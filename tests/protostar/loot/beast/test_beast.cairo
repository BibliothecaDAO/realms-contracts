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
)
from contracts.loot.loot.stats.combat import CombatStats
from tests.protostar.loot.test_structs import (
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
    assert unpacked_beast.SlainBy = 1;
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

    let (c) = BeastLib.cast_state(1, 50, beast_dynamic);

    %{ print('Health:', ids.c.Health) %}

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

    let (c) = BeastLib.slay(1, 1000, beast_dynamic);

    assert c.SlainBy = 1;
    assert c.SlainOnDate = 1000;
    
    return ();
}

@external
func test_calculate_damage_to_beast{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (beast) = TestUtils.create_beast(4, 0);

    let (local weapon) = TestUtils.create_item(75, 1); // Mace

    // let (weapon) = TestUtils.create_zero_item(); // no weapon (melee attack)

    %{
        print('Weapon Type:', ids.weapon.Type) # bludgeon
        print('Weapon Rank:', ids.weapon.Rank) # 4
        print('Weapon Greatness:', ids.weapon.Greatness) # 1
        print('Beast Attack Type:', ids.beast.AttackType) # magic
        print('Beast Armor Type:', ids.beast.ArmorType) # cloth
        print('Beast Rank:', ids.beast.Rank) # 1
        print('Beast XP:', ids.beast.XP) # 0
    %}

    let (local damage) = CombatStats.calculate_damage_to_beast(beast, weapon);

    // assert damage = 2;

    %{
        print('Damage To Beast:', ids.damage)
    %}

    return ();
    
}

@external
func test_calculate_damage_from_beast{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (beast) = TestUtils.create_beast(1, 2); // Creates a Pheonix

    let (armor) = TestUtils.create_item(50, 1); // Hard Leather Armor

    // let (armor) = TestUtils.create_zero_item();

    %{
        print('Armor Type:', ids.armor.Type) # hide
        print('Armor Rank:', ids.armor.Rank) # 4
        print('Armor Greatness:', ids.armor.Greatness) # 1
        print('Beast Attack Type:', ids.beast.AttackType) # magic
        print('Beast Armor Type:', ids.beast.ArmorType) # cloth
        print('Beast Rank:', ids.beast.Rank) # 1
        print('Beast XP:', ids.beast.XP) # 0
    %}

    let (local damage) = CombatStats.calculate_damage_from_beast(beast, armor);
    // base_weapon_damage = 5 * 2 = 10
    // magic v hide = low = 1
    // armor_strength = 6-4 * 1 = 2

    // assert damage = 8;

    %{
        print('Damage From Beast:', ids.damage)
    %}

    return ();
    
}