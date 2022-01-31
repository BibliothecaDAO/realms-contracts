import { Provider, ec, encode, number } from 'starknet'
import fs from 'fs'

import { checkDeployment, deployContract, getDeployedAddressInt, logDeployment, setupDeploymentDir, writeDeployment, writeNileDeploymentFile } from './helpers'

async function main() {
  const contractName = '01_TowerDefence'

  setupDeploymentDir()
  checkDeployment(contractName)

  // Collect params
  const moduleControllerAddress = getDeployedAddressInt('ModuleController')
  const elementsTokenAddress = getDeployedAddressInt('ERC1155_ElementsToken')

  // Magically deploy + write all files and stuff
  await deployContract(contractName, contractName, [moduleControllerAddress, elementsTokenAddress, "10", "36"])
}

main()