
import { getDeployedAddressInt, getDeployment, provider, getSigner } from "../helpers";

// Re-runs will use the same files
const deploy = async () => {
  const signer = getSigner();

  const towerDefence = getDeployment("01_TowerDefence");
  const towerDefenceStorage = getDeployment("02_TowerDefenceStorage");

  // The arbiter is the only contract that can modify the controller
  const arbiter = getDeployment("DesiegeArbiter").address;

  const controller = getDeployment("DesiegeModuleController")

  const res = await signer.execute({
    contractAddress: arbiter,
    entrypoint: "set_address_of_controller",
    calldata: [controller.address]
  }, undefined, {
    maxFee: '0'
  });

  console.log("setting controller to", controller.address)

  console.log("Waiting for set_address_of_controller...");

  console.log(await provider.getTransactionStatus(res.transaction_hash))

  try {
    const batchRes = await signer.execute({
      contractAddress: arbiter,
      entrypoint: "batch_set_controller_addresses",
      calldata: [towerDefence.address, towerDefenceStorage.address]
    }, undefined, {
      maxFee: '0'
    });
    console.log("Waiting for batch_set_controller_addresses...");

    await provider.waitForTransaction(batchRes.transaction_hash);
    console.log(
      await provider.getTransactionStatus(batchRes.transaction_hash)
    );
  } catch (e) {
    console.error("Error Configuring modules: ", e);
  }
};

deploy().catch((e) => console.error(e));
