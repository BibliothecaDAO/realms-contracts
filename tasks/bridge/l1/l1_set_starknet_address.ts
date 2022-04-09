
import "@nomiclabs/hardhat-ethers";
import { Provider, defaultProvider, stark } from 'starknet'
import {ethers as hardhatEthers} from "hardhat"
import * as ethers from "ethers"
import dotenv from "dotenv"
dotenv.config()

async function main() {

  const lockboxFactory = await hardhatEthers.getContractFactory("RealmsBridgeLockbox");

  const lockbox = await lockboxFactory.attach((process.env as any).L1_REALMS_BRIDGE_LOCKBOX)

  const res = await lockbox.setL2BridgeAddress((process.env as any).L2_BRIDGE_ADDRESS)

  console.log(res)
}

main();