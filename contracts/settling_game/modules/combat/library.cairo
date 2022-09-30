// -----------------------------------
//   COMBAT Library
//   Library to help with the combat mechanics.
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_lt
from starkware.cairo.common.math_cmp import is_nn_le, is_nn, is_le
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset
from contracts.settling_game.utils.general import unpack_data
from contracts.settling_game.modules.combat.constants import (
    BattalionStatistics,
    SHIFT_ARMY,
    BattalionIds,
)
from contracts.settling_game.utils.game_structs import (
    RealmBuildings,
    Battalion,
    Army,
    ArmyStatistics,
)

namespace Combat {
    // @notice Add Battalion to Army
    // @param current: current unpacked Army
    // @param battalion_ids_len: BattalionIds length
    // @param battalion_ids: Battalion IDS - BattalionIds
    // @param battalions_len: Battalions len
    // @param battalions: Battalion to Pack
    // @returns Army updated with new Battalions
    func add_battalions_to_army{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        current: Army,
        battalion_ids_len: felt,
        battalion_ids: felt*,
        battalions_len: felt,
        battalion_quantity: felt*,
    ) -> (army: Army) {
        alloc_locals;

        if (battalions_len == 0) {
            return (current,);
        }

        let (updated) = add_battalion_to_battalion(
            current, [battalion_ids], Battalion([battalion_quantity], 100)
        );

        return add_battalions_to_army(
            updated,
            battalion_ids_len - 1,
            battalion_ids + 1,
            battalions_len - 1,
            battalion_quantity + 1,
        );
    }

