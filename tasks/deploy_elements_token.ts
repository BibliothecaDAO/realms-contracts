import { Provider, ec, encode, number } from 'starknet'
import fs from 'fs'

import { checkDeployment, deployContract, getDeployedAddressInt, getOwnerAccountInt, logDeployment, setupDeploymentDir, writeDeployment, writeNileDeploymentFile } from './helpers'

async function main() {
  const contractName = 'ERC1155'

  setupDeploymentDir()
  checkDeployment(contractName)

  // Collect params
  const ownerAccount = getOwnerAccountInt()

  // Magically deploy + write all files and stuff 
  const tokenURIStruct = ["1","1","1","1","1"]

  await deployContract(contractName, "ERC1155_ElementsToken", [ownerAccount, ...tokenURIStruct])
}

main()