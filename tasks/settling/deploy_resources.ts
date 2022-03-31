
import { deployContract, getDeployedAddressInt, getOwnerAccountInt } from '../helpers'
import { toFelt } from 'starknet/dist/utils/number'

async function main() {
    const contractName = 'Resources_ERC1155_Mintable_Burnable'

    // Collect params
    const ownerAccount = getOwnerAccountInt()
    const uri: string = toFelt("1234")

    // Magically deploy + write all files and stuff 
    await deployContract(contractName, contractName, [uri, ownerAccount])
}

main().then(e => console.error(e))