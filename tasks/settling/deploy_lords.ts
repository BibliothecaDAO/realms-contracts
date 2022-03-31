
import { deployContract, getDeployedAddressInt, getOwnerAccountInt } from '../helpers'
import { toFelt } from 'starknet/dist/utils/number'
import { BigNumberish, toBN } from 'starknet/dist/utils/number'

async function main() {
    const contractName = 'ERC20_Mintable'

    // Collect params
    const ownerAccount = getOwnerAccountInt()
    const name: string = toFelt("1014")
    const symbol: string = toFelt("1014")

    const initial_supply = toBN(1000).toString()

    // Magically deploy + write all files and stuff 
    // TODO: Add treasury Account
    await deployContract(contractName, contractName, [name, symbol, 18, initial_supply, ownerAccount])
}

main().then(e => console.error(e))