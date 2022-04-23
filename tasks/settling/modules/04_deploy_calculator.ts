
import { deployContract, getOwnerAccountInt, setupDeploymentDir, getDeployedAddressInt } from '../../helpers'

async function main() {
    const logicContractName = 'L04_Calculator'

    setupDeploymentDir()

    // Collect params
    const arbiterAddress = getDeployedAddressInt("Arbiter");
    const moduleControllerAddress = getDeployedAddressInt("ModuleController");

    // Magically deploy + write all files and stuff 
    await deployContract(logicContractName, logicContractName, [moduleControllerAddress])
}

export default main()