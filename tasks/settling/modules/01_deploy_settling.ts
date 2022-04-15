
import { deployContract, getOwnerAccountInt, setupDeploymentDir, getDeployedAddressInt, getSigner, getAccountContract } from '../../helpers'

async function main() {
    const proxyLogicContractName = 'PROXY_L01_Settling'
    const logicContractName = 'L01_Settling'
    const stateContractName = 'S01_Settling'

    setupDeploymentDir()
    const ownerAccount = getOwnerAccountInt()

    // Collect params
    const moduleControllerAddress = getDeployedAddressInt("ModuleController");

    // Magically deploy + write all files and stuff 
    // Implementation
    // await deployContract(logicContractName, logicContractName, [])

    // const settlingLogicAddress = getDeployedAddressInt("L01_Settling");
    // // Proxy
    // await deployContract(proxyLogicContractName, proxyLogicContractName, [settlingLogicAddress])

    // const proxySettlingLogicAddress = getDeployedAddressInt("L01_Settling");

    // // set implementation
    // const res = await getSigner().execute(
    //     {
    //         contractAddress: proxySettlingLogicAddress,
    //         entrypoint: "initializer",
    //         calldata: [ownerAccount, moduleControllerAddress]
    //     }
    // )
    // console.log(await getAccountContract())

    await deployContract(stateContractName, stateContractName, [moduleControllerAddress])
}

export default main()