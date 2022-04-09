import { Provider, ec, encode, number } from 'starknet'
import fs from 'fs'

import { checkDeployment, deployContract, getDeployedAddressInt, getOwnerAccountInt, logDeployment, setupDeploymentDir, writeDeployment, writeNileDeploymentFile } from '../../helpers'

async function main() {
  const contractName = 'Bridge'

  setupDeploymentDir()
  checkDeployment(contractName)

  // Collect params
  const ownerAccount = getOwnerAccountInt()

  const testERC721: any = getDeployedAddressInt("Test_Realms_ERC721")

  // owner : felt,
  // l2_realms_address : felt
  await deployContract(contractName, contractName, [BigInt(ownerAccount).toString(), testERC721])
}

main()