import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { deployments, ethers } from 'hardhat';

const functionOne: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts } = hre;
    const { deploy, log } = deployments;

    const { deployer } = await getNamedAccounts();

    const deployLordsResult = await deploy('TheLordsToken', {
        from: deployer,
        log: true,
        args: ["500000000000000000000000000"]
    });

    if (deployLordsResult.newlyDeployed) {
        log(
            `LordsToken deployed at ${deployLordsResult.address} using ${deployLordsResult.receipt?.gasUsed} gas`
        );
    }

    const deployRealmsResult = await deploy('LootRealms', {
        from: deployer,
        log: true,
    });

    if (deployRealmsResult.newlyDeployed) {
        log(
            `LootRealms deployed at ${deployRealmsResult.address} using ${deployRealmsResult.receipt?.gasUsed} gas`
        );
    }

    const Journey = await deploy('Journey', {
        from: deployer,
        log: true,
        args: [10, 1, deployRealmsResult.address, deployLordsResult.address]
    });

    if (Journey.newlyDeployed) {
        log(
            `Journey deployed at ${Journey.address} using ${Journey.receipt?.gasUsed} gas`
        );
    }

    const Bridge = await deploy('Bridge', {
        from: deployer,
        log: true,
        args: [deployRealmsResult.address, Journey.address]
    });

    if (Journey.newlyDeployed) {
        log(
            `Bridge deployed at ${Bridge.address} using ${Bridge.receipt?.gasUsed} gas`
        );
    }
};
export default functionOne;
functionOne.tags = ['Tokens'];