import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  sourcify: {
    enabled: true,
    apiUrl: "https://sourcify.ambrosus.io/"
  },
  solidity: {
    version: "0.8.24",
    settings: {
      evmVersion: "istanbul",
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "airdao",
  networks: {
    airdao: {
      url: `${process.env.API_URL}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    sepolia: {
      url: 'https://ethereum-sepolia-rpc.publicnode.com',
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
  }
};

export default config;
