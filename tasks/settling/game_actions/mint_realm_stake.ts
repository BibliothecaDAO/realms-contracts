// used to set the initial known module addresses
import { deployContract, getDeployedAddressInt, getOwnerAccountInt, getSigner, sendtx } from '../../helpers'
import { Uint256, bnToUint256 } from 'starknet/dist/utils/uint256'
async function main() {
    const contractName = 'Arbiter'

    // const arbiter = getDeployedAddressInt('Arbiter');
    const ownerAccount = getOwnerAccountInt()
    // Collect params
    // const L01_Settling = getDeployedAddressInt("L01_Settling"); // module id 1
    const Realms_ERC721_Mintable = getDeployedAddressInt("Realms_ERC721_Mintable"); // module id 1

    const realm: Uint256 = bnToUint256("3")

    const mint = await sendtx(
        {
            contractAddress: Realms_ERC721_Mintable,
            entrypoint: "mint",
            calldata: [ownerAccount, realm.low.toString(), realm.high.toString()]
        }
    )

    // const res = await getSigner().execute(
    //     {
    //         contractAddress: L01_Settling,
    //         entrypoint: "settle",
    //         calldata: [realm.low.toString(), realm.high.toString()]
    //     }
    // )
    console.log("mint", mint)
    // console.log("settle", res)
}

main().then(e => console.error(e))