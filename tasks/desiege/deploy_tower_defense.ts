
import {
  deployContract,
  getDeployment,
  getOwnerAccountInt,
} from "../helpers";

async function main() {
  const contractName = "01_TowerDefence";

  // Collect params
  const moduleControllerAddress = getDeployment("DesiegeModuleController").address;
  const elementsTokenAddress = getDeployment("ERC1155_ElementsToken").address;

  // Magically deploy + write all files and stuff

  const blocksPerMin = "1";
  // Start at 8 hours per game for alpha testing
  const hoursPerGame = "24";

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
