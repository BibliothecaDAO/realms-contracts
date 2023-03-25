
import { deployContract, getDeployedAddressInt } from '../helpers'

async function main() {
  const contractName = '02_TowerDefenceStorage'

  // Collect params
  const moduleControllerAddress = getDeployedAddressInt('DesiegeModuleController')

  // Magically deploy + write all files and stuff 
  await deployContract(contractName, contractName, [moduleControllerAddress])
}

main()