%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from contracts.settling_game.modules.combat.library import Combat, Army, Battalion, ArmyStatistics
from contracts.settling_game.modules.combat.constants import BattalionStatistics, BattalionIds

func build_attacking_army() -> (a: Army) {
    tempvar values = new (2, 100, 2, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,);

    // tempvar values = new (1, 100, 1, 100, 1, 100, 1, 100, 1, 100, 1, 100, 1, 100, 1, 100,);
    let a = cast(values, Army*);
    return ([a],);
}

func build_defending_army() -> (a: Army) {
    // tempvar values = new (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 100, 3, 100,);
    // tempvar values = new (1, 100, 1, 100, 1, 100, 1, 100, 1, 100, 1, 100, 1, 100, 1, 100,);

    tempvar values = new (10, 100, 10, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,);
    let a = cast(values, Army*);
    return ([a],);
}

// @external
// func test_flatten_values{
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
// }() {
//     alloc_locals;
//     tempvar troop_ids = new (1, 2);
//     tempvar troop_qtys = new (3, 3);

// let (new_ids: felt*) = alloc();
//     Combat.flatten_ids(2, troop_ids, 2, troop_qtys, new_ids);

// let id_1 = new_ids[0];
//     let id_2 = new_ids[1];
//     let id_3 = new_ids[2];

// assert id_1 = 1;
//     assert id_2 = 1;
//     assert id_3 = 1;

// let len = Combat.id_length(2, troop_qtys, 0);

// assert len = 6;

// return ();
// }

// @external
// func test_squad{
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
// }() {
//     alloc_locals;

// let (attacking_army) = build_attacking_army();
//     let (packed_army) = Combat.pack_army(attacking_army);
//     let (unpacked_army: Army) = Combat.unpack_army(packed_army);

// assert unpacked_army.light_cavalry.quantity = 1;
//     assert unpacked_army.light_cavalry.health = 100;
//     assert unpacked_army.heavy_cavalry.quantity = 1;
//     assert unpacked_army.heavy_cavalry.health = 100;

// return ();
// }

// @external
// func test_statistics{
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
// }() {
//     alloc_locals;

// let (attacking_army) = build_attacking_army();
//     let (defending_army) = build_defending_army();
//     let (unpacked_army: ArmyStatistics) = Combat.calculate_army_statistics(
//         attacking_army, defending_army
//     );

// let (cavalry_attack) = Combat.calculate_attack_values(
//         BattalionIds.LightCavalry,
//         attacking_army.light_cavalry.quantity,
//         BattalionIds.HeavyCavalry,
//         attacking_army.heavy_cavalry.quantity,
//     );
//     let (archery_attack) = Combat.calculate_attack_values(
//         BattalionIds.Archer,
//         attacking_army.archer.quantity,
//         BattalionIds.Longbow,
//         attacking_army.longbow.quantity,
//     );
//     let (magic_attack) = Combat.calculate_attack_values(
//         BattalionIds.Mage,
//         attacking_army.mage.quantity,
//         BattalionIds.Arcanist,
//         attacking_army.arcanist.quantity,
//     );
//     let (infantry_attack) = Combat.calculate_attack_values(
//         BattalionIds.LightInfantry,
//         attacking_army.light_infantry.quantity,
//         BattalionIds.HeavyInfantry,
//         attacking_army.heavy_infantry.quantity,
//     );

// assert unpacked_army.cavalry_attack = cavalry_attack;
//     assert unpacked_army.archery_attack = archery_attack;
//     assert unpacked_army.magic_attack = magic_attack;
//     assert unpacked_army.infantry_attack = infantry_attack;

// return ();
// }

// @external
// func test_all_defence_value{
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
// }() {
//     alloc_locals;

// let (attacking_army) = build_attacking_army();
//     let (defending_army) = build_defending_army();

// let (total_battalions) = Combat.calculate_total_battalions(defending_army);

// let (
//         a_cavalry_defence, a_archer_defence, a_magic_defence, a_infantry_defence
//     ) = Combat.all_defence_value(attacking_army, defending_army);

// let c_defence = attacking_army.light_cavalry.quantity * BattalionStatistics.Defence.Cavalry.LightCavalry + attacking_army.heavy_cavalry.quantity * BattalionStatistics.Defence.Cavalry.HeavyCavalry + attacking_army.archer.quantity * BattalionStatistics.Defence.Cavalry.Archer + attacking_army.longbow.quantity * BattalionStatistics.Defence.Cavalry.Longbow + attacking_army.mage.quantity * BattalionStatistics.Defence.Cavalry.Mage + attacking_army.arcanist.quantity * BattalionStatistics.Defence.Cavalry.Arcanist + attacking_army.light_infantry.quantity * BattalionStatistics.Defence.Cavalry.LightInfantry + attacking_army.heavy_infantry.quantity * BattalionStatistics.Defence.Cavalry.HeavyInfantry;

// let (cavalry_defence) = Combat.calculate_defence_values(
//         c_defence,
//         total_battalions,
//         defending_army.light_cavalry.quantity + defending_army.heavy_cavalry.quantity,
//     );

// assert cavalry_defence = a_cavalry_defence;

// return ();
// }

