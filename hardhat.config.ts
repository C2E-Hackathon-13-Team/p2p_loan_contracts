import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config({ path: `./.env.${process.env.NODE_ENV}` });

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.27",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200, // adjust based on your needs
        details: {
          yulDetails: {
            optimizerSteps: "u", // recommended for better performance
          },
        },
      },
    },
  },
  networks:{
    local: {
      url: 'http://localhost:8545',
      chainId:31337,
      accounts: [process.env.OWNER_PRIVATE_KEY,process.env.LAUNCHER_PRIVATE_KEY,process.env.INVESTOR1_PRIVATE_KEY,process.env.INVESTOR2_PRIVATE_KEY]
    },
    sepolia: {
      url: 'https://rpc.sepolia.org',
      chainId: 11155111,
      accounts: [process.env.OWNER_PRIVATE_KEY]
    },
  }
};

export default config;
