%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.loot.constants.adventurer import AdventurerState, AdventurerStatus
from contracts.loot.constants.beast import Beast
from contracts.loot.constants.item import (
    Item, 
    ItemIds, 
    ItemType, 
    ItemMaterial, 
    ItemSlot
)
from contracts.loot.constants.rankings import ItemRank
from tests.protostar.loot.setup.interfaces import ILoot, IRealms, IAdventurer, IBeast, ILords
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
        stop_prank_loot = start_prank(ids.addresses.account_1, ids.addresses.loot)
    %}

    ILords.approve(addresses.lords, addresses.adventurer, Uint256(10000, 0));

    let weapon_id: Item = Item(
        ItemIds.Wand,
        ItemSlot.Wand, 
        ItemType.Wand, 
        ItemMaterial.Wand, 
        ItemRank.Wand, 
        1, 
        1, 
        1, 
        10, 
        0, 
        0, 
        0,
        0
    ); // Wand
    ILoot.mint(addresses.loot, addresses.account_1);
    ILoot.setItemById(addresses.loot, Uint256(1,0), weapon_id);
    IRealms.set_realm_data(addresses.realms, Uint256(13, 0), 'Test Realm', 1);

    %{
        stop_prank_lords()
    %}

    IAdventurer.mint(addresses.adventurer, addresses.account_1, 4, 10, 'Test', 8);
    %{
        stop_prank_loot()
    %}
    IAdventurer.equip_item(addresses.adventurer, Uint256(1,0), Uint256(1,0));
    %{
        stop_prank_realms()
        stop_prank_adventurer()
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
    assert beast.AttackType = 103;
    assert beast.ArmorType = 203;
    assert beast.Rank = 1;
    assert beast.Prefix_1 = 1;
    assert beast.Prefix_2 = 1;
    assert beast.Adventurer = 1;
    assert beast.XP = 1;
    assert beast.SlainBy = 0;
    assert beast.SlainOnDate = 0;

    %{
        stop_prank_beast()
        stop_mock()
    %}

    return ();
}

@external
func test_not_kill{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
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
        stop_mock_adventurer_random = mock_call(ids.xoroshiro_address, 'next', [1])
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}
    // discover and create beast
    let adventurer_token_id_1 = Uint256(1,0);
    let beast_token_id_1 = Uint256(1,0);
    
    IAdventurer.explore(adventurer_address, adventurer_token_id_1);

    %{ 
        stop_prank_adventurer()
        stop_prank_beast = start_prank(ids.account_1_address, ids.beast_address)
    %}

    IBeast.attack(beast_address, beast_token_id_1);

    let (local updated_beast) = IBeast.get_beast_by_id(beast_address,beast_token_id_1);
    let (local updated_adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, adventurer_token_id_1);

    %{
        stop_mock_adventurer_random()
        stop_prank_beast()
    %}

    // As part of attacking the Beast, the adventurer takes 12hp of damage
    assert updated_beast.Health = 64;
    assert updated_adventurer.Health = 88;



    return ();
}

@external
func test_kill{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    
    local account_1_address;
    local xoroshiro_address;
    local adventurer_address;
    local beast_address;
    local loot_address;

    %{
        ids.account_1_address = context.account_1
        ids.xoroshiro_address = context.xoroshiro
        ids.adventurer_address = context.adventurer
        ids.beast_address = context.beast
        ids.loot_address = context.loot
        stop_mock_adventurer_random = mock_call(ids.xoroshiro_address, 'next', [1])
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
        stop_prank_loot = start_prank(ids.account_1_address, ids.loot_address)
    %}
    // discover and create beast
    IAdventurer.explore(adventurer_address, Uint256(1,0));

    %{ 
        stop_prank_adventurer()
        stop_prank_beast = start_prank(ids.account_1_address, ids.beast_address)
    %}

    let strong_item: Item = Item(
        ItemIds.Katana,
        ItemSlot.Katana, 
        ItemType.Katana, 
        ItemMaterial.Katana, 
        ItemRank.Katana, 
        1, 
        1, 
        1, 
        20,  // high greatness
        0, 
        0, 
        0, 
        0
    ); // Mace

    ILoot.setItemById(loot_address, Uint256(1,0), strong_item);

    IBeast.attack(beast_address, Uint256(1,0));

    let (local updated_beast) = IBeast.get_beast_by_id(beast_address, Uint256(1,0));

    let (local adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1,0));

    // Beast should be dead
    assert updated_beast.Health = 0;

    // Since it was a one-hit kill, adventurer didn't take damage
    assert adventurer.Health = 100;

    %{
        stop_mock_adventurer_random()
        stop_prank_beast()
    %}

    return ();
}

@external
func test_ambushed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
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
        stop_mock_adventurer_random = mock_call(ids.xoroshiro_address, 'next', [1])
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}
    // discover and create beast
    IAdventurer.explore(adventurer_address, Uint256(1,0));

    %{ 
        stop_mock_adventurer_random()
        stop_prank_adventurer()
        stop_prank_beast = start_prank(ids.account_1_address, ids.beast_address)
        stop_mock_flee_random = mock_call(ids.xoroshiro_address, 'next', [2])
    %}

    IBeast.flee(beast_address, Uint256(1,0));

    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1,0));

    assert adventurer.Status = AdventurerStatus.Battle;

    %{
        stop_mock_flee_random()
        stop_prank_beast()
    %}

    return ();
}

@external
func test_flee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
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
        stop_mock_adventurer_random = mock_call(ids.xoroshiro_address, 'next', [1])
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}
    // discover and create beast
    IAdventurer.explore(adventurer_address, Uint256(1,0));

    %{ 
        stop_mock_adventurer_random()
        stop_prank_adventurer()
        stop_prank_beast = start_prank(ids.account_1_address, ids.beast_address)
        stop_mock_flee_random = mock_call(ids.xoroshiro_address, 'next', [3])
    %}

    IBeast.flee(beast_address, Uint256(1,0));

    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1,0));

    assert adventurer.Status = AdventurerStatus.Idle;

    %{
        stop_mock_flee_random()
        stop_prank_beast()
    %}

    return ();
}