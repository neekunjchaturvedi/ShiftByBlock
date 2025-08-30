// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ShiftLog {
    struct Shift {
        uint256 id;
        address worker;
        uint256 startTime;
        uint256 endTime;
        string noteHash;
    }

    mapping(address => Shift[]) public workerShifts;

    event ShiftStarted(address indexed worker, uint256 shiftId, uint256 startTime);
    event ShiftEnded(address indexed worker, uint256 shiftId, uint256 endTime, string noteHash);

    function startShift() public {
        Shift[] storage shifts = workerShifts[msg.sender];
        if (shifts.length > 0) {
            require(shifts[shifts.length - 1].endTime != 0, "Previous shift not ended yet.");
        }
        uint256 newShiftId = shifts.length;
        shifts.push(Shift(newShiftId, msg.sender, block.timestamp, 0, ""));
        emit ShiftStarted(msg.sender, newShiftId, block.timestamp);
    }

    function endShift(string memory _noteHash) public {
        Shift[] storage shifts = workerShifts[msg.sender];
        require(shifts.length > 0, "No shifts recorded for this worker.");
        Shift storage currentShift = shifts[shifts.length - 1];
        require(currentShift.endTime == 0, "Shift has already been ended.");
        currentShift.endTime = block.timestamp;
        currentShift.noteHash = _noteHash;
        emit ShiftEnded(msg.sender, currentShift.id, block.timestamp, _noteHash);
    }

    function getShiftsByWorker(address _worker) public view returns (Shift[] memory) {
        return workerShifts[_worker];
    }
}