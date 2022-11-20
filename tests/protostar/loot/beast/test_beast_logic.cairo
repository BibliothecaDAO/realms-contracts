%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.loot.constants.beast import Beast
from contracts.loot.constants.item import Item, ItemIds

from tests.protostar.loot.setup.interfaces import ILoot, IRealms, IAdventurer, IBeast
from tests.protostar.loot.setup.setup import Contracts, deploy_all
from tests.protostar.loot.test_structs import (
    TestAdventurerState,
    get_adventurer_state,
    TestUtils,
    TEST_WEAPON_TOKEN_ID,
    TEST_DAMAGE_HEALTH_REMAINING,
    TEST_DAMAGE_OVERKILL,
)

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let addresses: Contracts = deploy_all();

    %{
        context.account_1 = ids.addresses.account_1
        context.xoroshiro = ids.addresses.xoroshiro
        context.realms = ids.addresses.realms
        context.adventurer = ids.addresses.adventurer
        context.loot = ids.addresses.loot
        context.beast = ids.addresses.beast
        context.lords = ids.addresses.lords
        stop_prank_realms = start_prank(ids.addresses.account_1, ids.addresses.realms)
        stop_prank_adventurer = start_prank(ids.addresses.account_1, ids.addresses.adventurer)
        stop_prank_lords = start_prank(ids.addresses.account_1, ids.addresses.lords)
    %}
    let (timestamp) = get_block_timestamp();
    let weapon_id: Item = Item(ItemIds.Wand, 0, 0, 0, 0, 0, 0, 0, 0, timestamp, 0, 0, 0); // Wand
    ILoot.mint(addresses.loot, addresses.account_1);
    ILoot.setItemById(addresses.loot, Uint256(1,0), weapon_id);
    IRealms.set_realm_data(addresses.realms, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(addresses.adventurer, addresses.account_1, 4, 10, 'Test', 8);
    IAdventurer.equip_item(addresses.adventurer, Uint256(1,0), Uint256(1,0));
    %{
        stop_prank_realms()
        stop_prank_adventurer()
        stop_prank_lords()
    %}
    return ();
}

@external
func test_create{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_1_address;
    local xoroshiro_address;
    local adventurer_address;
    local beast_address;

    %{
        ids.account_1_address = context.account_1
        ids.xoroshiro_address = context.xoroshiro
        ids.adventurer_address = context.adventurer
        ids.beast_address = context.beast
        stop_prank_beast = start_prank(ids.adventurer_address, ids.beast_address)
        stop_mock = mock_call(ids.xoroshiro_address, 'next', [0])
    %}

    let (beast_id) = IBeast.create(beast_address, Uint256(1,0));

    let (beast) = IBeast.get_beast_by_id(beast_address, beast_id);

    assert beast.Id = 1;
    assert beast.Health = 100;
    assert beast.Type = 103;
    assert beast.Rank = 1;
    assert beast.Prefix_1 = 1;
    assert beast.Prefix_2 = 1;
    assert beast.Adventurer = 1;
    assert beast.XP = 0;
    assert beast.SlainBy = 0;
    assert beast.SlainOnDate = 0;

    %{
        stop_prank_beast()
        stop_mock()
    %}

    return ();
}

@external
func test_attack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    
    local account_1_address;
    local xoroshiro_address;
    local adventurer_address;
    local beast_address;

    %{
        ids.account_1_address = context.account_1
        ids.xoroshiro_address = context.xoroshiro
        ids.adventurer_address = context.adventurer
        ids.beast_address = context.beast
        stop_mock = mock_call(ids.beast_address, 'calculate_damage_to_beast', [50])
        stop_prank_beast = start_prank(ids.adventurer_address, ids.beast_address)
    %}

    // Create beast
    let (beast_id) = IBeast.create(beast_address, Uint256(1,0));

    // set beast to rank 5
    let beast = Beast(
        1,
        100,
        103,
        5,
        1,
        1,
        1,
        0,
        0,
        0
    );
    IBeast.set_beast_by_id(beast_address, Uint256(1,0), beast);

    IAdventurer.explore(adventurer_address);

    %{
        stop_prank_beast()
        stop_prank_beast = start_prank(ids.account_1_address, ids.beast_address)
    %}

    IBeast.attack(beast_address, Uint256(1,0));

    %{
        stop_mock()
        stop_prank_beast()
    %}

    return ();
}

// @external
// func test_flee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
// }