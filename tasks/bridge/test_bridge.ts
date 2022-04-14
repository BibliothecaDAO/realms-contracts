
import "@nomiclabs/hardhat-ethers";
import { Provider, defaultProvider, stark } from 'starknet'
import {ethers as hardhatEthers, network} from "hardhat"
import * as ethers from "ethers"
import dotenv from "dotenv"
import { getSigner } from "../helpers";
dotenv.config()

async function main() {
  const tokenIds = ["27"]

  const lootRealmsFactory = await hardhatEthers.getContractFactory("LootRealms");
  const lockboxFactory = await hardhatEthers.getContractFactory("RealmsBridgeLockbox");
  const lootRealms = await lootRealmsFactory.attach(process.env[`L1_REALMS_ADDRESS_${network.name.toUpperCase()}`])
  const lockbox = await lockboxFactory.attach(process.env[`L1_REALMS_BRIDGE_LOCKBOX_ADDRESS_${network.name.toUpperCase()}`])

  // Mint
  // for (let i = 0; i < tokenIds.length; i++) {
  //   const tx1 = await lootRealms.mint(tokenIds[i])
  //   await tx1.wait()
  //   console.log(`Minted: ${tokenIds[i]}, ${tx1.hash}`)
  // }
  // // console.log(await lootRealms.ownerOf(tokenId.toString()))

  // // Approving
  // const tx2 = await lootRealms.setApprovalForAll(process.env[`L1_REALMS_BRIDGE_LOCKBOX_ADDRESS_${network.name.toUpperCase()}`], true)
  // console.log(`Approved: ${tx2.hash}`)

  // Depositing
  const tx = await lockbox.depositToL2(ethers.BigNumber.from(process.env.STARKNET_ACCOUNT_ADDRESS), tokenIds)
  const a = await tx.wait()
  console.log(`Deposited:`, a)

  // Verifying
  // const signer = getSigner()
  // const res = await signer.callContract({
  //   contractAddress: process.env[`L2_REALMS_ADDRESS_${network.name.toUpperCase()}`],
  //   entrypoint: "ownerOf",
  //   calldata: [tokenId.toString(), "0"]
  // });
  // console.log(res)
}

main();