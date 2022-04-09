
import "@nomiclabs/hardhat-ethers";
import { Provider, defaultProvider, stark } from 'starknet'
import {ethers as hardhatEthers, network} from "hardhat"
import * as ethers from "ethers"
import dotenv from "dotenv"
dotenv.config()

async function main() {

  const lockboxFactory = await hardhatEthers.getContractFactory("RealmsBridgeLockbox");

  const lockbox = await lockboxFactory.attach(process.env[`L1_REALMS_BRIDGE_LOCKBOX_ADDRESS_${network.name.toUpperCase()}`])

  const res = await lockbox.setL2BridgeAddress(process.env[`L2_BRIDGE_ADDRESS_${network.name.toUpperCase()}`])

  console.log(res)
}

main();