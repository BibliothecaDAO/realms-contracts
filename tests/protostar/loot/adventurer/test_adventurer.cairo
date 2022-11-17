%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from starkware.cairo.common.pow import pow

from contracts.loot.constants.item import Item, ItemIds, ItemSlot, ItemType, ItemMaterial, Material
from contracts.loot.constants.rankings import ItemRank
from contracts.loot.loot.stats.item import ItemStats
from contracts.loot.constants.physics import MaterialDensity
from contracts.loot.constants.adventurer import Adventurer, AdventurerState, PackedAdventurerState
from contracts.loot.adventurer.library import AdventurerLib

from tests.protostar.loot.test_structs import (
    TestAdventurerState,
    get_adventurer_state,
    TestUtils,
    TEST_WEAPON_TOKEN_ID,
    TEST_DAMAGE_HEALTH_REMAINING,
    TEST_DAMAGE_OVERKILL,
)

@external
func test_birth{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (adventurer: AdventurerState) = AdventurerLib.birth(
        TestAdventurerState.Race,
        TestAdventurerState.HomeRealm,
        TestAdventurerState.Name,
        TestAdventurerState.Birthdate,
        TestAdventurerState.Order,
    );

    let (adventurer_state: PackedAdventurerState) = AdventurerLib.pack(adventurer);

    let (adventurer: AdventurerState) = AdventurerLib.unpack(adventurer_state);

    assert TestAdventurerState.Race = adventurer.Race;
    assert TestAdventurerState.HomeRealm = adventurer.HomeRealm;
    assert TestAdventurerState.Name = adventurer.Name;
    assert TestAdventurerState.Birthdate = adventurer.Birthdate;
    assert TestAdventurerState.Order = adventurer.Order;

    return ();
}

@external
func test_pack{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (state) = get_adventurer_state();

    let (adventurer_state: PackedAdventurerState) = AdventurerLib.pack(state);

    let (adventurer: AdventurerState) = AdventurerLib.unpack(adventurer_state);

    assert TestAdventurerState.Race = adventurer.Race;  // 3
    assert TestAdventurerState.HomeRealm = adventurer.HomeRealm;  // 13
    assert TestAdventurerState.Birthdate = adventurer.Birthdate;
    assert TestAdventurerState.Name = adventurer.Name;

    // evolving stats
    assert TestAdventurerState.Health = adventurer.Health;  //

    assert TestAdventurerState.Level = adventurer.Level;  //
    assert TestAdventurerState.Order = adventurer.Order;  //

    // Physical
    assert TestAdventurerState.Strength = adventurer.Strength;
    assert TestAdventurerState.Dexterity = adventurer.Dexterity;
    assert TestAdventurerState.Vitality = adventurer.Vitality;

    // Mental
    assert TestAdventurerState.Intelligence = adventurer.Intelligence;
    assert TestAdventurerState.Wisdom = adventurer.Wisdom;
    assert TestAdventurerState.Charisma = adventurer.Charisma;

    // Meta Physical
    assert TestAdventurerState.Luck = adventurer.Luck;

    assert TestAdventurerState.XP = adventurer.XP;  //

    // store item NFT id when equiped
    // Packed Stats p2
    assert TestAdventurerState.NeckId = adventurer.NeckId;
    assert TestAdventurerState.WeaponId = adventurer.WeaponId;
    assert TestAdventurerState.RingId = adventurer.RingId;
    assert TestAdventurerState.ChestId = adventurer.ChestId;

    // Packed Stats p3
    assert TestAdventurerState.HeadId = adventurer.HeadId;
    assert TestAdventurerState.WaistId = adventurer.WaistId;
    assert TestAdventurerState.FeetId = adventurer.FeetId;
    assert TestAdventurerState.HandsId = adventurer.HandsId;

    return ();
}

@external
func test_cast{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (state) = get_adventurer_state();

    let (adventurer_state: PackedAdventurerState) = AdventurerLib.pack(state);

    let (adventurer: AdventurerState) = AdventurerLib.unpack(adventurer_state);

    let (c) = AdventurerLib.cast_state(0, 3, adventurer);

    %{ print('Race', ids.c.Race) %}

    return ();
}

@external
func test_equip{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (state) = get_adventurer_state();

    let (item) = TestUtils.create_item(ItemIds.Katana, 20);

    let (adventurer_state: PackedAdventurerState) = AdventurerLib.pack(state);

    let (adventurer: AdventurerState) = AdventurerLib.unpack(adventurer_state);

    let (c) = AdventurerLib.equip_item(TEST_WEAPON_TOKEN_ID, item, adventurer);

    assert c.WeaponId = TEST_WEAPON_TOKEN_ID;

    return ();
}

@external
func test_unequip{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (state) = get_adventurer_state();

    let (item) = TestUtils.create_item(ItemIds.Katana, 20);

    let (adventurer_state: PackedAdventurerState) = AdventurerLib.pack(state);

    let (adventurer: AdventurerState) = AdventurerLib.unpack(adventurer_state);

    let (c) = AdventurerLib.equip_item(TEST_WEAPON_TOKEN_ID, item, adventurer);

    assert c.WeaponId = TEST_WEAPON_TOKEN_ID;

    let (new_c) = AdventurerLib.unequip_item(item, c);

    assert new_c.WeaponId = 0;
    
    return ();
}

@external
func test_deductHealth{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (state) = get_adventurer_state();

    let (adventurer_state: PackedAdventurerState) = AdventurerLib.pack(state);

    let (adventurer: AdventurerState) = AdventurerLib.unpack(adventurer_state);

    let (c) = AdventurerLib.deduct_health(TEST_DAMAGE_HEALTH_REMAINING, adventurer);

    assert c.Health = TestAdventurerState.Health - TEST_DAMAGE_HEALTH_REMAINING;

    let (c) = AdventurerLib.deduct_health(TEST_DAMAGE_OVERKILL, adventurer);

    assert c.Health = 0;

    return ();
}