import { Provider, ec, encode, number } from 'starknet'
import fs from 'fs'

import { checkDeployment, deployContract, getDeployedAddressInt, logDeployment, setupDeploymentDir, writeDeployment, writeNileDeploymentFile } from './helpers'

async function main() {
  const contractName = '02_TowerDefenceStorage'

  setupDeploymentDir()
  checkDeployment(contractName)

  // Collect params
  const moduleControllerAddress = getDeployedAddressInt('ModuleController')

  // Magically deploy + write all files and stuff 
  await deployContract(contractName, contractName, [moduleControllerAddress])
}

main()