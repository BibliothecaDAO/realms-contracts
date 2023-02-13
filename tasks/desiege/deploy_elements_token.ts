
import { deployContract, getOwnerAccountInt } from '../helpers'

async function main() {
  const contractName = 'ERC1155_Mintable_Ownable'

  // Collect params
  const ownerAccount = getOwnerAccountInt()

  await deployContract(contractName, "ERC1155_ElementsToken", [ownerAccount])
}

main()