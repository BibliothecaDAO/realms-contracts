
import "@nomiclabs/hardhat-ethers";
import { Provider, defaultProvider, stark } from 'starknet'
import {ethers as hardhatEthers, network} from "hardhat"
import * as ethers from "ethers"
import dotenv from "dotenv"
dotenv.config()

async function main() {

  const lockboxFactory = await hardhatEthers.getContractFactory("RealmsL1Bridge");

  const lockbox = await lockboxFactory.attach(process.env[`L1_REALMS_BRIDGE_LOCKBOX_${network.name.toUpperCase()}`])

  const res = await lockbox.withdrawFromL2("0xa035bf657bd2fbde2ec374bec968b85715512f29", ["27"])

  console.log(res)
}

main();