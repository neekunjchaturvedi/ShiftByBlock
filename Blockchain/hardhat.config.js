import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";
dotenv.config();

/** @type import('hardhat/config').HardhatUserConfig */
const config = {
  solidity: "0.8.9",
  networks: {
    fuji: {
      url: process.env.FUJI_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};

export default config;
