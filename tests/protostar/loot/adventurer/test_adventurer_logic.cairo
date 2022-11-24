%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from starkware.cairo.common.pow import pow
from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.loot.constants.item import Item, ItemIds, ItemSlot, ItemType, ItemMaterial, Material
from contracts.loot.constants.rankings import ItemRank
from contracts.loot.loot.stats.item import ItemStats
from contracts.loot.constants.physics import MaterialDensity
from contracts.loot.constants.adventurer import (
    Adventurer, 
    AdventurerState, 
    PackedAdventurerState, 
    AdventurerStatus
)
from contracts.loot.adventurer.library import AdventurerLib

from tests.protostar.loot.setup.interfaces import IAdventurer, ILoot, ILords, IRealms
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
        stop_prank_lords = start_prank(ids.addresses.account_1, ids.addresses.lords)
    %}

    ILords.approve(addresses.lords, addresses.adventurer, Uint256(10000, 0));

    %{
        stop_prank_lords()
    %}

    return ();
}

@external
func test_mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_1_address;
    local realms_address;
    local adventurer_address;
    local lords_address;

    %{
        ids.account_1_address = context.account_1
        ids.realms_address = context.realms
        ids.adventurer_address = context.adventurer
        ids.lords_address = context.lords
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}

    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    let (local allowance: Uint256) = ILords.allowance(lords_address, account_1_address, adventurer_address);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8);
    let (new_balance: Uint256) = ILords.balanceOf(lords_address, account_1_address);

    assert new_balance = Uint256(9900, 0);
    %{
        stop_prank_realms()
        stop_prank_adventurer()
    %}

    return ();
}

@external
func test_equip_item{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_1_address;
    local realms_address;
    local adventurer_address;
    local loot_address;

    %{
        ids.account_1_address = context.account_1
        ids.realms_address = context.realms
        ids.adventurer_address = context.adventurer
        ids.loot_address = context.loot
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}
    let (timestamp) = get_block_timestamp();
    let weapon_id: Item = Item(
        ItemIds.Wand,
        ItemSlot.Wand, 
        ItemType.Wand, 
        ItemMaterial.Wand, 
        ItemRank.Wand, 
        1, 
        1, 
        1, 
        0, 
        0, 
        0, 
        0, 
        0
    ); // Wand
    ILoot.mint(loot_address, account_1_address);
    ILoot.setItemById(loot_address, Uint256(1,0), weapon_id);
    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8);
    IAdventurer.equip_item(adventurer_address, Uint256(1,0), Uint256(1,0));
    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1,0));
    let (adventurer_item) = ILoot.getItemByTokenId(loot_address, Uint256(adventurer.WeaponId, 0));
    assert adventurer_item.Id = ItemIds.Wand;

    %{
        stop_prank_realms()
        stop_prank_adventurer()
    %}

    return ();
}

@external
func test_unequip_item{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_1_address;
    local realms_address;
    local adventurer_address;
    local loot_address;

    %{
        ids.account_1_address = context.account_1
        ids.realms_address = context.realms
        ids.adventurer_address = context.adventurer
        ids.loot_address = context.loot
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}
    let (timestamp) = get_block_timestamp();
    let weapon_id: Item = Item(ItemIds.Wand, 0, 0, 0, 0, 0, 0, 0, 0, timestamp, 0, 0, 0); // Wand
    ILoot.mint(loot_address, account_1_address);
    ILoot.setItemById(loot_address, Uint256(1,0), weapon_id);
    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8);
    IAdventurer.equip_item(adventurer_address, Uint256(1,0), Uint256(1,0));
    IAdventurer.unequip_item(adventurer_address, Uint256(1,0), Uint256(1,0));
    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1,0));
    let (adventurer_item) = ILoot.getItemByTokenId(loot_address, Uint256(adventurer.WeaponId, 0));
    assert adventurer_item.Id = 0;

    %{
        stop_prank_realms()
        stop_prank_adventurer()
    %}

    return ();
}

@external
func test_deduct_health{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_1_address;
    local realms_address;
    local adventurer_address;
    local loot_address;

    %{
        ids.account_1_address = context.account_1
        ids.realms_address = context.realms
        ids.adventurer_address = context.adventurer
        ids.loot_address = context.loot
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}

    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8);

    %{
        stop_prank_adventurer()
        stop_prank_adventurer = start_prank(ids.loot_address, ids.adventurer_address)
    %}
    IAdventurer.deduct_health(adventurer_address, Uint256(1,0), 50);
    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1,0));
    assert adventurer.Health = 50;
    %{
        stop_prank_realms()
        stop_prank_adventurer()
    %}

    return ();
}

@external
func test_increase_xp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_1_address;
    local realms_address;
    local adventurer_address;
    local loot_address;

    %{
        ids.account_1_address = context.account_1
        ids.realms_address = context.realms
        ids.adventurer_address = context.adventurer
        ids.loot_address = context.loot
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
        
    %}

    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8);

    %{
        stop_prank_adventurer()
        stop_prank_adventurer = start_prank(ids.loot_address, ids.adventurer_address)
    %}

    let adventurer_token_id = Uint256(1,0);
    IAdventurer.increase_xp(adventurer_address, adventurer_token_id, 10);

    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, adventurer_token_id);

    // Adventuer should now have 10XP and be on Level 2
    assert adventurer.XP = 10;
    assert adventurer.Level = 2;
    %{
        stop_prank_realms()
        stop_prank_adventurer()
    %}
    return ();
}

@external
func test_explore{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_1_address;
    local xoroshiro_address;
    local realms_address;
    local adventurer_address;
    local loot_address;

    %{
        ids.account_1_address = context.account_1
        ids.xoroshiro_address = context.xoroshiro
        ids.realms_address = context.realms
        ids.adventurer_address = context.adventurer
        ids.loot_address = context.loot
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
        stop_mock_adventurer_random = mock_call(ids.xoroshiro_address, 'next', [1])
    %}

    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8);
    IAdventurer.explore(adventurer_address, Uint256(1,0));

    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1,0));

    assert adventurer.Status = AdventurerStatus.Battle;

    %{
        stop_prank_realms()
        stop_prank_adventurer()
        stop_mock_adventurer_random()
    %}

    return ();
}