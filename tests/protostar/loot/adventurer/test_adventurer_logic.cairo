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
    AdventurerSlotIds,
    AdventurerState,
    PackedAdventurerState,
    AdventurerStatus,
    DiscoveryType,
)
from contracts.loot.adventurer.library import AdventurerLib

from tests.protostar.loot.setup.interfaces import IAdventurer, IBeast, ILoot, ILords, IRealms
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
    alloc_locals;

    let addresses: Contracts = deploy_all();

    %{
        context.account_1 = ids.addresses.account_1
        context.xoroshiro = ids.addresses.xoroshiro
        context.realms = ids.addresses.realms
        context.adventurer = ids.addresses.adventurer
        context.beast = ids.addresses.beast
        context.loot = ids.addresses.loot
        context.lords = ids.addresses.lords
        stop_prank_lords = start_prank(ids.addresses.account_1, ids.addresses.lords)
    %}

    ILords.approve(addresses.lords, addresses.adventurer, Uint256(100000000000000000000, 0));

    %{ stop_prank_lords() %}

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
    let (local allowance: Uint256) = ILords.allowance(
        lords_address, account_1_address, adventurer_address
    );
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);
    let (new_balance: Uint256) = ILords.balanceOf(lords_address, account_1_address);

    assert new_balance = Uint256(100000000000000000000, 0);

    return ();
}

@external
func test_mint_with_starting_weapon{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    local account_1_address;
    local realms_address;
    local adventurer_address;
    local lords_address;
    local loot_address;

    %{
        ids.account_1_address = context.account_1
        ids.realms_address = context.realms
        ids.adventurer_address = context.adventurer
        ids.lords_address = context.lords
        ids.loot_address = context.loot
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}

    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);

    // Mint an adventurer with a book as a starting weapon
    IAdventurer.mint_with_starting_weapon(
        adventurer_address, account_1_address, 4, 13, 'Test', 8, 1, 1, ItemIds.Book
    );

    %{ stop_prank_lords = start_prank(ids.account_1_address, ids.lords_address) %}

    ILords.approve(lords_address, adventurer_address, Uint256(100000000000000000000, 0));

    %{ stop_prank_lords() %}

    // Mint an adventurer with a book as a starting weapon
    IAdventurer.mint_with_starting_weapon(
        adventurer_address, account_1_address, 4, 13, 'Test', 8, 1, 1, ItemIds.Book
    );

    let (new_balance: Uint256) = ILords.balanceOf(lords_address, account_1_address);

    // assert new_balance = Uint256(0, 0);

    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1, 0));
    let (adventurer_item) = ILoot.get_item_by_token_id(
        loot_address, Uint256(adventurer.WeaponId, 0)
    );
    assert adventurer_item.Id = ItemIds.Book;

    let (next_adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(2, 0));
    let (next_adventurer_item) = ILoot.get_item_by_token_id(
        loot_address, Uint256(next_adventurer.WeaponId, 0)
    );
    assert next_adventurer_item.Id = ItemIds.Book;

    return ();
}

