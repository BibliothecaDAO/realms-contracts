
import "@nomiclabs/hardhat-ethers";
import {ethers as hardhatEthers, upgrades, network} from "hardhat"
import * as ethers from "ethers"
import fs from 'fs/promises'
import dotenv from "dotenv"
dotenv.config()

async function main() {
    const lockboxFactory = await hardhatEthers.getContractFactory("Journey");
    const lockbox = await lockboxFactory.deploy(
        0,
        10,
        process.env[`L1_REALMS_ADDRESS_${network.name.toUpperCase()}`],
        process.env[`L1_LORDS_ADDRESS_${network.name.toUpperCase()}`],
    )

    console.log("LootRealms deployed to:", lockbox.address);
}

main();