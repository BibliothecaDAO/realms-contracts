
import "@nomiclabs/hardhat-ethers";
import {ethers as hardhatEthers, upgrades} from "hardhat"
import * as ethers from "ethers"
import fs from 'fs/promises'
import dotenv from "dotenv"
dotenv.config()

async function main() {
    const lootRealmsDeploymentFile = await fs.readFile('./deployments/goerli/LootRealms.json')
    const lootRealmsDeploymentContent = JSON.parse(lootRealmsDeploymentFile.toString())

    const lockboxFactory = await hardhatEthers.getContractFactory("RealmsBridgeLockbox");
    const lockbox = await upgrades.upgradeProxy((process.env as any).L1_REALMS_BRIDGE_LOCKBOX, lockboxFactory);
    console.log(lockbox)
    console.log("RealmsBridgeLockbox upgraded");
}

main();