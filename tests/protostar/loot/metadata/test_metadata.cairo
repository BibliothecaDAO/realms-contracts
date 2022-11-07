%lang starknet

from starkware.cairo.common.uint256 import Uint256, uint256_add

from contracts.loot.metadata import Uri
from contracts.loot.constants.adventurer import Adventurer, AdventurerState
from contracts.settling_game.utils.game_structs import RealmData
from contracts.loot.constants.item import ItemIds

const CONTROLLER_ADDR = 123;
const REALMS_ADDR = 456;

@external
func test_metadata{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    %{
        stop_mock_controller = mock_call(ids.CONTROLLER_ADDR, 'get_external_contract_address', [ids.REALMS_ADDR])
        stop_mock_realms = mock_call(ids.REALMS_ADDR, 'get_realm_name', [398550225022444783103085])
    %}
    let id = Uint256(1,0);

    let adventurer_state = AdventurerState(
        3, // Race
        13, // HomeRealm
        1667831589, // Birthdate
        'Test', // Name
        100, // Health
        5, // Level
        6, // Order
        20, // Strength
        10, // Dexterity
        50, // Vitality
        30, // Intelligence
        15, // Wisdom
        40, // Charisma
        20, // Luck
        500, // XP
        ItemIds.Wand,// WeaponId
        ItemIds.DivineRobe, // ChestId
        ItemIds.Helm, // HeadId
        ItemIds.HardLeatherBelt, // WaistId
        ItemIds.Gauntlets, // FeetId
        ItemIds.Gloves, // HandsId
        ItemIds.Amulet, // NeckId
        ItemIds.GoldRing // RingId
    );
    let (data_len, data) = Uri.build(id, adventurer_state, CONTROLLER_ADDR);

    %{
        array = []
        for i in range(ids.data_len):
            path = memory[ids.data+i]
            array.append(path.to_bytes(31, "big").decode())
        string_data = ''.join(array).replace('\x00', '')
        assert string_data == 'data:application/json,{"description":"Adventurer","name":"Test","image":"https://d23fdhqc1jb9no.cloudfront.net/Adventurer/1.webp","attributes":[{"trait_type":"Race","value":"Giant"},{"trait_type":"Home Realm","value":"Test Realm"},{"trait_type":"Birthdate","value":"1667831589"},{"trait_type":"Health","value":"100"},{"trait_type":"Level","value":"5"},{"trait_type":"Order","value":"Brilliance"},{"trait_type":"Strength","value":"20"},{"trait_type":"Dexterity","value":"10"},{"trait_type":"Vitality","value":"50"},{"trait_type":"Intelligence","value":"30"},{"trait_type":"Wisdom","value":"15"},{"trait_type":"Charisma","value":"40"},{"trait_type":"Luck","value":"20"},{"trait_type":"XP","value":"500"},{"trait_type":"Weapon","value":"Wand"},{"trait_type":"Chest","value":"Divine Robe"},{"trait_type":"Head","value":"Helm"},{"trait_type":"Waist","value":"Hard Leather Belt"},{"trait_type":"Feet","value":"Gauntlets"},{"trait_type":"Hand","value":"Gloves"},{"trait_type":"Neck","value":"Amulet"},{"trait_type":"Ring","value":"Gold Ring"},]}'
    %}
    return ();
}
