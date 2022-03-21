
import { shortString } from "starknet";
import { 
    provider,
    getDeployedAddressInt, 
    getSigner,
    deployContract,
 } from "../helpers";

const deploy = async () => {
    const contractName = 'DivineEclipseElements'

    const arbiterAddress = getDeployedAddressInt("Arbiter");
    const moduleControllerAddress = getDeployedAddressInt("ModuleController");

    await deployContract(
        contractName, 
        'DivineEclipseStorage', 
        [
            moduleControllerAddress,
        ]
    )

    const divineEclipse = getDeployedAddressInt('DivineEclipseStorage');
    
    const moduleId = shortString.encodeShortString("divine-eclipse");
    console.log("moduleId is ", moduleId)
    const res = await getSigner().execute(
        {
            contractAddress: arbiterAddress,
            entrypoint: "appoint_contract_as_module",
            calldata: [divineEclipse, moduleId]
        }
    )

    console.log("appoint_contract_as_module", res)

    await provider.waitForTransaction(res.transaction_hash);
    console.log(await provider.getTransactionStatus(
      res.transaction_hash
    ))

    const res2 = await getSigner().execute(
        {
            contractAddress: arbiterAddress,
            entrypoint: "approve_module_to_module_write_access",
            calldata: ['4', moduleId]
        }
    )

    console.log("approve_module_to_module_write_access", res2)

    await provider.waitForTransaction(res2.transaction_hash);
    console.log(await provider.getTransactionStatus(
      res2.transaction_hash
    ))
}

deploy().catch((e) => console.error(e));
