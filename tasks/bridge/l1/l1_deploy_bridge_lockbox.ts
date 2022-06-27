
import "@nomiclabs/hardhat-ethers";
import {ethers as hardhatEthers, upgrades, network} from "hardhat"
import * as ethers from "ethers"
import fs from 'fs/promises'
import dotenv from "dotenv"
dotenv.config()

async function main() {
    const lockboxFactory = await hardhatEthers.getContractFactory("RealmsL1Bridge");
    const box = await upgrades.deployProxy(lockboxFactory, [
        process.env[`L1_STARKNET_CORE_ADDRESS_${network.name.toUpperCase()}`]
    ]);
    await box.deployed();
    console.log(`RealmsL1Bridge ${network.name} deployed to:`, box.address);
}

main();