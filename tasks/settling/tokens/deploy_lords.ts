
import { deployContract, getDeployedAddressInt, getOwnerAccountInt } from '../../helpers'
import { toFelt } from 'starknet/dist/utils/number'
import { BigNumberish, toBN } from 'starknet/dist/utils/number'
import { Uint256, bnToUint256 } from 'starknet/dist/utils/uint256'

async function main() {
    const contractName = 'Lords_ERC20_Mintable'

    // Collect params
    const ownerAccount = getOwnerAccountInt()
    const name: string = toFelt("1014")
    const symbol: string = toFelt("1014")

    const initial_supply: Uint256 = bnToUint256("1000000000000000000000000")

    // Magically deploy + write all files and stuff 
    // TODO: Add treasury Account
    await deployContract(contractName, contractName, [name, symbol, 18, initial_supply.low.toString(), initial_supply.high.toString(), ownerAccount, ownerAccount])
}

export default main().then(e => console.error(e))