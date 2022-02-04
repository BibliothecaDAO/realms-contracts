
import { defaultProvider } from "starknet";
import { getSelectorFromName } from "starknet/dist/utils/stark";
import { getDeployedAddressInt, getSigner } from "./helpers";

// Re-runs will use the same files
const deploy = async () => {
  const signor = getSigner();

  const towerDefence = getDeployedAddressInt("01_TowerDefence");
  const towerDefenceStorage = getDeployedAddressInt("02_TowerDefenceStorage");
  const controller = getDeployedAddressInt("ModuleController");

  try {
    // The arbiter is the only contract that can modify the controller
    const arbiter = getDeployedAddressInt("Arbiter");
    const res = await signor.invokeFunction(
      arbiter,
      getSelectorFromName("set_address_of_controller"),
      [controller]
    );

    console.log(res);
    await defaultProvider.waitForTx(res.transaction_hash);
    const status = await defaultProvider.getTransactionStatus(
      res.transaction_hash
    );
    console.log(status);

    const batchRes = await signor.invokeFunction(
      arbiter,
      getSelectorFromName("batch_set_controller_addresses"),
      [towerDefence, towerDefenceStorage]
    );
    await defaultProvider.waitForTx(batchRes.transaction_hash);
    console.log(
      await defaultProvider.getTransactionStatus(batchRes.transaction_hash)
    );
  } catch (e) {
    console.error("Error Configuring modules: ", e);
  }
};

deploy().catch((e) => console.error(e));
