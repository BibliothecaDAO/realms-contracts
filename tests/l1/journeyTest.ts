import hre from "hardhat";
import { ethers, deployments } from 'hardhat';
import { assert, expect } from "chai";
import { solidity } from "ethereum-waffle";
import { beforeEach } from "mocha";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Deployment } from "hardhat-deploy/dist/types";

// chai.use(solidity);

describe("JourneyTest", () => {

    let staker: SignerWithAddress;

    let lootRealms: Contract;
    let lootRealmsDeployment: Deployment;

    let theLordsToken: Contract;
    let theLordsTokenDeployment: Deployment;

    let journey: Contract;
    let journeyDeployment: Deployment;

    let bridge: Contract;
    let bridgeDeployment: Deployment;
    // vars
    let numOfRealms: any;
    let ids: Array<Number>;



    before(async function () {
        const { deployments, getNamedAccounts } = hre;

        await deployments.fixture(["Tokens", "DiamondCutFacet", "RealmsDiamond", "DiamondInit", "Faucets"]);

        // Token deployments
        bridgeDeployment = await deployments.get('Bridge');
        lootRealmsDeployment = await deployments.get('LootRealms');
        theLordsTokenDeployment = await deployments.get('TheLordsToken');

        journeyDeployment = await deployments.get('Journey');
        journey = await ethers.getContractAt('Journey', journeyDeployment.address)

        // token Contracts
        lootRealms = await ethers.getContractAt('LootRealms', lootRealmsDeployment.address)
        theLordsToken = await ethers.getContractAt('TheLordsToken', theLordsTokenDeployment.address)

        // bridge
        bridge = await ethers.getContractAt('Bridge', bridgeDeployment.address)


        // misc 

        numOfRealms = 100;
        ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

    });



    it('it will mint numRealms to player', async () => {
        [staker] = await ethers.getSigners();

        for (let i = 0; i < numOfRealms; i++) {
            await lootRealms.mint(i);
        }

        expect(await lootRealms.balanceOf(staker.address)).to.equal(numOfRealms);

    })

    it('it will stake realms', async () => {
        [staker] = await ethers.getSigners();

        await lootRealms.setApprovalForAll(journeyDeployment.address, true)
        await journey.boardShip(ids);

        expect(await lootRealms.balanceOf(staker.address)).to.equal(numOfRealms - ids.length);
    })

    it('it return num realms staked', async () => {
        [staker] = await ethers.getSigners();

        expect(await journey.getNumberRealms(staker.address)).to.equal(ids.length);
    })

    it('it will show LORDS available', async () => {
        await theLordsToken.mint(journeyDeployment.address, 10000000000);

        [staker] = await ethers.getSigners();

        expect(await theLordsToken.balanceOf(journeyDeployment.address)).to.equal(10000000000);
    })
    it('it will withdraw all Realms from contract', async () => {
        await journey.exitShip(ids)

        // await bridge.withdrawRealm(staker.address, ids)

        const balance = await lootRealms.balanceOf(staker.address)

        console.log("BALANCE OF REALMS AFTER WITHDRAW:", balance.toString())
        expect(await lootRealms.balanceOf(staker.address)).to.equal(numOfRealms);

    })
    // it('it will mint LORDS', async () => {
    //     [staker] = await ethers.getSigners();

    //     await journey.claimLords();

    //     let balance = await theLordsToken.balanceOf(staker.address)

    //     // await journey.claimLords();
    //     console.log("LORDS BALANCE:", balance.toString())

    // })



    it('it will show no LORDS Available', async () => {

        await theLordsToken.mint(journeyDeployment.address, 10000000000);

        [staker] = await ethers.getSigners();

        let balance = await journey.lordsAvailable(staker.address);

        console.log("LORDS AVAILABLE:", balance.toString())
        expect(await journey.lordsAvailable(staker.address)).to.equal(0);

    })
});