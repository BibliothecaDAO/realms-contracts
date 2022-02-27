import { defaultProvider } from "starknet";
import { getSelectorFromName } from "starknet/dist/utils/stark";
import { getDeployedAddressInt, getSigner, deployContract, getOwnerAccountInt } from "../helpers";

const main = async () => {

    const contractName = "01_TowerDefence";
  
    // Collect params
    const moduleControllerAddress = getDeployedAddressInt("ModuleController");
    const elementsTokenAddress = getDeployedAddressInt("ERC1155_ElementsToken");
    const arbiter = getDeployedAddressInt("Arbiter");
    
    const blocksPerMin = "1";
    const hoursPerGame = "24";

    const owner = getOwnerAccountInt();
   
    await deployContract(contractName, contractName, [
      moduleControllerAddress,
      elementsTokenAddress,
      blocksPerMin,
      hoursPerGame,
      owner
    ]);

    const upgradedModule = getDeployedAddressInt(contractName);

    // Appoint the upgrade as module with existing module ID
    const appoint = await getSigner().invokeFunction(
        arbiter,
        getSelectorFromName("appoint_contract_as_module"),
        [
            upgradedModule,
            "1"
        ]
    )

    await defaultProvider.waitForTx(appoint.transaction_hash)
    console.log("appoint_contract_as_module", await defaultProvider.getTransactionStatus(appoint.transaction_hash))
    
    // The tower defence needs permission to write to the storage contract
    const permit = await getSigner().invokeFunction(
        arbiter,
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