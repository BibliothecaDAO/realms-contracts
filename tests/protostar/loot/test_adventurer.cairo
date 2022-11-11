%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from starkware.cairo.common.pow import pow

from contracts.loot.constants.item import ItemIds, ItemSlot, ItemType, ItemMaterial, Material
from contracts.loot.constants.rankings import ItemRank
from contracts.loot.loot.stats.item import ItemStats
from contracts.loot.constants.physics import MaterialDensity
from contracts.loot.constants.adventurer import Adventurer, AdventurerStatic, AdventurerDynamic, AdventurerState, PackedAdventurerState
from contracts.loot.adventurer.library import AdventurerLib

from tests.protostar.loot.test_structs import (
    TestAdventurerState,
    get_adventurer_state,
    get_item,
    TEST_WEAPON_TOKEN_ID,
)

@external
func test_birth{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (
        adventurer_static: AdventurerStatic, 
        adventurer_dynamic: AdventurerDynamic
    ) = AdventurerLib.birth(
        TestAdventurerState.Race,
        TestAdventurerState.HomeRealm,
        TestAdventurerState.Name,
        TestAdventurerState.Birthdate,
        TestAdventurerState.Order,
    );

    assert TestAdventurerState.Race = adventurer_static.Race;
    assert TestAdventurerState.HomeRealm = adventurer_static.HomeRealm;
    assert TestAdventurerState.Name = adventurer_static.Name;
    assert TestAdventurerState.Birthdate = adventurer_static.Birthdate;
    assert TestAdventurerState.Order = adventurer_static.Order;

    return ();
}

@external
func test_pack{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (
        adventurer_static: AdventurerStatic, 
        adventurer_dynamic: AdventurerDynamic
    ) = get_adventurer_state();

    let (packed_adventurer: PackedAdventurerState) = AdventurerLib.pack(adventurer_dynamic);

    let (unpacked_adventurer: AdventurerDynamic) = AdventurerLib.unpack(packed_adventurer);

    assert TestAdventurerState.Race = adventurer_static.Race;  // 3
    assert TestAdventurerState.HomeRealm = adventurer_static.HomeRealm;  // 13
    assert TestAdventurerState.Birthdate = adventurer_static.Birthdate;
    assert TestAdventurerState.Name = adventurer_static.Name;
    assert TestAdventurerState.Order = adventurer_static.Order;  //

    // evolving stats
    assert TestAdventurerState.Health = unpacked_adventurer.Health;  //
    assert TestAdventurerState.Level = unpacked_adventurer.Level;  //

    // Physical
    assert TestAdventurerState.Strength = unpacked_adventurer.Strength;
    assert TestAdventurerState.Dexterity = unpacked_adventurer.Dexterity;
    assert TestAdventurerState.Vitality = unpacked_adventurer.Vitality;

    // Mental
    assert TestAdventurerState.Intelligence = unpacked_adventurer.Intelligence;
    assert TestAdventurerState.Wisdom = unpacked_adventurer.Wisdom;
    assert TestAdventurerState.Charisma = unpacked_adventurer.Charisma;

    // Meta Physical
    assert TestAdventurerState.Luck = unpacked_adventurer.Luck;
    assert TestAdventurerState.XP = unpacked_adventurer.XP;  //

    // store item NFT id when equiped
    // Packed Stats p2
    assert TestAdventurerState.NeckId = unpacked_adventurer.NeckId;
    assert TestAdventurerState.WeaponId = unpacked_adventurer.WeaponId;
    assert TestAdventurerState.RingId = unpacked_adventurer.RingId;
    assert TestAdventurerState.ChestId = unpacked_adventurer.ChestId;

    // Packed Stats p3
    assert TestAdventurerState.HeadId = unpacked_adventurer.HeadId;
    assert TestAdventurerState.WaistId = unpacked_adventurer.WaistId;
    assert TestAdventurerState.FeetId = unpacked_adventurer.FeetId;
    assert TestAdventurerState.HandsId = unpacked_adventurer.HandsId;

    return ();
}

@external
func test_cast{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (
        adventurer_static: AdventurerStatic, 
        adventurer_dynamic: AdventurerDynamic
    ) = get_adventurer_state();

    let (packed_adventurer: PackedAdventurerState) = AdventurerLib.pack(adventurer_dynamic);

    let (unpacked_adventurer: AdventurerDynamic) = AdventurerLib.unpack(packed_adventurer);

    let (c) = AdventurerLib.cast_dynamic(0, 3, unpacked_adventurer);

    %{ print('Level', ids.c.Level) %}

    return ();
}

@external
func test_equip{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (
        adventurer_static: AdventurerStatic, 
        adventurer_dynamic: AdventurerDynamic
    ) = get_adventurer_state();

    let (item) = get_item();

    let (packed_adventurer: PackedAdventurerState) = AdventurerLib.pack(adventurer_dynamic);

    let (unpacked_adventurer: AdventurerDynamic) = AdventurerLib.unpack(packed_adventurer);

    let (c) = AdventurerLib.equip_item(TEST_WEAPON_TOKEN_ID, item, unpacked_adventurer);

    assert c.WeaponId = TEST_WEAPON_TOKEN_ID;

    return ();
}
