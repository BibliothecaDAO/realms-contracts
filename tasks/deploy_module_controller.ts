import { Provider, ec, encode, number } from 'starknet'
import fs from 'fs'

import { checkDeployment, deployContract, getDeployedAddressInt, logDeployment, setupDeploymentDir, writeDeployment, writeNileDeploymentFile } from './helpers'

async function main() {
  const contractName = 'ModuleController'

  setupDeploymentDir()
  checkDeployment(contractName)

  // Collect params
  const arbiterAddress = getDeployedAddressInt('Arbiter')

  // Magically deploy + write all files and stuff 
  await deployContract(contractName, contractName, [arbiterAddress])
}

main()