import { defaultProvider } from "starknet";
import { getSelectorFromName } from "starknet/dist/utils/stark";
import { 
    getDeployedAddressInt, 
    getSigner, 
    setupDeploymentDir, 
    checkDeployment, 
    deployContract
 } from "./helpers";

const deploy = async () => {
    const contractName = '04_Elements'

    setupDeploymentDir()
    checkDeployment(contractName)

    const arbiterAddress = getDeployedAddressInt("Arbiter");
    const moduleControllerAddress = getDeployedAddressInt("ModuleController");
    const elementsTokenAddress = getDeployedAddressInt("ERC1155_ElementsToken");  

    // The minting middleware was deployed separately
    // It's not the same account as the OwnerAccount for security reasons
    const mintingMiddlewareAddr = BigInt("0x430728b8d6252608f35615191903466284b01e4ae9ecff60de8a6cb99d44a10").toString()
  
    await deployContract(
        contractName, 
        "04_Elements", 
        [
            moduleControllerAddress,
            elementsTokenAddress,
            mintingMiddlewareAddr
        ]
    )

    const elementBalancer = getDeployedAddressInt("04_Elements");
    
    // The elements module should be the owner of the 1155 contract
    const res = await getSigner().invokeFunction(
        elementsTokenAddress,
        getSelectorFromName("set_owner"),
        [
            elementBalancer
        ]
    )

    console.log("set_owner", res)

    await defaultProvider.waitForTx(res.transaction_hash);
    const status = await defaultProvider.getTransactionStatus(
      res.transaction_hash
    );
    console.log(status);

    const appointRes = await getSigner().invokeFunction(
        arbiterAddress,
        getSelectorFromName("appoint_contract_as_module"),
        [
            elementBalancer,
            "4"
        ]
    )
    console.log("appoint_contract_as_module", appointRes);
    await defaultProvider.waitForTx(appointRes.transaction_hash)
    console.log(await defaultProvider.getTransactionStatus(appointRes.transaction_hash));
}

deploy().catch((e) => console.error(e));
