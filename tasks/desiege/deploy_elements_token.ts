
import { deployContract, getOwnerAccountInt } from '../helpers'

async function main() {
  const contractName = 'ERC1155'

  // Collect params
  const ownerAccount = getOwnerAccountInt()

  // Magically deploy + write all files and stuff 
  const tokenURIStruct = ["1","1","1","1","1"]

  await deployContract(contractName, "ERC1155_ElementsToken", [ownerAccount, ...tokenURIStruct])
}

main()