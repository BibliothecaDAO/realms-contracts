import { defaultProvider } from "starknet";
import { getSelectorFromName } from "starknet/dist/utils/stark";
import { getDeployedAddressInt, getSigner, deployContract } from "../helpers";

const main = async () => {

    const contractName = "02_TowerDefenceStorage";
  
    // Collect params
    const moduleControllerAddress = getDeployedAddressInt("ModuleController");
    const arbiter = getDeployedAddressInt("Arbiter");
   
    await deployContract(contractName, contractName, [
      moduleControllerAddress,
    ]);

    const upgradedModule = getDeployedAddressInt(contractName);

    // Appoint the upgrade as module with existing module ID
    const appoint = await getSigner().invokeFunction(
        arbiter,
        getSelectorFromName("appoint_contract_as_module"),
        [
            upgradedModule,
            "2"
        ]
    )

    await defaultProvider.waitForTx(appoint.transaction_hash)
    console.log("appoint_contract_as_module", await defaultProvider.getTransactionStatus(appoint.transaction_hash))

}

main().catch(e => console.error(e))