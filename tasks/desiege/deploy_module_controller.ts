
import { deployContract, getDeployedAddressInt } from '../helpers'

async function main() {
  const contractName = 'ModuleController'

  // Collect params
  const arbiterAddress = getDeployedAddressInt('Arbiter')

  // Magically deploy + write all files and stuff 
  await deployContract(contractName, contractName, [arbiterAddress])
}

main()