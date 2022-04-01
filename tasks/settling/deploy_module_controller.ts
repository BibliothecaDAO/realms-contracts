
import { deployContract, getDeployedAddressInt, getOwnerAccountInt } from '../helpers'

async function main() {
  const contractName = 'ModuleController'

  const ownerAccount = getOwnerAccountInt()
  // Collect params
  const arbiter = getDeployedAddressInt("Arbiter");
  const realms = getDeployedAddressInt("Realms_ERC721_Mintable");
  const s_realms = getDeployedAddressInt("S_Realms_ERC721_Mintable");
  const lords = getDeployedAddressInt("ERC20_Mintable");
  const resources = getDeployedAddressInt("Resources_ERC1155_Mintable_Burnable");

  // Magically deploy + write all files and stuff 
  await deployContract(contractName, contractName, [arbiter, lords, resources, realms, ownerAccount, s_realms])
}

main().then(e => console.error(e))