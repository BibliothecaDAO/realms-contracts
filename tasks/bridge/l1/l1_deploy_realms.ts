
import "@nomiclabs/hardhat-ethers";
import {ethers as hardhatEthers, upgrades, network} from "hardhat"
import * as ethers from "ethers"
import fs from 'fs/promises'
import dotenv from "dotenv"
dotenv.config()

async function main() {
    const lockboxFactory = await hardhatEthers.getContractFactory("LootRealms");
    const lockbox = await lockboxFactory.deploy()

    console.log("LootRealms deployed to:", lockbox.address);
}

main();