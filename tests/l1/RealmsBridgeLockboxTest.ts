import hre from "hardhat";
import { ethers } from 'hardhat';
import { assert, expect } from "chai";
import { solidity } from "ethereum-waffle";
import { beforeEach } from "mocha";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { smock } from "@defi-wonderland/smock";

import { Deployment } from "hardhat-deploy/dist/types";

// chai.use(solidity);

describe("RealmsBridgeLockboxTest", () => {
  let staker: SignerWithAddress;

  let lootRealms: Contract;
  let lockbox: Contract;

  let starknetCoreMock: any;

  // vars
  let numOfRealms: any;
  let ids: Array<Number>;



  before(async function () {
      const { deployments, getNamedAccounts } = hre;

      const realmsFactory = await ethers.getContractFactory("LootRealms")
      const lockboxFactory = await ethers.getContractFactory("RealmsBridgeLockbox")
      
      const starknetCoreMockFactory = await smock.mock("StarknetCoreMock");
      starknetCoreMock = await starknetCoreMockFactory.deploy()
      lootRealms = await realmsFactory.deploy()
      lockbox = await lockboxFactory.deploy()
      await lockbox.initialize(lootRealms.address, "0xa", starknetCoreMock.address)

      numOfRealms = 10;
      ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
  });



  it('it will mint numRealms to player', async () => {
    const tokenId = 1

    const [staker] = await ethers.getSigners();

    await lootRealms.mint(tokenId);

    await lootRealms.setApprovalForAll(lockbox.address, true)

    await lockbox.depositToL2("0x1111", [tokenId])

    expect(starknetCoreMock.sendMessageToL2.atCall(0).getCallCount()).to.be.equal(1);
  })
});