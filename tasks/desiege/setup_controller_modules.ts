
import { getDeployedAddressInt, provider, getSigner } from "../helpers";

// Re-runs will use the same files
const deploy = async () => {
  const signer = getSigner();

  const towerDefence = getDeployedAddressInt("01_TowerDefence");
  const towerDefenceStorage = getDeployedAddressInt("02_TowerDefenceStorage");
  const controller = getDeployedAddressInt("ModuleController");

  try {
    // The arbiter is the only contract that can modify the controller
    const arbiter = getDeployedAddressInt("Arbiter");
    const res = await signer.execute({
      contractAddress: arbiter,
      entrypoint: "set_address_of_controller",
      calldata: [controller]
    });

    console.log(res);
    await provider.waitForTransaction(res.transaction_hash);
    const status = await provider.getTransactionStatus(
      res.transaction_hash
    );
    console.log(status);

    const batchRes = await signer.execute({
      contractAddress: arbiter,
      entrypoint: "batch_set_controller_address",
      calldata: [towerDefence, towerDefenceStorage]
    });
    await provider.waitForTransaction(batchRes.transaction_hash);
    console.log(
      await provider.getTransactionStatus(batchRes.transaction_hash)
    );
  } catch (e) {
    console.error("Error Configuring modules: ", e);
  }
};

deploy().catch((e) => console.error(e));
