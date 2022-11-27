%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.loot.loot.metadata import LootUri
from contracts.loot.constants.adventurer import AdventurerState
from contracts.loot.constants.item import Item, ItemIds
from contracts.settling_game.utils.game_structs import ExternalContractIds

from tests.protostar.loot.setup.interfaces import IAdventurer, ILoot, ILords, IRealms
from tests.protostar.loot.setup.setup import Contracts, deploy_all

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() 
{
    alloc_locals;

    let addresses: Contracts = deploy_all();

    %{
        context.account_1 = ids.addresses.account_1
        context.xoroshiro = ids.addresses.xoroshiro
        context.realms = ids.addresses.realms
        context.adventurer = ids.addresses.adventurer
        context.loot = ids.addresses.loot
        context.lords = ids.addresses.lords
        stop_prank_realms = start_prank(ids.addresses.account_1, ids.addresses.realms)
        stop_prank_adventurer = start_prank(ids.addresses.account_1, ids.addresses.adventurer)
        stop_prank_loot = start_prank(ids.addresses.account_1, ids.addresses.loot)
        stop_prank_lords = start_prank(ids.addresses.account_1, ids.addresses.lords)
    %}

    IRealms.set_realm_data(addresses.realms, Uint256(10, 0), 'Test Realm', 1);

    ILords.approve(addresses.lords, addresses.adventurer, Uint256(10000, 0));

    // Store item ids and equip to adventurer

    let (timestamp) = get_block_timestamp();

    %{
        stop_mock = mock_call(1, 'next', [1])
    %}
    // Mint 8 tokens
    ILoot.mint(addresses.loot, addresses.account_1);
    ILoot.mint(addresses.loot, addresses.account_1);
    ILoot.mint(addresses.loot, addresses.account_1);
    ILoot.mint(addresses.loot, addresses.account_1);
    ILoot.mint(addresses.loot, addresses.account_1);
    ILoot.mint(addresses.loot, addresses.account_1);
    ILoot.mint(addresses.loot, addresses.account_1);
    ILoot.mint(addresses.loot, addresses.account_1);
    %{
        stop_mock()
        stop_prank_lords()
        stop_prank_lords = start_prank(ids.addresses.adventurer, ids.addresses.lords)
    %}

    // Set tokens to ids above for testing
    ILoot.setItemById(addresses.loot, Uint256(1,0), ItemIds.Wand, 15, 0, 0, 0);
    ILoot.setItemById(addresses.loot, Uint256(2,0), ItemIds.DivineRobe, 15, 0, 0, 0);
    ILoot.setItemById(addresses.loot, Uint256(3,0), ItemIds.LinenHood, 15, 0, 0, 0);
    ILoot.setItemById(addresses.loot, Uint256(4,0), ItemIds.SilkSash, 15, 0, 0, 0);
    ILoot.setItemById(addresses.loot, Uint256(5,0), ItemIds.DivineSlippers, 15, 0, 0, 0);
    ILoot.setItemById(addresses.loot, Uint256(6,0), ItemIds.WoolGloves, 15, 0, 0, 0);
    ILoot.setItemById(addresses.loot, Uint256(7,0), ItemIds.Amulet, 15, 0, 0, 0);
    ILoot.setItemById(addresses.loot, Uint256(8,0), ItemIds.PlatinumRing, 15, 0, 0, 0);

    // Mint adventurer with random params
    IAdventurer.mint(
        addresses.adventurer, 
        addresses.account_1, 
        4, 
        10, 
        'Test', 
        8, 
        'QmUn4BZtz4tw3rzpZHpT2oE',
        'o6guw2FxsiPEyvfRFnUJWzZ'
    );

    %{
        stop_prank_loot()
    %}
    IAdventurer.equip_item(addresses.adventurer, Uint256(1,0), Uint256(1,0));
    IAdventurer.equip_item(addresses.adventurer, Uint256(1,0), Uint256(2,0));
    IAdventurer.equip_item(addresses.adventurer, Uint256(1,0), Uint256(3,0));
    IAdventurer.equip_item(addresses.adventurer, Uint256(1,0), Uint256(4,0));
    IAdventurer.equip_item(addresses.adventurer, Uint256(1,0), Uint256(5,0));
    IAdventurer.equip_item(addresses.adventurer, Uint256(1,0), Uint256(6,0));
    IAdventurer.equip_item(addresses.adventurer, Uint256(1,0), Uint256(7,0));
    IAdventurer.equip_item(addresses.adventurer, Uint256(1,0), Uint256(8,0));

    %{
        stop_prank_realms()
        stop_prank_adventurer()
        stop_prank_lords()
    %}
    return ();
}

@external
func test_metadata{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local adventurer_address;
    local loot_address;

    %{
        ids.adventurer_address = context.adventurer
        ids.loot_address = context.loot
    %}
    let id = Uint256(1, 0);
    let (data_len, data) = IAdventurer.tokenURI(adventurer_address, id);

    %{
        array = []
        for i in range(ids.data_len):
            path = memory[ids.data+i]
            array.append(path.to_bytes(31, "big").decode())
        string_data = ''.join(array).replace('\x00', '')
        print(string_data)
        # assert string_data == 'data:application/json,{"description":"Adventurer","name":"Test","image":"https://ipfs.io/ipfs/QmUn4BZtz4tw3rzpZHpT2oEo6guw2FxsiPEyvfRFnUJWzZ.webp","attributes":[{"trait_type":"Race","value":"Human"},{"trait_type":"Home Realm","value":"Test Realm"},{"trait_type":"Birthdate","value":"0"},{"trait_type":"Health","value":"100"},{"trait_type":"Level","value":"1"},{"trait_type":"Order","value":"Protection"},{"trait_type":"Strength","value":"0"},{"trait_type":"Dexterity","value":"0"},{"trait_type":"Vitality","value":"0"},{"trait_type":"Intelligence","value":"0"},{"trait_type":"Wisdom","value":"0"},{"trait_type":"Charisma","value":"0"},{"trait_type":"Luck","value":"0"},{"trait_type":"XP","value":"0"},{"trait_type":"Weapon","value":"Wand"},{"trait_type":"Chest","value":"Divine Robe"},{"trait_type":"Head","value":"Linen Hood"},{"trait_type":"Waist","value":"Silk Sash"},{"trait_type":"Feet","value":"Divine Slippers"},{"trait_type":"Hand","value":"Wool Gloves"},{"trait_type":"Neck","value":"Amulet"},{"trait_type":"Ring","value":"Platinum Ring"},{"trait_type":"Status","value":"Idle"},]}'
    %}

    return ();
}
