%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from contracts.loot.beast.stats.beast import BeastStats
from contracts.loot.beast.library import BeastLib
from contracts.loot.constants.beast import (
    Beast,
    BeastStatic,
    BeastDynamic,
    BeastIds, 
    BeastRank, 
    BeastAttackType,
    BeastArmorType,
    BeastSlotIds,
)
from contracts.loot.loot.stats.combat import CombatStats
from tests.protostar.loot.test_structs import (
    create_adventurer,
    get_adventurer_state,
    TestUtils,
    TEST_DAMAGE_HEALTH_REMAINING,
    TEST_DAMAGE_OVERKILL,
)

@external
func test_beast_rank{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (phoenix_rank) = BeastStats.get_rank_from_id(BeastIds.Phoenix);
    assert phoenix_rank = BeastRank.Phoenix;

    let (orc_rank) = BeastStats.get_rank_from_id(BeastIds.Orc);
    assert orc_rank = BeastRank.Orc;

    let (rat_rank) = BeastStats.get_rank_from_id(BeastIds.Rat);
    assert rat_rank = BeastRank.Rat;

    return ();
}

@external
func test_beast_attack_type{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (phoenix_attack_type) = BeastStats.get_attack_type_from_id(BeastIds.Phoenix);
    assert phoenix_attack_type = BeastAttackType.Phoenix;

    let (orc_attack_type) = BeastStats.get_attack_type_from_id(BeastIds.Orc);
    assert orc_attack_type = BeastAttackType.Orc;

    let (rat_attack_type) = BeastStats.get_attack_type_from_id(BeastIds.Rat);
    assert rat_attack_type = BeastAttackType.Rat;

    return ();
}

@external
func test_beast_armor_type{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (phoenix_armor_type) = BeastStats.get_armor_type_from_id(BeastIds.Phoenix);
    assert phoenix_armor_type = BeastArmorType.Phoenix;

    let (orc_armor_type) = BeastStats.get_armor_type_from_id(BeastIds.Orc);
    assert orc_armor_type = BeastArmorType.Orc;

    let (rat_armor_type) = BeastStats.get_armor_type_from_id(BeastIds.Rat);
    assert rat_armor_type = BeastArmorType.Rat;

    return ();
}

@external
func test_pack{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let beast_dynamic = BeastDynamic(
        100,
        0,
        0,
        1,
        1000
    );

    let (packed_beast) = BeastLib.pack(beast_dynamic);

    let (unpacked_beast: BeastDynamic) = BeastLib.unpack(packed_beast);

    assert unpacked_beast.Health = 100;
    assert unpacked_beast.Adventurer = 0;
    assert unpacked_beast.XP = 0;
    assert unpacked_beast.Level = 1;
    assert unpacked_beast.SlainOnDate = 1000;

    return ();
}

@external
func test_cast{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (beast: Beast) = TestUtils.create_beast(1, 0);

    let (_, beast_dynamic: BeastDynamic) = BeastLib.split_data(beast);

    let (c) = BeastLib.cast_state(BeastSlotIds.Health, 50, beast_dynamic);

    assert c.Health = 50;

    return ();
}

@external
func test_deduct_health{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}() {
    alloc_locals;
    
    let (beast) = TestUtils.create_beast(1, 0);

    let (_, beast_dynamic: BeastDynamic) = BeastLib.split_data(beast);

    let (c) = BeastLib.deduct_health(TEST_DAMAGE_HEALTH_REMAINING, beast_dynamic);

    assert c.Health = beast.Health - TEST_DAMAGE_HEALTH_REMAINING;

    let (c) = BeastLib.deduct_health(TEST_DAMAGE_OVERKILL, beast_dynamic);

    assert c.Health = 0;
    
    return ();
}

@external
func test_set_adventurer{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() {
    alloc_locals;
    
    let (beast) = TestUtils.create_beast(1, 0);

    let (_, beast_dynamic: BeastDynamic) = BeastLib.split_data(beast);

    let (c) = BeastLib.set_adventurer(1, beast_dynamic);

    assert c.Adventurer = 1;
    
    return ();
}

@external
func test_slain{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let (beast) = TestUtils.create_beast(1, 0);

    let (_, beast_dynamic: BeastDynamic) = BeastLib.split_data(beast);

    let (c) = BeastLib.slay(1000, beast_dynamic);

    assert c.SlainOnDate = 1000;
    
    return ();
}

@external
func test_calculate_critical_damage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (critical_damage) = CombatStats.calculate_critical_damage(20, 1);

    assert critical_damage = 30;
    return ();
}

