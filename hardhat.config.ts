import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from 'dotenv';
dotenv.config();

const PRIVATE_KEY_1 = process.env.PRIVATE_KEY_1?.toString()||'';
const PRIVATE_KEY_2 = process.env.PRIVATE_KEY_2?.toString()||'';
const PRIVATE_KEY_3 = process.env.PRIVATE_KEY_3?.toString()||'';

const config: HardhatUserConfig = {
  defaultNetwork: 'bscmainnet',
  networks: {
    bscmainnet: {
      url: "https://bsc-dataseed1.ninicoin.io/",
      accounts: [PRIVATE_KEY_1 , PRIVATE_KEY_2,PRIVATE_KEY_3],
      gasPrice:1000000000,
    },
    bsctestnet: {
      url: "https://bsc-testnet-dataseed.bnbchain.org",
      accounts: [PRIVATE_KEY_1 , PRIVATE_KEY_2,PRIVATE_KEY_3]
    },
    goerli: {
      url: "https://api.zan.top/node/v1/eth/goerli/public",
      accounts: [PRIVATE_KEY_1 , PRIVATE_KEY_2,PRIVATE_KEY_3]
    },
  },
  etherscan: {
    apiKey: "9ASBCS3BUMCVZG5BSVERV3S5W73C8J7ERE"
  },
  solidity: {
    compilers: [
      {
        version: "0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
          viaIR: true
        }
      },
    ]
  },

};

export default config;
