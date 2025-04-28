import {HardhatUserConfig} from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'dotenv/config'
import "@openzeppelin/hardhat-upgrades";

const PRIVATE_KEY = process.env.PRIVATE_KEY!;

const config: HardhatUserConfig = {
  defaultNetwork: "ethTest",
  networks: {
    hardhat: {},
    ethTest: {
      url: "https://ethereum-sepolia-rpc.publicnode.com",
      accounts: [PRIVATE_KEY]
    },
    bscTest: {
      url: "https://bsc-rpc.publicnode.com",
      accounts: [PRIVATE_KEY]
    },
    local: {
      url: "http://127.0.0.1:8545",
      accounts: [PRIVATE_KEY]
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ]
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  }
};

export default config;
