
import { deployContract, getDeployedAddressInt, getOwnerAccountInt } from '../../helpers'

async function main() {
  const contractName = 'ModuleController'

  const ownerAccount = getOwnerAccountInt()
  // Collect params
  const arbiter = getDeployedAddressInt("Arbiter");
  const realms = getDeployedAddressInt("Realms_ERC721_Mintable");
  const s_realms = getDeployedAddressInt("S_Realms_ERC721_Mintable");
  const lords = getDeployedAddressInt("ERC20_Mintable");
  const resources = getDeployedAddressInt("Resources_ERC1155_Mintable_Burnable");
  const storage = getDeployedAddressInt("Storage");
  console.log(arbiter)
  console.log(lords)
  console.log(resources)
  console.log(realms)
  console.log(ownerAccount)
  console.log(s_realms)
  console.log(storage)
  // Magically deploy + write all files and stuff 
  await deployContract(contractName, contractName, [arbiter, lords, resources, realms, ownerAccount, s_realms, storage])
}

main().then(e => console.error(e))