// used to set the initial known module addresses
import { deployContract, getDeployedAddressInt, getOwnerAccountInt, getSigner } from '../../helpers'

async function main() {
    const contractName = 'Arbiter'

    const arbiter = getDeployedAddressInt('Arbiter');
    // Collect params
    const L01_Settling = getDeployedAddressInt("L01_Settling"); // module id 1
    const S01_Settling = getDeployedAddressInt("S01_Settling"); // module id 2
    const L02_Resources = getDeployedAddressInt("L02_Resources"); // module id 3
    const S02_Resources = getDeployedAddressInt("S02_Resources"); // module id 4
    const L03_Buildings = getDeployedAddressInt("L03_Buildings"); // module id 5
    const S03_Buildings = getDeployedAddressInt("S03_Buildings"); // module id 6
    const L04_Calculator = getDeployedAddressInt("L04_Calculator"); // module id 7

    // Magically deploy + write all files and stuff 
    console.log(L01_Settling, S01_Settling, L02_Resources, S02_Resources, L03_Buildings, S03_Buildings, L04_Calculator)
    const res = await getSigner().execute(
        {
            contractAddress: arbiter,
            entrypoint: "batch_set_controller_addresses",
            calldata: [L01_Settling, S01_Settling, L02_Resources, S02_Resources, L03_Buildings, S03_Buildings, L04_Calculator]
        }
    )

    console.log("batch_set_controller_addresses", res)
}

main().then(e => console.error(e))