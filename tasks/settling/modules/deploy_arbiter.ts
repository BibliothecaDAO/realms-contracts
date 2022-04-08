
import { deployContract, getOwnerAccountInt, setupDeploymentDir } from '../../helpers'

async function main() {
  const contractName = 'Arbiter'

  setupDeploymentDir()

  // Collect params
  const ownerAccount = getOwnerAccountInt()

  // Magically deploy + write all files and stuff 
  await deployContract(contractName, contractName, [ownerAccount])
}

main()