@external
func test_mint_non_starting_weapon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    alloc_locals;

    local account_1_address;
    local realms_address;
    local adventurer_address;
    local lords_address;
    local loot_address;

    %{
        ids.account_1_address = context.account_1
        ids.realms_address = context.realms
        ids.adventurer_address = context.adventurer
        ids.lords_address = context.lords
        ids.loot_address = context.loot
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}

    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);

    %{ expect_revert(error_message="Loot: Item is not a starter weapon") %}

    // Test minting adventurer with a non starting weapon
    IAdventurer.mint_with_starting_weapon(
        adventurer_address, account_1_address, 4, 13, 'Test', 8, 1, 1, ItemIds.Katana
    );

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
        stop_prank_loot = start_prank(ids.adventurer_address, ids.loot_address)
    %}
    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);
    ILoot.mint(loot_address, account_1_address, Uint256(1, 0));
    %{
        stop_prank_loot()
        stop_prank_loot = start_prank(ids.account_1_address, ids.loot_address)
    %}
    // make sure adventurer and bag are set to 0
    ILoot.set_item_by_id(loot_address, Uint256(1, 0), ItemIds.Wand, 0, 0, 0, 0);
    %{
        stop_prank_loot()
        stop_prank_loot = start_prank(ids.adventurer_address, ids.loot_address)
    %}
    IAdventurer.equip_item(adventurer_address, Uint256(1, 0), Uint256(1, 0));
    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1, 0));
    let (adventurer_item) = ILoot.get_item_by_token_id(
        loot_address, Uint256(adventurer.WeaponId, 0)
    );
    assert adventurer_item.Id = ItemIds.Wand;

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
        stop_prank_loot = start_prank(ids.adventurer_address, ids.loot_address)
    %}
    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);
    ILoot.mint(loot_address, account_1_address, Uint256(1, 0));
    // make sure adventurer and bag are set to 0
    %{
        stop_prank_loot()
        stop_prank_loot = start_prank(ids.account_1_address, ids.loot_address)
    %}
    ILoot.set_item_by_id(loot_address, Uint256(1, 0), ItemIds.Wand, 0, 0, 0, 0);
    %{
        stop_prank_loot()
        stop_prank_loot = start_prank(ids.adventurer_address, ids.loot_address)
    %}
    IAdventurer.equip_item(adventurer_address, Uint256(1, 0), Uint256(1, 0));
    IAdventurer.unequip_item(adventurer_address, Uint256(1, 0), Uint256(1, 0));
    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1, 0));
    let (adventurer_item) = ILoot.get_item_by_token_id(
        loot_address, Uint256(adventurer.WeaponId, 0)
    );
    assert adventurer_item.Id = 0;

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
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);

    %{
        stop_prank_adventurer()
        stop_prank_adventurer = start_prank(ids.loot_address, ids.adventurer_address)
    %}
    IAdventurer.deduct_health(adventurer_address, Uint256(1, 0), 50);
    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1, 0));
    assert adventurer.Health = 50;

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
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);

    %{
        stop_prank_adventurer()
        stop_prank_adventurer = start_prank(ids.loot_address, ids.adventurer_address)
    %}

    let adventurer_token_id = Uint256(1, 0);
    IAdventurer.increase_xp(adventurer_address, adventurer_token_id, 10);

    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, adventurer_token_id);

    // Adventuer should now have 10XP and be on Level 2
    assert adventurer.XP = 10;
    assert adventurer.Level = 2;

    return ();
}

@external
func test_purchase_health{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_1_address;
    local xoroshiro_address;
    local realms_address;
    local adventurer_address;
    local beast_address;
    local loot_address;

    %{
        ids.account_1_address = context.account_1
        ids.realms_address = context.realms
        ids.adventurer_address = context.adventurer
        ids.beast_address = context.beast
        ids.loot_address = context.loot
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}

    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);

    %{
        stop_prank_beast = start_prank(ids.adventurer_address, ids.beast_address)
        stop_prank_adventurer()
        stop_prank_adventurer = start_prank(ids.beast_address, ids.adventurer_address)
    %}

    // store balance of 5 gold
    IBeast.add_to_balance(beast_address, Uint256(1, 0), 100);

    %{
        stop_prank_beast()
        stop_prank_adventurer()
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}

    IAdventurer.purchase_health(adventurer_address, Uint256(1, 0), 1);

    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1, 0));

    assert adventurer.Health = 100;

    %{
        stop_prank_adventurer()
        stop_prank_adventurer = start_prank(ids.beast_address, ids.adventurer_address)
    %}

    IAdventurer.deduct_health(adventurer_address, Uint256(1, 0), 90);

    %{
        stop_prank_adventurer()
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}

    IAdventurer.purchase_health(adventurer_address, Uint256(1, 0), 5);

    let (new_adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1, 0));

    assert new_adventurer.Health = 60;

    return ();
}

@external
func test_upgrade_stat{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_1_address;
    local xoroshiro_address;
    local realms_address;
    local adventurer_address;
    local beast_address;
    local loot_address;

    %{
        ids.account_1_address = context.account_1
        ids.realms_address = context.realms
        ids.adventurer_address = context.adventurer
        ids.beast_address = context.beast
        ids.loot_address = context.loot
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}

    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);

    %{
        stop_prank_adventurer()
        stop_prank_adventurer = start_prank(ids.beast_address, ids.adventurer_address)
    %}

    // enough xp to level up
    IAdventurer.increase_xp(adventurer_address, Uint256(1, 0), 9);

    %{
        stop_prank_adventurer()
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}

    // upgrade strength
    IAdventurer.upgrade_stat(adventurer_address, Uint256(1, 0), AdventurerSlotIds.Strength);

    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1, 0));

    assert adventurer.Strength = 1;

    %{ expect_revert(error_message="Adventurer: Adventurer must be upgradable") %}

    // try upgrade strength again
    IAdventurer.upgrade_stat(adventurer_address, Uint256(1, 0), AdventurerSlotIds.Strength);

    return ();
}

