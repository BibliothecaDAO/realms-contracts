
import "@nomiclabs/hardhat-ethers";
import { Provider, defaultProvider, stark } from 'starknet'
import {ethers as hardhatEthers, network} from "hardhat"
import * as ethers from "ethers"
import dotenv from "dotenv"
import { getSigner } from "../helpers";
dotenv.config()

async function main() {
  const tokenId = 5

  const lootRealmsFactory = await hardhatEthers.getContractFactory("LootRealms");

  const lootRealms = await lootRealmsFactory.attach(process.env[`L1_REALMS_ADDRESS_${network.name.toUpperCase()}`])

  const tx1 = await lootRealms.mint(tokenId)

  console.log(await tx1.wait())

  // console.log(await lootRealms.ownerOf(tokenId.toString()))

  const tx2 = await lootRealms.setApprovalForAll(process.env[`L1_REALMS_BRIDGE_LOCKBOX_ADDRESS_${network.name.toUpperCase()}`], true)

  console.log(tx2)

  const lockboxFactory = await hardhatEthers.getContractFactory("RealmsBridgeLockbox");

  const lockbox = await lockboxFactory.attach(process.env[`L1_REALMS_BRIDGE_LOCKBOX_ADDRESS_${network.name.toUpperCase()}`])

  const tx = await lockbox.depositToL2(ethers.BigNumber.from(process.env.STARKNET_ACCOUNT_ADDRESS), [ethers.BigNumber.from(tokenId.toString())])

  const a = await tx.wait()

  console.log(a)

  const signer = getSigner()

  const res = await signer.callContract({
    contractAddress: process.env[`L2_REALMS_ADDRESS_${network.name.toUpperCase()}`],
    entrypoint: "ownerOf",
    calldata: ["5000", "0"]
  });

  console.log(res)
}

main();