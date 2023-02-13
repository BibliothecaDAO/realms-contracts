import { defaultProvider } from "starknet";
import { getSelectorFromName } from "starknet/dist/utils/stark";
import { getDeployment, getSigner, deployContract, getOwnerAccountInt } from "../helpers";

const main = async () => {

    const contractName = "01_TowerDefence";
  
    // Collect params
    const moduleControllerAddress = getDeployment("ModuleController");
    const elementsTokenAddress = getDeployment("ERC1155_ElementsToken");
    const arbiter = getDeployment("Arbiter");
    
    const blocksPerMin = "1";
    const hoursPerGame = "24";

    const owner = getOwnerAccountInt();
   
    await deployContract(contractName, contractName, [
      BigInt(moduleControllerAddress.address).toString(),
      BigInt(elementsTokenAddress.address).toString(),
      blocksPerMin,
      hoursPerGame,
      owner
    ]);

    const upgradedModule = getDeployment(contractName);

    // Appoint the upgrade as module with existing module ID
    const appoint = await getSigner().invokeFunction(
        arbiter.address,
        getSelectorFromName("appoint_contract_as_module"),
        [
            upgradedModule.address,
            "1"
        ]
    )

    await defaultProvider.waitForTx(appoint.transaction_hash)
    console.log("appoint_contract_as_module", await defaultProvider.getTransactionStatus(appoint.transaction_hash))
    
    // The tower defence needs permission to write to the storage contract
    const permit = await getSigner().invokeFunction(
        arbiter.address,
        getSelectorFromName("approve_module_to_module_write_access"),
        [
            "1",
            "2"
        ]
    )
    await defaultProvider.waitForTx(permit.transaction_hash)
    console.log("approve_module_to_module_write_access", await defaultProvider.getTransactionStatus(permit.transaction_hash))

}

main().catch(e => console.error(e.response.data))