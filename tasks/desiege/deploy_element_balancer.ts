
import { 
    provider,
    getDeployedAddressInt, 
    getSigner,
    deployContract,
    getOwnerAccountInt
 } from "../helpers";

const deploy = async () => {
    const contractName = '04_Elements'

    const arbiterAddress = getDeployedAddressInt("Arbiter");
    const moduleControllerAddress = getDeployedAddressInt("ModuleController");
    const elementsTokenAddress = getDeployedAddressInt("ERC1155_ElementsToken");  
    const owner = getOwnerAccountInt();
  
    await deployContract(
        contractName, 
        "04_Elements", 
        [
            moduleControllerAddress,
            elementsTokenAddress,
            owner
        ]
    )

    const elementBalancer = getDeployedAddressInt("04_Elements");
    
    // The elements module should be the owner of the 1155 contract
    const res = await getSigner().execute(
        {
            contractAddress: elementsTokenAddress,
            entrypoint: "transferOwnership",
            calldata: [elementBalancer]
        }
    )

    console.log("transferOwnership", res)

    await provider.waitForTransaction(res.transaction_hash);
    const status = await provider.getTransactionStatus(
      res.transaction_hash
    );
    console.log(status);

    const appointRes = await getSigner().execute({
        contractAddress: arbiterAddress,
        entrypoint: "appoint_contract_as_module",
        calldata: [
            elementBalancer,
            "4"
        ]
    })
    console.log("appoint_contract_as_module", appointRes);
    await provider.waitForTransaction(appointRes.transaction_hash);
    console.log(await provider.getTransactionStatus(appointRes.transaction_hash));
}

deploy().catch((e) => console.error(e));
