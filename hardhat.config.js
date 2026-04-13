require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.26",//changed from 0.8.0
    //added this to compile the NFT
    settings: {
      evmVersion: "cancun"
    }
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://sepolia.infura.io/v3/" + String(process.env.API_KEY)
      }
    },
    sepolia: {
      url: String(process.env.SEPOLIA_RPC_URL),
      accounts: [`0x${process.env.PRIVATE_KEY}`, `0x${process.env.PRIVATE_KEY_2}`]
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};