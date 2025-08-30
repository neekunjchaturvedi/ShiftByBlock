// Import the hardhat environment object (hre) using ES Module syntax
import hre from "hardhat";

async function main() {
  console.log("Deploying ShiftLog contract...");

  // Get the contract factory and deploy it.
  // This uses the contract NAME, "ShiftLog", not the filename.
  const shiftLog = await hre.ethers.deployContract("ShiftLog");

  // Wait for the contract deployment to be finalized on the blockchain
  await shiftLog.waitForDeployment();

  // Log the contract's address to the console
  console.log(`✅ ShiftLog contract deployed to: ${shiftLog.target}`);
}

// Standard pattern to execute the async main function and handle any errors
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
