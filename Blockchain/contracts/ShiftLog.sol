// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ShiftLog {
    // ## State Variables ##
    address public supervisor; // The address of the supervisor who pays workers.
    address public escrowAgent; // A neutral address to hold the bond.

    // ## Structs ##
    struct Shift {
        uint256 id;
        address worker;
        uint256 startTime;
        uint256 endTime;
        string noteHash;
        uint256 paymentAmount; // Amount paid for this shift.
    }

    struct Escrow {
        uint256 bondAmount; // The safety bond deposited by the supervisor.
        bool isActive;      // True if a bond is currently held.
    }

    // ## Mappings ##
    mapping(address => Shift[]) public workerShifts;
    mapping(uint256 => Escrow) public activeEscrows; // Mapping from shift ID to its escrow details.

    // ## Events ##
    event ShiftStarted(address indexed worker, uint256 shiftId, uint256 startTime);
    event ShiftEnded(address indexed worker, uint256 shiftId, uint256 paymentAmount);
    event BondDeposited(uint256 shiftId, uint256 amount);
    event BondReturned(uint256 shiftId, uint256 amount);
    event BondForfeited(uint256 shiftId, address indexed worker, uint256 amount);

    // ## Constructor ##
    // Sets the supervisor and escrow agent when the contract is deployed.
    constructor() {
        supervisor = msg.sender;
        escrowAgent = address(this); // The contract itself will act as the escrow agent.
    }

    // ## Functions ##
    /**
     * @dev Starts a new shift. Called by the supervisor.
     * The supervisor must send AVAX equal to the shift payment + safety bond.
     * @param _worker The address of the worker starting the shift.
     * @param _bondAmount The amount to be held as a safety bond.
     */
    function startShift(address _worker, uint256 _bondAmount) public payable {
        require(msg.sender == supervisor, "Only supervisor can start shifts");
        
        Shift[] storage shifts = workerShifts[_worker];
        if (shifts.length > 0) {
            require(shifts[shifts.length - 1].endTime != 0, "Worker's previous shift not ended.");
        }

        uint256 paymentAmount = msg.value - _bondAmount;
        require(paymentAmount > 0, "Payment must be greater than bond");

        uint256 newShiftId = shifts.length;
        
        // Hold the bond in escrow
        activeEscrows[newShiftId] = Escrow(_bondAmount, true);
        emit BondDeposited(newShiftId, _bondAmount);

        shifts.push(Shift(newShiftId, _worker, block.timestamp, 0, "", paymentAmount));
        emit ShiftStarted(_worker, newShiftId, block.timestamp);
    }

    /**
     * @dev Ends the most recent active shift. Called by the worker.
     * @param _noteHash The IPFS hash of the handover notes.
     */
    function endShift(string memory _noteHash) public {
        Shift[] storage shifts = workerShifts[msg.sender];
        require(shifts.length > 0, "No shifts recorded for this worker.");
        
        Shift storage currentShift = shifts[shifts.length - 1];
        require(currentShift.worker == msg.sender, "Not your shift to end");
        require(currentShift.endTime == 0, "Shift has already been ended.");
        
        Escrow storage currentEscrow = activeEscrows[currentShift.id];
        require(currentEscrow.isActive, "No active bond for this shift.");

        // Mark the shift as ended
        currentShift.endTime = block.timestamp;
        currentShift.noteHash = _noteHash;

        // 1. Return the bond to the supervisor
        payable(supervisor).transfer(currentEscrow.bondAmount);
        emit BondReturned(currentShift.id, currentEscrow.bondAmount);

        // 2. Pay the worker
        payable(msg.sender).transfer(currentShift.paymentAmount);
        emit ShiftEnded(msg.sender, currentShift.id, currentShift.paymentAmount);

        // Deactivate the escrow
        currentEscrow.isActive = false;
    }

    /**
     * @dev Called by the supervisor if an incident occurs and the shift isn't ended.
     * This forfeits the bond to the worker.
     * @param _worker The address of the worker whose bond is to be forfeited.
     */
    function forfeitBondToWorker(address _worker) public {
        require(msg.sender == supervisor, "Only supervisor can call this.");
        
        Shift[] storage shifts = workerShifts[_worker];
        require(shifts.length > 0, "Worker has no shifts.");
        
        Shift storage lastShift = shifts[shifts.length - 1];
        require(lastShift.endTime == 0, "Shift is not active.");
        
        Escrow storage currentEscrow = activeEscrows[lastShift.id];
        require(currentEscrow.isActive, "No active bond for this shift.");

        // Mark shift as "ended by incident"
        lastShift.endTime = block.timestamp;
        lastShift.noteHash = "INCIDENT_REPORTED_BY_SUPERVISOR";

        // Forfeit the bond to the worker
        payable(_worker).transfer(currentEscrow.bondAmount);
        emit BondForfeited(lastShift.id, _worker, currentEscrow.bondAmount);
        
        // Return the payment portion to the supervisor
        payable(supervisor).transfer(lastShift.paymentAmount);

        // Deactivate the escrow
        currentEscrow.isActive = false;
    }

    function getShiftsByWorker(address _worker) public view returns (Shift[] memory) {
        return workerShifts[_worker];
    }
}