import "@nomiclabs/hardhat-ethers";
import { ethers as hardhatEthers, upgrades, network } from "hardhat";
import * as ethers from "ethers";
// import fs from "fs/promises";
import dotenv from "dotenv";
dotenv.config();

async function main() {
  const bridgeFactory = await hardhatEthers.getContractFactory(
    "RealmsL1Bridge"
  );

  const instance = bridgeFactory.attach(
    process.env[`L1_REALMS_BRIDGE_${network.name.toUpperCase()}`]
  );

  // Configure internal variables
  console.log("Setting StarkNet Core");
  const res1 = await instance.setStarknetCore(
    (process.env as any)[
      `L1_STARKNET_CORE_ADDRESS_${network.name.toUpperCase()}`
    ]
  );
  await res1.wait();

  console.log("Setting L1 Journey V1");
  const res2 = await instance.setJourneyV1Address(
    (process.env as any)[`L1_JOURNEY_V1_${network.name.toUpperCase()}`]
  );
  await res2.wait();

  console.log("Setting L1 Journey V2");
  const res3 = await instance.setJourneyV2Address(
    (process.env as any)[`L1_JOURNEY_V2_${network.name.toUpperCase()}`]
  );
  await res3.wait();

  console.log("Setting L2 Bridge");
  const res4 = await instance.setL2BridgeAddress(
    (process.env as any)[`L2_REALMS_BRIDGE_${network.name.toUpperCase()}`]
  );
  await res4.wait();
}

main();