@external
func test_winner{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (attacking_army) = build_attacking_army();
    let (defending_army) = build_defending_army();

    let luck = 100;

    let (outcome, updated_attacker: Army, updated_defender: Army) = Combat.calculate_winner(
        luck, attacking_army, defending_army
    );

    // assert outcome = 1;

    let attacking_army = updated_attacker;
    let defending_army = updated_defender;

    %{ print('light_cavalry Health:', ids.attacking_army.light_cavalry.health, ids.defending_army.light_cavalry.health) %}
    %{ print('heavy_cavalry Health:', ids.attacking_army.heavy_cavalry.health, ids.defending_army.heavy_cavalry.health) %}
    %{ print('archer Health:', ids.attacking_army.archer.health, ids.defending_army.archer.health) %}
    %{ print('longbow Health:', ids.attacking_army.longbow.health, ids.defending_army.longbow.health) %}
    %{ print('mage Health:', ids.attacking_army.mage.health, ids.defending_army.mage.health) %}
    %{ print('arcanist Health:', ids.attacking_army.arcanist.health, ids.defending_army.arcanist.health) %}
    %{ print('light_infantry Health:', ids.attacking_army.light_infantry.health, ids.defending_army.light_infantry.health) %}
    %{ print('heavy_infantry Health:', ids.attacking_army.heavy_infantry.health, ids.defending_army.heavy_infantry.health) %}

    %{ print('light_cavalry quantity:', ids.attacking_army.light_cavalry.quantity, ids.defending_army.light_cavalry.quantity) %}
    %{ print('heavy_cavalry quantity:', ids.attacking_army.heavy_cavalry.quantity, ids.defending_army.heavy_cavalry.quantity) %}
    %{ print('archer quantity:', ids.attacking_army.archer.quantity, ids.defending_army.archer.quantity) %}
    %{ print('longbow quantity:', ids.attacking_army.longbow.quantity, ids.defending_army.longbow.quantity) %}
    %{ print('mage quantity:', ids.attacking_army.mage.quantity, ids.defending_army.mage.quantity) %}
    %{ print('arcanist quantity:', ids.attacking_army.arcanist.quantity, ids.defending_army.arcanist.quantity) %}
    %{ print('light_infantry quantity:', ids.attacking_army.light_infantry.quantity, ids.defending_army.light_infantry.quantity) %}
    %{ print('heavy_infantry quantity:', ids.attacking_army.heavy_infantry.quantity, ids.defending_army.heavy_infantry.quantity) %}
    return ();
}

@external
func test_calculate_health_loss_percentage{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (a_outcome) = Combat.calculate_health_loss_percentage(0, 1);

    // assert outcome = 694;
    %{ print('attacking', ids.a_outcome) %}

    let (d_outcome) = Combat.calculate_health_loss_percentage(0, 0);

    %{ print('defending', ids.d_outcome) %}

    return ();
}

// @external
// func test_calculate_total_battalions{
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
// }() {
//     alloc_locals;

// let (attacking_army) = build_attacking_army();
//     let (packed_army) = Combat.pack_army(attacking_army);
//     let (unpacked_army) = Combat.unpack_army(packed_army);

// let (total_battalions) = Combat.calculate_total_battalions(attacking_army);

// assert total_battalions = 29;

// return ();
// }

// @external
// func test_health_remaining{
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
// }() {
//     alloc_locals;

// let (attacking_army) = build_attacking_army();
//     let (defending_army) = build_defending_army();

// let (hp_loss) = Combat.calculate_health_loss_percentage(-134);

// let (attack_army_statistics: ArmyStatistics) = Combat.calculate_army_statistics(
//         attacking_army, defending_army
//     );

// let (defending_army_statistics: ArmyStatistics) = Combat.calculate_army_statistics(
//         defending_army, attacking_army
//     );

// let (light_cavalry_health, light_cavalry_battalions) = Combat.calculate_health_remaining(
//         attacking_army.light_cavalry.health * attacking_army.light_cavalry.quantity,
//         attack_army_statistics.infantry_attack,
//         defending_army_statistics.infantry_defence,
//         hp_loss,
//     );

// let luck = 100;
//     let (outcome, updated_attacker: Army, updated_defender: Army) = Combat.calculate_winner(
//         luck, attacking_army, defending_army
//     );

// assert updated_attacker.light_cavalry.health = light_cavalry_health;
//     assert updated_attacker.light_cavalry.quantity = light_cavalry_battalions;

// return ();
// }

// @external
// func test_add_battalions_to_army{
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
// }() {
//     alloc_locals;

// let (attacking_army) = build_attacking_army();
//     let (packed_army) = Combat.pack_army(attacking_army);
//     let (unpacked_army) = Combat.unpack_army(packed_army);

// let (battalion_ids: felt*) = alloc();
//     assert battalion_ids[0] = BattalionIds.LightCavalry;
//     assert battalion_ids[1] = BattalionIds.HeavyCavalry;

// let (battalions: felt*) = alloc();
//     assert battalions[0] = 3;
//     assert battalions[1] = 3;

// let (total_battalions: Army) = Combat.add_battalions_to_army(
//         unpacked_army, 2, battalion_ids, 2, battalions
//     );

// assert total_battalions.light_cavalry.quantity = battalions[0];

// return ();
// }