@external
func test_calculate_adventurer_level_boost{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (adventurer_level_damage) = CombatStats.calculate_entity_level_boost(20, 1);

    assert adventurer_level_damage = 20;
    return ();
}

// @notice Tests damage to beast calculation
// Damage Calculation is:
// Attack = Greatness * (6 - item_rank) * attack_effectiveness
// Armor = Greatness * (6 - item_rank)
// Damage Given = Attack - Armor (can't be negative)
@external
func test_calculate_damage_to_beast{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (adventurer_state) = get_adventurer_state();

    let (greatness_8_mace) = TestUtils.create_item(75, 8); // Greatness 8 Mace (Bludgeon) vs
    let (xp_1_basilisk) = TestUtils.create_beast(4, 1); // Level 1 Basilisk (Magic)

    // attack = 8 * (6-4) * 1 = 16
    // defense = 1 * (6-4) = 2
    // 16 - 2 = 14HP damage
    let (mace_vs_basilik) = CombatStats.calculate_damage_to_beast(xp_1_basilisk, greatness_8_mace, adventurer_state, 1);

    // adventurer boost = 14 * (1 + ((1-1) * 0.1)) = 14
    // no critical hit
    assert mace_vs_basilik = 14;

    // TODO: Test attacking without weapon (melee)
     // let (weapon) = TestUtils.create_zero_item(); // no weapon (melee attack)

    return ();
    
}

// @notice Tests damage from beast calculation
// Damage Calculation is:
// Attack = Greatness * (6 - item_rank) * attack_effectiveness
// Armor = Greatness * (6 - item_rank)
// Damage Taken = Attack - Armor (can't be negative)
@external
func test_calculate_damage_from_beast{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (beast) = TestUtils.create_beast(1, 2); // 2XP Pheonix vs
    let (armor) = TestUtils.create_item(50, 1); // Greatness 1 Hard Leather Armor
    
    
    // beast_attack = 2 * (6-1) * 1 = 10
    // armor_defense = 1 * (6-4) = 2
    // 10 attack - 2 defense = 8hp damage
    let (local damage) = CombatStats.calculate_damage_from_beast(beast, armor, 1);

    // beast level boost = 8 * ((1-1) + 2 * 0.1) = 9
    // no critical
    assert damage = 8;

    // TODO: Test defending without armor

    return ();
}

// @notice Tests damage from beast calculation in late game
// Damage Calculation is:
// Attack = Greatness * (6 - item_rank) * attack_effectiveness
// Armor = Greatness * (6 - item_rank)
// Damage Taken = Attack - Armor (can't be negative)
@external
func test_calculate_damage_from_beast_late_game{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (beast) = TestUtils.create_beast(11, 20); // levl 20 giant (rank 1)
    let (cloth_armor) = TestUtils.create_item(18, 20); // lvl 20 silk robe (rank 2)
    
    // base weapon damage: 100
    // armor strength: 80
    // attack effectiveness: 1
    // total weapon damage: (100 - 80) * 1 = 20

    let (cloth_damage) = CombatStats.calculate_damage_from_beast(beast, cloth_armor, 1);

    assert cloth_damage = 20;

    let (metal_armor) = TestUtils.create_item(78, 20); // lvl 20 ornate chestplate(rank 2)
    
    let (metal_damage) = CombatStats.calculate_damage_from_beast(beast, metal_armor, 1);

    assert metal_damage = 40;

    let (hide_armor) = TestUtils.create_item(48, 20); // lvl 20 dragonskin armor (rank 2)

    let (hide_damage) = CombatStats.calculate_damage_from_beast(beast, hide_armor, 1);

    assert hide_damage = 60;

    // TODO: Test defending without armor

    let (no_armor) = TestUtils.create_item(0, 0); // no item

    let (no_armor_damage) = CombatStats.calculate_damage_from_beast(beast, no_armor, 1);

    assert no_armor_damage = 300;

    return ();
}

// @notice Tests ambush chance calculation
// Ambush calculation is:
// random_number * (health / 50)
@external
func test_ambush_chance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {

    let (ambush_chance) = BeastLib.calculate_ambush_chance(1, 69);

    assert ambush_chance = 2;

    return ();
}

// @notice Tests ambush chance calculation
// Ambush calculation is:
// (xp_gained - (xp_gained/4)) + ((xp_gained/4) * (rand % 4))
@external
func test_calculate_gold_reward{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (gold_reward) = BeastLib.calculate_gold_reward(0, 5);

    assert gold_reward = 4;

    return ();
}
