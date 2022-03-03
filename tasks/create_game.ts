import { toBN } from "starknet/dist/utils/number";
import { getSelectorFromName } from "starknet/dist/utils/stark";
import { getDeployment, getSigner, provider } from "./helpers";

const startGame = async () => {

    const towerDefence = getDeployment("01_TowerDefence");
    const towerDefenceStorage = getDeployment("02_TowerDefenceStorage");
    const elements = getDeployment("04_Elements");

    const getLatestIndex = await provider.callContract({
        contract_address: towerDefenceStorage.address,
        entry_point_selector: getSelectorFromName("get_latest_game_index"),
        calldata: []
    });

    let [lastIndex] = getLatestIndex.result;
    const lastIndexInt = parseInt(lastIndex);
    const nextIndex = lastIndexInt + 1;

    console.log("nextIndex", nextIndex)

    const tokenOffsetBase = 10
    
    const lightBalance = await provider.callContract({
        contract_address: elements.address,
        entry_point_selector: getSelectorFromName("get_total_minted"),
        calldata: [
            (((nextIndex) * tokenOffsetBase) + 1).toString()
        ]
    })
    const darkBalance = await provider.callContract({
        contract_address: elements.address,
        entry_point_selector: getSelectorFromName("get_total_minted"),
        calldata: [
            (((nextIndex) * tokenOffsetBase) + 2).toString()
        ]
    })
    const light = toBN(lightBalance.result[0])
    const dark = toBN(darkBalance.result[0])

    console.log("Total light minted", light.toString(10))
    console.log("Total dark minted", dark.toString(10))

    const ratio = light.div(dark);
    console.log("ratio", ratio.toString());

    // The ratio should be imbalanced because
    // dark needs to have sufficient tokens to both
    // bring down the shield to 0 and reduce tower health to 0
    // Therefore, the tower health should be:
    // Tower health = Dark - light

    // Calculate the initial health of the tower
    let initialHealth = dark.sub(light);
    console.log("initial health", initialHealth.toString(10));

    // Since there is a restriction to play,
    // there could form a chance of a deadlock, where light has minted more than dark
    // and nobody else can/wants to mint. In this case, start the main health
    // with enough health for dark to win even in early stages, but not small enough that 
    // it's too easy for dark to win.
    if(initialHealth.isZero() || initialHealth.isNeg()){
        
        const targetInitHealth = Math.min(10 * 100 * 100, dark.div(toBN(2)).toNumber())
        initialHealth = toBN(targetInitHealth);
        console.log("Light minted more, setting initial health to ", initialHealth.toString(10))
    }

    const res = await getSigner().invokeFunction(
        towerDefence.address,
        getSelectorFromName("create_game"),
        [
            initialHealth.toString()
        ]
    )

    await provider.waitForTx(res.transaction_hash)
    console.log(await provider.getTransactionStatus(res.transaction_hash))
}

startGame().catch((e:any) => console.error(e.response.data))