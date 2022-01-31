import { Provider, ec, encode, number } from 'starknet'
import fs from 'fs'

import { checkDeployment, deployContract, getOwnerAccountInt, logDeployment, setupDeploymentDir, writeDeployment, writeNileDeploymentFile } from './helpers'

async function main() {
  const contractName = 'Arbiter'

  setupDeploymentDir()
  checkDeployment(contractName)

  // Collect params
  const ownerAccount = getOwnerAccountInt()

  // Magically deploy + write all files and stuff 
  await deployContract(contractName, contractName, [ownerAccount])
}

main()