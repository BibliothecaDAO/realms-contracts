import { HardhatUserConfig } from 'hardhat/types';
import { task } from "hardhat/config";
import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";
import 'hardhat-deploy';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-truffle5';
import '@nomiclabs/hardhat-waffle';
import "hardhat-gas-reporter"
import '@typechain/hardhat';
import "tsconfig-paths/register";
import "@nomiclabs/hardhat-etherscan";
dotenvConfig({ path: resolve(__dirname, "./.env") });
const baseAccount: string | undefined = process.env.BASE_ACCOUNT;
const treasuryAccount: string | undefined = process.env.TREASURY_ACCOUNT;
const diamondAdmin: string | undefined = process.env.DIAMOND_ADMIN;

const arbPrivateKey = process.env.ARB_PRIVATEKEY;
const arbTreasuryPrivateKey = process.env.ARB_TREASURY_PRIVATEKEY;

const coinMarketCap = process.env.COIN_MCP;

if (!baseAccount) {
  throw new Error("Please set your baseAccount in a .env file");
}
if (!treasuryAccount) {
  throw new Error("Please set your treasuryAccount in a .env file");
}
if (!diamondAdmin) {
  throw new Error("Please set your diamondAdmin in a .env file");
}
if (!arbPrivateKey) {
  throw new Error("Please set your arbPrivateKey in a .env file");
}
if (!arbTreasuryPrivateKey) {
  throw new Error("Please set your arbTreasuryPrivateKey in a .env file");
}
if (!coinMarketCap) {
  throw new Error("Please set your coinMarketCap in a .env file");
}

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  solidity: "0.8.10",
  gasReporter: {
    currency: 'USD',
    gasPrice: 120,
    coinmarketcap: coinMarketCap,
    enabled: true
  },
  paths: {
    artifacts: './ethers/artifacts',
  },
  typechain: {
    outDir: "src/types",
    target: "ethers-v5",
  },
  networks: {
    hardhat: {
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      chainId: 1337
    },
    ropsten: {
      url: 'https://eth-ropsten.alchemyapi.io/v2/z2dZ-pKk2obtCwF9VFgM-Bx7Z7mKkrzH',
      accounts: [baseAccount]
    },
    rinkeby: {
      url: 'https://eth-rinkeby.alchemyapi.io/v2/XfkcyfGjPNcDrKrcA4Ccx63QnQjIYvBb',
      accounts: [arbPrivateKey]
    },
    arbitrumRinkeby: {
      url: 'https://rinkeby.arbitrum.io/rpc',
      accounts: [arbPrivateKey, arbTreasuryPrivateKey]
    },
  },
  etherscan: {
    apiKey: 'JPFRXZ5J2GV4P7CB4NCP8BYBCJUTUHIZEB'
  },
  namedAccounts: {
    deployer: {
      default: 0,
      hardhat: 0,
      rinkeby: baseAccount,
      ropsten: baseAccount,
      arbitrumRinkeby: baseAccount,
      4: baseAccount
    },
    treasury: {
      default: 1,
      hardhat: 1,
      rinkeby: treasuryAccount,
      ropsten: treasuryAccount,
      arbitrumRinkeby: treasuryAccount,
      4: treasuryAccount
    },
    diamondAdmin: {
      default: 2,
      hardhat: 2,
      ropsten: diamondAdmin,
      arbitrumRinkeby: diamondAdmin,
      4: diamondAdmin
    }
  },
};

export default config;