// @external
// func test_discover_loot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     alloc_locals;

// local account_1_address;
//     local xoroshiro_address;
//     local adventurer_address;
//     local beast_address;

// %{
//         ids.account_1_address = context.account_1
//         ids.xoroshiro_address = context.xoroshiro
//         ids.adventurer_address = context.adventurer
//         ids.beast_address = context.beast
//         # 1%4 = 1, therefore DiscoveryType beast
//         stop_mock = mock_call(ids.xoroshiro_address, 'next', [2])
//         # now we are timsing by timestamp we also need this
//         stop_roll_adventurer = roll(1, ids.adventurer_address)
//         stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
//         stop_prank_beast = start_prank(ids.adventurer_address, ids.beast_address)
//     %}

// IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);

// %{
//         from tests.protostar.loot.utils import utils
//         # need to store adventurer level to greater than 1 to avoid starter beast
//         p1, p2, p3, p4 = utils.pack_adventurer(utils.build_adventurer_level(2))
//         store(ids.adventurer_address, "adventurer_dynamic", [p1, p2, p3, p4], key=[1,0])
//     %}

// let (discovery_type, r) = IAdventurer.explore(adventurer_address, Uint256(1,0));

// assert discovery_type = DiscoveryType.Item;
//     assert r = 0;

// return ();
// }

@external
func test_discover_health{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
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
        # 1%4 = 1, therefore DiscoveryType beast
        stop_mock = mock_call(ids.xoroshiro_address, 'next', [3])
        # now we are timsing by timestamp we also need this 
        stop_roll_adventurer = roll(1, ids.adventurer_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
        stop_prank_beast = start_prank(ids.adventurer_address, ids.beast_address)
    %}

    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);

    %{
        from tests.protostar.loot.utils import utils
        # need to store adventurer level to greater than 1 to avoid starter beast
        p1, p2, p3, p4 = utils.pack_adventurer(utils.build_adventurer_level(2))
        store(ids.adventurer_address, "adventurer_dynamic", [p1, p2, p3, p4], key=[1,0])
    %}

    %{
        stop_prank_adventurer()
        stop_prank_adventurer = start_prank(ids.beast_address, ids.adventurer_address)
    %}

    // deduct health to measure health increase
    IAdventurer.deduct_health(adventurer_address, Uint256(1, 0), 50);

    %{
        stop_prank_adventurer()
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}

    let (discovery_type, r) = IAdventurer.explore(adventurer_address, Uint256(1, 0));

    assert discovery_type = DiscoveryType.Item;
    assert r = 0;

    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1, 0));

    // 50 + (10 + (5 * 3))
    assert adventurer.Health = 75;

    return ();
}

@external
func test_discover_obstacle{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
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
        # 1%4 = 1, therefore DiscoveryType beast
        stop_mock = mock_call(ids.xoroshiro_address, 'next', [2])
        # now we are timsing by timestamp we also need this 
        stop_roll_adventurer = roll(1, ids.adventurer_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
        stop_prank_beast = start_prank(ids.adventurer_address, ids.beast_address)
    %}
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);

    %{
        from tests.protostar.loot.utils import utils
        # need to store adventurer level to greater than 1 to avoid starter beast
        p1, p2, p3, p4 = utils.pack_adventurer(utils.build_adventurer_level(2))
        store(ids.adventurer_address, "adventurer_dynamic", [p1, p2, p3, p4], key=[1,0])
    %}
    let (discovery_type, obstacle_id) = IAdventurer.explore(adventurer_address, Uint256(1, 0));

    assert discovery_type = DiscoveryType.Obstacle;
    assert obstacle_id = 3;

    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1, 0));

    // Obstacle level will be same as adventurer level (until level 3)
    // So for this test since adventurer is level 2, obstacle will be level 2
    // Obstacle ID is 3 which is a Hex which is a tier 3
    // Since  adventurer isn't wearing any armor, elemental_multiplier will always be HIGH which is 3

    // (6 - OBSTACLE_TIER) * OBSTACLE_LEVEL * ELEMENTAL_MULTIPLIER
    // (6 - 3) * 2 * 3 = 18HP of damage dealt to adventurer
    // 100HP - 18HP = 82
    assert adventurer.Health = 82;

    return ();
}
