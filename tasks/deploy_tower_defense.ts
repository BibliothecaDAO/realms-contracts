
import {
  checkDeployment,
  deployContract,
  getDeployedAddressInt,
  getOwnerAccountInt,
  setupDeploymentDir,
} from "./helpers";

async function main() {
  const contractName = "01_TowerDefence";

  setupDeploymentDir();
  checkDeployment(contractName);

  // Collect params
  const moduleControllerAddress = getDeployedAddressInt("ModuleController");
  const elementsTokenAddress = getDeployedAddressInt("ERC1155_ElementsToken");

  // Magically deploy + write all files and stuff

  const blocksPerMin = "4";
  // Start at 8 hours per game for alpha testing
  const hoursPerGame = "8";

  const owner = getOwnerAccountInt()

  await deployContract(contractName, contractName, [
    moduleControllerAddress,
    elementsTokenAddress,
    blocksPerMin,
    hoursPerGame,
    owner
  ]);
}

main();
