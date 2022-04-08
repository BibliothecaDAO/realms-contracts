
import { deployContract, getOwnerAccountInt, setupDeploymentDir, getDeployedAddressInt } from '../../helpers'

async function main() {
    const logicContractName = 'L01_Settling'
    const stateContractName = 'S01_Settling'

    setupDeploymentDir()

    // Collect params
    const arbiterAddress = getDeployedAddressInt("Arbiter");
    const moduleControllerAddress = getDeployedAddressInt("ModuleController");

    // Magically deploy + write all files and stuff 
    await deployContract(logicContractName, logicContractName, [moduleControllerAddress])
    await deployContract(stateContractName, stateContractName, [moduleControllerAddress])
}

main()