    // @notice Add Battalion to Battalion
    // @param current: current unpacked Army
    // @param battalion_id: BattalionId to add
    // @param battalion: Battalion to add
    // @returns Army with added Battalion
    func add_battalion_to_battalion{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(current: Army, battalion_id: felt, battalion: Battalion) -> (army: Army) {
        alloc_locals;

        let (__fp__, _) = get_fp_and_pc();
        // let old = cast(&current, felt*)
        let (updated: felt*) = alloc();

        let battalion_idx = (battalion_id - 1) * Battalion.SIZE;
        let old_battalion = [&current + battalion_idx];  // [&old + battalion_idx]

        memcpy(updated, &current, battalion_idx);
        memcpy(updated + battalion_idx, &battalion, Battalion.SIZE);
        memcpy(
            updated + battalion_idx + Battalion.SIZE,
            &current + battalion_idx + Battalion.SIZE,
            Army.SIZE - battalion_idx - Battalion.SIZE,
        );

        let army = cast(updated, Army*);
        return ([army],);
    }

    // @notice Unpacks bitmapped Army
    // @param army_packed: current packed Army
    // @returns unpacked Army
    func unpack_army{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(army_packed: felt) -> (army: Army) {
        alloc_locals;

        let (light_cavalry_quantity) = unpack_data(army_packed, 0, 31);  // 5
        let (heavy_cavalry_quantity) = unpack_data(army_packed, 5, 31);  // 5
        let (archer_quantity) = unpack_data(army_packed, 10, 31);  // 5
        let (longbow_quantity) = unpack_data(army_packed, 15, 31);  // 5
        let (mage_quantity) = unpack_data(army_packed, 20, 31);  // 5
        let (archanist_quantity) = unpack_data(army_packed, 25, 31);  // 5
        let (light_infantry_quantity) = unpack_data(army_packed, 30, 31);  // 5
        let (heavy_infantry_quantity) = unpack_data(army_packed, 35, 31);  // 5

        let (light_cavalry_health) = unpack_data(army_packed, 42, 127);  // 7
        let (heavy_cavalry_health) = unpack_data(army_packed, 49, 127);  // 7
        let (archer_health) = unpack_data(army_packed, 56, 127);  // 7
        let (longbow_health) = unpack_data(army_packed, 63, 127);  // 7
        let (mage_health) = unpack_data(army_packed, 70, 127);  // 7
        let (arcanist_health) = unpack_data(army_packed, 77, 127);  // 7
        let (light_infantry_health) = unpack_data(army_packed, 84, 127);  // 7
        let (heavy_infantry_health) = unpack_data(army_packed, 91, 127);  // 7

        return (
            Army(Battalion(light_cavalry_quantity, light_cavalry_health), Battalion(heavy_cavalry_quantity, heavy_cavalry_health), Battalion(archer_quantity, archer_health), Battalion(longbow_quantity, longbow_health), Battalion(mage_quantity, mage_health), Battalion(archanist_quantity, arcanist_health), Battalion(light_infantry_quantity, light_infantry_health), Battalion(heavy_infantry_quantity, heavy_infantry_health)),
        );
    }

    // @notice Packs Army into single felt
    // @param army_unpacked: current unpacked Army
    // @returns packed Army in the form of a felt
    func pack_army{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(army_unpacked: Army) -> (packed_army: felt) {
        alloc_locals;

        let light_cavalry_quantity = army_unpacked.light_cavalry.quantity * SHIFT_ARMY._1;
        let heavy_cavalry_quantity = army_unpacked.heavy_cavalry.quantity * SHIFT_ARMY._2;
        let archer_quantity = army_unpacked.archer.quantity * SHIFT_ARMY._3;
        let longbow_quantity = army_unpacked.longbow.quantity * SHIFT_ARMY._4;
        let mage_quantity = army_unpacked.mage.quantity * SHIFT_ARMY._5;
        let archanist_quantity = army_unpacked.arcanist.quantity * SHIFT_ARMY._6;
        let light_infantry_quantity = army_unpacked.light_infantry.quantity * SHIFT_ARMY._7;
        let heavy_infantry_quantity = army_unpacked.heavy_infantry.quantity * SHIFT_ARMY._8;

        let light_cavalry_health = army_unpacked.light_cavalry.health * SHIFT_ARMY._9;
        let heavy_cavalry_health = army_unpacked.heavy_cavalry.health * SHIFT_ARMY._10;
        let archer_health = army_unpacked.archer.health * SHIFT_ARMY._11;
        let longbow_health = army_unpacked.longbow.health * SHIFT_ARMY._12;
        let mage_health = army_unpacked.mage.health * SHIFT_ARMY._13;
        let arcanist_health = army_unpacked.arcanist.health * SHIFT_ARMY._14;
        let light_infantry_health = army_unpacked.light_infantry.health * SHIFT_ARMY._15;
        let heavy_infantry_health = army_unpacked.heavy_infantry.health * SHIFT_ARMY._16;

        let packed = heavy_infantry_health + light_infantry_health + arcanist_health + mage_health + longbow_health + archer_health + heavy_cavalry_health + light_cavalry_health + heavy_infantry_quantity + light_infantry_quantity + archanist_quantity + mage_quantity + longbow_quantity + archer_quantity + heavy_cavalry_quantity + light_cavalry_quantity;
        return (packed,);
    }

    // @notice Gets statistics of Army
    // @param army: An army
    // @returns ArmyStatistics which is a computed value
    func calculate_army_statistics{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(army: Army) -> (statistics: ArmyStatistics) {
        alloc_locals;

        let (cavalry_attack) = calculate_attack_values(
            BattalionIds.LightCavalry,
            army.light_cavalry.quantity,
            BattalionIds.HeavyCavalry,
            army.heavy_cavalry.quantity,
        );
        let (archery_attack) = calculate_attack_values(
            BattalionIds.Archer,
            army.archer.quantity,
            BattalionIds.Longbow,
            army.longbow.quantity,
        );
        let (magic_attack) = calculate_attack_values(
            BattalionIds.Mage,
            army.mage.quantity,
            BattalionIds.Arcanist,
            army.arcanist.quantity,
        );
        let (infantry_attack) = calculate_attack_values(
            BattalionIds.LightInfantry,
            army.light_infantry.quantity,
            BattalionIds.HeavyInfantry,
            army.heavy_infantry.quantity,
        );

        let (cavalry_defence, archer_defence, magic_defence, infantry_defence) = all_defence_value(
            army
        );

        return (
            ArmyStatistics(cavalry_attack, archery_attack, magic_attack, infantry_attack, cavalry_defence, archer_defence, magic_defence, infantry_defence),
        );
    }

    // @notice Gets attack value on same type battalions (Cav, Archer etc) to be used in combat formula
    // @param unit_1_id: unit id 1
    // @param unit_1_number: unit id 1
    // @param unit_2_id: unit id 2
    // @param unit_2_number: number of units
    // @ returns attack value
    func calculate_attack_values{range_check_ptr}(
        unit_1_id: felt, unit_1_number: felt, unit_2_id: felt, unit_2_number: felt
    ) -> (attack: felt) {
        alloc_locals;

        let (unit_1_attack_value) = attack_value(unit_1_id);
        let (unit_2_attack_value) = attack_value(unit_2_id);

        return (unit_1_attack_value * unit_1_number + unit_2_attack_value * unit_2_number,);
    }

    // @notice Gets attack value
    // @param battalion_id: Battalion ID
    // @ returns attack value
    func attack_value{range_check_ptr}(
        battalion_id: felt
    ) -> (attack: felt) {
        alloc_locals;

        let (type_label) = get_label_location(unit_attack);

        return ([type_label + battalion_id - 1],);

        unit_attack:
        dw BattalionStatistics.Attack.LightCavalry;
        dw BattalionStatistics.Attack.HeavyCavalry;
        dw BattalionStatistics.Attack.Archer;
        dw BattalionStatistics.Attack.Longbow;
        dw BattalionStatistics.Attack.Mage;
        dw BattalionStatistics.Attack.Arcanist;
        dw BattalionStatistics.Attack.LightInfantry;
        dw BattalionStatistics.Attack.HeavyInfantry;
    }

    // @notice Calculates real defence value
    // @param defense_sum: Sum of defence values
    // @param total_battalions: Total battalions of Army
    // @param unit_battalions: Qty of battalions
    // @returns defence value
    func calculate_defence_values{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        defense_sum: felt, total_battalions: felt, unit_battalions: felt
    ) -> (defence: felt) {
        alloc_locals;

        let (percentage_of_battalions, _) = unsigned_div_rem(
            (unit_battalions * 100) + 1, total_battalions + 1
        );

        let (values, _) = unsigned_div_rem(defense_sum * percentage_of_battalions, 100);

        return (values,);
    }

    // @notice Calculates total battalions
    // @param army: Unpacked Army
    // @returns Total battalions
    func calculate_total_battalions{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(army: Army) -> (total_battalions: felt) {
        alloc_locals;

        return (
            army.light_cavalry.quantity + army.heavy_cavalry.quantity + army.archer.quantity + army.longbow.quantity + army.mage.quantity + army.arcanist.quantity + army.light_infantry.quantity + army.heavy_infantry.quantity,
        );
    }

    // @notice Sums all defence values
    // @param army: Unpacked Army
    // @returns cavalry_defence, archer_defence, magic_defence, infantry_defence
    func all_defence_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        army: Army
    ) -> (
        cavalry_defence: felt, archer_defence: felt, magic_defence: felt, infantry_defence: felt
    ) {
        alloc_locals;

        let (total_battalions) = calculate_total_battalions(army);

        let c_defence = army.light_cavalry.quantity * BattalionStatistics.Defence.Cavalry.LightCavalry + army.heavy_cavalry.quantity * BattalionStatistics.Defence.Cavalry.HeavyCavalry + army.archer.quantity * BattalionStatistics.Defence.Cavalry.Archer + army.longbow.quantity * BattalionStatistics.Defence.Cavalry.Longbow + army.mage.quantity * BattalionStatistics.Defence.Cavalry.Mage + army.arcanist.quantity * BattalionStatistics.Defence.Cavalry.Arcanist + army.light_infantry.quantity * BattalionStatistics.Defence.Cavalry.LightInfantry + army.heavy_infantry.quantity * BattalionStatistics.Defence.Cavalry.HeavyInfantry;

        let a_defence = army.light_cavalry.quantity * BattalionStatistics.Defence.Archery.LightCavalry + army.heavy_cavalry.quantity * BattalionStatistics.Defence.Archery.HeavyCavalry + army.archer.quantity * BattalionStatistics.Defence.Archery.Archer + army.longbow.quantity * BattalionStatistics.Defence.Archery.Longbow + army.mage.quantity * BattalionStatistics.Defence.Archery.Mage + army.arcanist.quantity * BattalionStatistics.Defence.Archery.Arcanist + army.light_infantry.quantity * BattalionStatistics.Defence.Archery.LightInfantry + army.heavy_infantry.quantity * BattalionStatistics.Defence.Archery.HeavyInfantry;

        let m_defence = army.light_cavalry.quantity * BattalionStatistics.Defence.Magic.LightCavalry + army.heavy_cavalry.quantity * BattalionStatistics.Defence.Magic.HeavyCavalry + army.archer.quantity * BattalionStatistics.Defence.Magic.Archer + army.longbow.quantity * BattalionStatistics.Defence.Magic.Longbow + army.mage.quantity * BattalionStatistics.Defence.Magic.Mage + army.arcanist.quantity * BattalionStatistics.Defence.Magic.Arcanist + army.light_infantry.quantity * BattalionStatistics.Defence.Magic.LightInfantry + army.heavy_infantry.quantity * BattalionStatistics.Defence.Magic.HeavyInfantry;

        let i_defence = army.light_cavalry.quantity * BattalionStatistics.Defence.Infantry.LightCavalry + army.heavy_cavalry.quantity * BattalionStatistics.Defence.Infantry.HeavyCavalry + army.archer.quantity * BattalionStatistics.Defence.Infantry.Archer + army.longbow.quantity * BattalionStatistics.Defence.Infantry.Longbow + army.mage.quantity * BattalionStatistics.Defence.Infantry.Mage + army.arcanist.quantity * BattalionStatistics.Defence.Infantry.Arcanist + army.light_infantry.quantity * BattalionStatistics.Defence.Infantry.LightInfantry + army.heavy_infantry.quantity * BattalionStatistics.Defence.Infantry.HeavyInfantry;

        let (cavalry_defence) = calculate_defence_values(
            c_defence, total_battalions, army.light_cavalry.quantity + army.heavy_cavalry.quantity
        );
        let (archer_defence) = calculate_defence_values(
            a_defence, total_battalions, army.archer.quantity + army.longbow.quantity
        );
        let (magic_defence) = calculate_defence_values(
            m_defence, total_battalions, army.mage.quantity + army.arcanist.quantity
        );
        let (infantry_defence) = calculate_defence_values(
            i_defence, total_battalions, army.light_infantry.quantity + army.heavy_infantry.quantity
        );
        return (cavalry_defence, archer_defence, magic_defence, infantry_defence);
    }

    // @notice Calculates winner of battle
    // @param luck: Luck of Attacker - this is a number between 75-125 which adjusts the battle outcome
    // @param attacking_army: Attacking Army
    // @param defending_army: Defending Army
    // @return battle outcome (WIN or LOSS), updated attacking army, updated defending army
    func calculate_winner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(luck: felt, attacking_army: Army, defending_army: Army) -> (
        outcome: felt, updated_attacking_army: Army, updated_defending_army: Army
    ) {
        alloc_locals;

        let (attacking_army_statistics: ArmyStatistics) = calculate_army_statistics(
            attacking_army
        );
        let (defending_army_statistics: ArmyStatistics) = calculate_army_statistics(
            defending_army
        );

        let (cavalry_outcome) = calculate_luck_outcome(
            luck, attacking_army_statistics.cavalry_attack, defending_army_statistics.cavalry_defence
        );
        let (archery_outcome) = calculate_luck_outcome(
            luck, attacking_army_statistics.archery_attack, defending_army_statistics.archery_defence
        );
        let (magic_outcome) = calculate_luck_outcome(
            luck, attacking_army_statistics.magic_attack, defending_army_statistics.magic_defence
        );
        let (infantry_outcome) = calculate_luck_outcome(
            luck, attacking_army_statistics.infantry_attack, defending_army_statistics.infantry_defence
        );

        let final_outcome = cavalry_outcome + archery_outcome + magic_outcome + infantry_outcome;

        let successful = is_nn(final_outcome);

        let (updated_attacking_army) = update_army(
            attacking_army_statistics,
            defending_army_statistics,
            attacking_army,
        );
        let (updated_defending_army) = update_army(
            defending_army_statistics,
            attacking_army_statistics,
            defending_army,
        );

        return (successful, updated_attacking_army, updated_defending_army);
    }

    // @notice Calculates value after applying luck. All units use this.
    // @param attacking_statistics: Attacker statistics
    // @param defending_statistics: Defender statistics
    // @return luck outcome
    func calculate_luck_outcome{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        luck: felt, attacking_statistics: felt, defending_statistics: felt
    ) -> (outcome: felt) {
        alloc_locals;

        let (luck, _) = unsigned_div_rem(attacking_statistics * luck, 100);

        return (luck - defending_statistics,);
    }

    // @notice calculates Health of Battalion remaining after a battle
    // @param starting_health: Starting Health of Battalion
    // @param battalions: Number of Battalions
    // @param total_battalions: Total Battalions in Army
    // @param counter_attack: Counter attack value
    // @param counter_defence: Counter defence value
    // @return new health of battalions and battalions remaining
    //         if health goes to 0, then no battalions are alive and we return 0

    const COMBAT_ALGO_WEIGHT_1 = 50;  // weight in bp
    const FIXED_DAMAGE_AMOUNT = 20;
    const BASE_STATISTICS = 7;
    const BASE_BATTALIONS = 1;  // adds a base value to the battalions to make algo work

    func calculate_health_remaining{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        starting_health: felt,
        battalions: felt,
        total_battalions: felt,
        counter_attack: felt,
        counter_defence: felt,
    ) -> (new_health: felt, battalions: felt) {
        alloc_locals;

        // get weight of attack over defence
        let (attack_over_defence, _) = unsigned_div_rem(
            ((counter_attack + BASE_STATISTICS) * 100) * COMBAT_ALGO_WEIGHT_1,
            counter_defence + BASE_STATISTICS,
        );

        // use weight and multiple by starting health to get remaining health
        let (health_remaining, _) = unsigned_div_rem(attack_over_defence * starting_health, 10000);

        // get % of calculated battalions over total battalions of that type
        let (battalion_distribution, _) = unsigned_div_rem(
            (battalions) * 100, total_battalions + BASE_BATTALIONS
        );

        // get actual health in of battalion by using the battalion distribution
        let (real_battalion_health, _) = unsigned_div_rem(
            health_remaining * battalion_distribution, 100
        );

        // add modifier so the health can depleate past 0
        let modified_health = real_battalion_health - FIXED_DAMAGE_AMOUNT;

        // check if dead,IF yes, then return 0,0
        let is_dead = is_le(modified_health, 0);
        if (is_dead == TRUE) {
            return (0, 0);
        }

        return (real_battalion_health, battalions);
    }

    // @notice updates Army
    // @param attack_army_statistics: ArmyStatistics of attacking Army
    // @param defending_army_statistics: ArmyStatistics of defending Army
    // @param attack_army: Army to be updated
    // @returns Army after it has had health modifier applied
    func update_army{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
    }(
        attack_army_statistics: ArmyStatistics,
        defending_army_statistics: ArmyStatistics,
        attack_army: Army,
    ) -> (updated_army: Army) {
        alloc_locals;

        let (light_cavalry_health, light_cavalry_battalions) = calculate_health_remaining(
            attack_army.light_cavalry.health,
            attack_army.light_cavalry.quantity,
            attack_army.light_cavalry.quantity + attack_army.heavy_cavalry.quantity,
            attack_army_statistics.infantry_attack,
            defending_army_statistics.infantry_defence,
        );
        let (heavy_cavalry_health, heavy_cavalry_battalions) = calculate_health_remaining(
            attack_army.heavy_cavalry.health,
            attack_army.heavy_cavalry.quantity,
            attack_army.light_cavalry.quantity + attack_army.heavy_cavalry.quantity,
            attack_army_statistics.infantry_attack,
            defending_army_statistics.infantry_defence,
        );
        let (archer_health, archer_battalions) = calculate_health_remaining(
            attack_army.archer.health,
            attack_army.archer.quantity,
            attack_army.archer.quantity + attack_army.longbow.quantity,
            attack_army_statistics.cavalry_attack,
            defending_army_statistics.cavalry_defence,
        );
        let (longbow_health, longbow_battalions) = calculate_health_remaining(
            attack_army.longbow.health,
            attack_army.longbow.quantity,
            attack_army.archer.quantity + attack_army.longbow.quantity,
            attack_army_statistics.cavalry_attack,
            defending_army_statistics.cavalry_defence,
        );
        let (mage_health, mage_battalions) = calculate_health_remaining(
            attack_army.mage.health,
            attack_army.mage.quantity,
            attack_army.mage.quantity + attack_army.arcanist.quantity,
            attack_army_statistics.archery_attack,
            defending_army_statistics.archery_defence,
        );
        let (archanist_health, archanist_battalions) = calculate_health_remaining(
            attack_army.arcanist.health,
            attack_army.arcanist.quantity,
            attack_army.mage.quantity + attack_army.arcanist.quantity,
            attack_army_statistics.archery_attack,
            defending_army_statistics.archery_defence,
        );
        let (light_infantry_health, light_infantry_battalions) = calculate_health_remaining(
            attack_army.light_infantry.health,
            attack_army.light_infantry.quantity,
            attack_army.light_infantry.quantity + attack_army.heavy_infantry.quantity,
            attack_army_statistics.infantry_attack,
            defending_army_statistics.infantry_defence,
        );
        let (heavy_infantry_health, heavy_infantry_battalions) = calculate_health_remaining(
            attack_army.heavy_infantry.health,
            attack_army.heavy_infantry.quantity,
            attack_army.light_infantry.quantity + attack_army.heavy_infantry.quantity,
            attack_army_statistics.magic_attack,
            defending_army_statistics.magic_defence,
        );

        let updated_attacking_army = Army(
            Battalion(light_cavalry_battalions,
            light_cavalry_health),
            Battalion(heavy_cavalry_battalions,
            heavy_cavalry_health),
            Battalion(archer_battalions,
            archer_health),
            Battalion(longbow_battalions,
            longbow_health),
            Battalion(mage_battalions,
            mage_health),
            Battalion(archanist_battalions,
            archanist_health),
            Battalion(light_infantry_battalions,
            light_infantry_health),
            Battalion(heavy_infantry_battalions,
            heavy_infantry_health),
        );

        return (updated_attacking_army,);
    }

    // @notice Asserts can build battalions
    // @param battalion_ids: Array of Battalion IDs that you want to build
    // @param realm_buildings: A RealmBuildings struct specifying which buildings does a Realm have
    // @return fails if buildings do not exist on Realm
    func assert_can_build_battalions{range_check_ptr}(
        battalion_ids_len: felt, battalion_ids: felt*, realm_buildings: RealmBuildings
    ) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        if (battalion_ids_len == 0) {
            return ();
        }

        let (building) = get_battalion_building([battalion_ids]);
        let buildings = cast(&realm_buildings, felt*);
        let buildings_in_realm: felt = [buildings + building - 1];
        with_attr error_message("Combat: missing building to build Battalion") {
            assert_not_zero(buildings_in_realm);
        }

        return assert_can_build_battalions(
            battalion_ids_len - 1, battalion_ids + 1, realm_buildings
        );
    }

    // @notice Returns battalion building
    // @param battalion_id: Battalion ID
    // @return building id
    func get_battalion_building{range_check_ptr}(battalion_id: felt) -> (building: felt) {
        assert_not_zero(battalion_id);
        assert_lt(battalion_id, BattalionIds.SIZE);

        let (building_label) = get_label_location(battalion_building_per_id);

        return ([building_label + battalion_id - 1],);

        battalion_building_per_id:
        dw BattalionStatistics.RequiredBuilding.LightCavalry;
        dw BattalionStatistics.RequiredBuilding.HeavyCavalry;
        dw BattalionStatistics.RequiredBuilding.Archer;
        dw BattalionStatistics.RequiredBuilding.Longbow;
        dw BattalionStatistics.RequiredBuilding.Mage;
        dw BattalionStatistics.RequiredBuilding.Arcanist;
        dw BattalionStatistics.RequiredBuilding.LightInfantry;
        dw BattalionStatistics.RequiredBuilding.HeavyInfantry;
    }
}
