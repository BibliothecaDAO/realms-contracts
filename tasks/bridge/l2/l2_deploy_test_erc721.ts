import { Provider, ec, encode, number } from 'starknet'
import fs from 'fs'

import { checkDeployment, deployContract, getOwnerAccountInt, logDeployment, setupDeploymentDir, writeDeployment, writeNileDeploymentFile } from '../../helpers'

async function main() {
  const contractName = 'Test_Realms_ERC721'

  setupDeploymentDir()
  checkDeployment(contractName)

  // Collect params
  const ownerAccount = getOwnerAccountInt()

  console.log(ownerAccount)

  // owner : felt,
  // l2_realms_address : felt
  await deployContract(contractName, contractName, ["0", "0", ownerAccount])
}

main()