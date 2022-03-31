
import { deployContract, getDeployedAddressInt, getOwnerAccountInt } from '../helpers'

async function main() {
  const contractName = 'ModuleController'

  // Collect params
  const arbiter = getDeployedAddressInt("Arbiter");
  const realms = getDeployedAddressInt("Realms_ERC721_Mintable");
  const lords = getDeployedAddressInt("ERC20_Mintable");

  // Magically deploy + write all files and stuff 
  await deployContract(contractName, contractName, [arbiter])
}

main().then(e => console.error(e))