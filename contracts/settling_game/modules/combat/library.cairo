// amarna: disable=arithmetic-add,arithmetic-div,arithmetic-mul,arithmetic-sub
// -----------------------------------
//   module.COMBAT Library
//   Library to help with the combat mechanics.
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_lt
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import get_block_timestamp
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
from contracts.settling_game.utils.constants import CCombat

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

    // @notice Gets statistics of Army
    // @param army: An army
    // @returns ArmyStatistics which is a computed value
    func calculate_army_statistics{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        attacking_army: Army, defending_army: Army
    ) -> (statistics: ArmyStatistics) {
        alloc_locals;

        let (cavalry_attack) = calculate_attack_values(
            BattalionIds.LightCavalry,
            attacking_army.light_cavalry.quantity,
            BattalionIds.HeavyCavalry,
            attacking_army.heavy_cavalry.quantity,
        );
        let (archery_attack) = calculate_attack_values(
            BattalionIds.Archer,
            attacking_army.archer.quantity,
            BattalionIds.Longbow,
            attacking_army.longbow.quantity,
        );
        let (magic_attack) = calculate_attack_values(
            BattalionIds.Mage,
            attacking_army.mage.quantity,
            BattalionIds.Arcanist,
            attacking_army.arcanist.quantity,
        );
        let (infantry_attack) = calculate_attack_values(
            BattalionIds.LightInfantry,
            attacking_army.light_infantry.quantity,
            BattalionIds.HeavyInfantry,
            attacking_army.heavy_infantry.quantity,
        );

        let (cavalry_defence, archer_defence, magic_defence, infantry_defence) = all_defence_value(
            attacking_army, defending_army
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

    // @notice Calculates real defence value
    // @param defence_sum: Sum of defence values
    // @param attacking_total_battalions: Total battalions of Army
    // @param attacking_unit_battalions: Qty of battalions
    // @returns calculated defence value
    func calculate_defence_values{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        defence: felt, attacking_total_battalions: felt, attacking_unit_battalions: felt
    ) -> (defence: felt) {
        alloc_locals;

        // get ratio of battlions to whole Army
        let (percentage_of_battalions, _) = unsigned_div_rem(
            (attacking_unit_battalions * 1000), attacking_total_battalions
        );

        let (values, _) = unsigned_div_rem(defence * percentage_of_battalions, 1000);

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
    // @param attacking_army: attacking Army unpacked
    // @param defending_army: defending Army unpacked
    // @returns cavalry_defence, archer_defence, magic_defence, infantry_defence
    func all_defence_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        attacking_army: Army, defending_army: Army
    ) -> (
        cavalry_defence: felt, archer_defence: felt, magic_defence: felt, infantry_defence: felt
    ) {
        alloc_locals;

        let (total_battalions) = calculate_total_battalions(defending_army);

        let c_defence = attacking_army.light_cavalry.quantity * BattalionStatistics.Defence.Cavalry.LightCavalry + attacking_army.heavy_cavalry.quantity * BattalionStatistics.Defence.Cavalry.HeavyCavalry + attacking_army.archer.quantity * BattalionStatistics.Defence.Cavalry.Archer + attacking_army.longbow.quantity * BattalionStatistics.Defence.Cavalry.Longbow + attacking_army.mage.quantity * BattalionStatistics.Defence.Cavalry.Mage + attacking_army.arcanist.quantity * BattalionStatistics.Defence.Cavalry.Arcanist + attacking_army.light_infantry.quantity * BattalionStatistics.Defence.Cavalry.LightInfantry + attacking_army.heavy_infantry.quantity * BattalionStatistics.Defence.Cavalry.HeavyInfantry;

        let a_defence = attacking_army.light_cavalry.quantity * BattalionStatistics.Defence.Archery.LightCavalry + attacking_army.heavy_cavalry.quantity * BattalionStatistics.Defence.Archery.HeavyCavalry + attacking_army.archer.quantity * BattalionStatistics.Defence.Archery.Archer + attacking_army.longbow.quantity * BattalionStatistics.Defence.Archery.Longbow + attacking_army.mage.quantity * BattalionStatistics.Defence.Archery.Mage + attacking_army.arcanist.quantity * BattalionStatistics.Defence.Archery.Arcanist + attacking_army.light_infantry.quantity * BattalionStatistics.Defence.Archery.LightInfantry + attacking_army.heavy_infantry.quantity * BattalionStatistics.Defence.Archery.HeavyInfantry;

        let m_defence = attacking_army.light_cavalry.quantity * BattalionStatistics.Defence.Magic.LightCavalry + attacking_army.heavy_cavalry.quantity * BattalionStatistics.Defence.Magic.HeavyCavalry + attacking_army.archer.quantity * BattalionStatistics.Defence.Magic.Archer + attacking_army.longbow.quantity * BattalionStatistics.Defence.Magic.Longbow + attacking_army.mage.quantity * BattalionStatistics.Defence.Magic.Mage + attacking_army.arcanist.quantity * BattalionStatistics.Defence.Magic.Arcanist + attacking_army.light_infantry.quantity * BattalionStatistics.Defence.Magic.LightInfantry + attacking_army.heavy_infantry.quantity * BattalionStatistics.Defence.Magic.HeavyInfantry;

        let i_defence = attacking_army.light_cavalry.quantity * BattalionStatistics.Defence.Infantry.LightCavalry + attacking_army.heavy_cavalry.quantity * BattalionStatistics.Defence.Infantry.HeavyCavalry + attacking_army.archer.quantity * BattalionStatistics.Defence.Infantry.Archer + attacking_army.longbow.quantity * BattalionStatistics.Defence.Infantry.Longbow + attacking_army.mage.quantity * BattalionStatistics.Defence.Infantry.Mage + attacking_army.arcanist.quantity * BattalionStatistics.Defence.Infantry.Arcanist + attacking_army.light_infantry.quantity * BattalionStatistics.Defence.Infantry.LightInfantry + attacking_army.heavy_infantry.quantity * BattalionStatistics.Defence.Infantry.HeavyInfantry;

        let (cavalry_defence) = calculate_defence_values(
            c_defence,
            total_battalions,
            defending_army.light_cavalry.quantity + defending_army.heavy_cavalry.quantity,
        );
        let (archer_defence) = calculate_defence_values(
            a_defence,
            total_battalions,
            defending_army.archer.quantity + defending_army.longbow.quantity,
        );
        let (magic_defence) = calculate_defence_values(
            m_defence,
            total_battalions,
            defending_army.mage.quantity + defending_army.arcanist.quantity,
        );
        let (infantry_defence) = calculate_defence_values(
            i_defence,
            total_battalions,
            defending_army.light_infantry.quantity + defending_army.heavy_infantry.quantity,
        );
        return (cavalry_defence, archer_defence, magic_defence, infantry_defence);
    }

    // @notice Calculates winner of battle
    // @param luck: Luck of Attacker - this is a number between 75-125 which adjusts the battle outcome
    // @param attacking_army: Attacking Army
    // @param defending_army: Defending Army
    // @return battle outcome (WIN or LOSS), updated attacking army, updated defending army
    func calculate_winner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        luck: felt, attacking_army: Army, defending_army: Army
    ) -> (outcome: felt, updated_attacking_army: Army, updated_defending_army: Army) {
        alloc_locals;

        // calculate statistics
        let (attacking_army_statistics: ArmyStatistics) = calculate_army_statistics(
            attacking_army, defending_army
        );
        let (defending_army_statistics: ArmyStatistics) = calculate_army_statistics(
            defending_army, attacking_army
        );

        // get outcomes of battles
        let (cavalry_outcome) = calculate_luck_outcome(
            luck,
            attacking_army_statistics.cavalry_attack,
            defending_army_statistics.cavalry_defence,
        );
        let (archery_outcome) = calculate_luck_outcome(
            luck,
            attacking_army_statistics.archery_attack,
            defending_army_statistics.archery_defence,
        );
        let (magic_outcome) = calculate_luck_outcome(
            luck, attacking_army_statistics.magic_attack, defending_army_statistics.magic_defence
        );
        let (infantry_outcome) = calculate_luck_outcome(
            luck,
            attacking_army_statistics.infantry_attack,
            defending_army_statistics.infantry_defence,
        );

        // less than 0 = unsuccessful raid
        let final_outcome = cavalry_outcome + archery_outcome + magic_outcome + infantry_outcome;
        let successful = is_nn(final_outcome);

        // update armies battlion health
        let (updated_attacking_army) = update_army(
            attacking_army_statistics,
            defending_army_statistics,
            attacking_army,
            final_outcome,
            TRUE,
        );
        let (updated_defending_army) = update_army(
            defending_army_statistics,
            attacking_army_statistics,
            defending_army,
            final_outcome,
            FALSE,
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
    // @return new health of battalions and battalions remaining
    //         if health goes to 0, then no battalions are alive and we return 0
    func calculate_health_remaining{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(starting_health: felt, battalion_attack: felt, counter_defence: felt, hp_loss: felt) -> (
        new_health: felt, battalions: felt
    ) {
        alloc_locals;

        // get weight of attack over defence
        let (attack_over_defence, _) = unsigned_div_rem(
            battalion_attack * 1000, counter_defence + 1
        );

        // get base health remaining - divided by 1000000 as values coming in a bp
        let (health_remaining, _) = unsigned_div_rem(
            attack_over_defence * hp_loss * starting_health, 1000000
        );

        // check if health has been taken off. If no health, then apply fixed damage amount to starting health
        // if yes, then apply fixed damage to health remaining
        let is_above_base_line_health = is_le(starting_health, health_remaining);
        if (is_above_base_line_health == TRUE) {
            let (new_health, _) = unsigned_div_rem(
                starting_health * CCombat.FIXED_DAMAGE_AMOUNT, 100
            );
            tempvar actual_health_remaining = new_health;
        } else {
            let (new_health, _) = unsigned_div_rem(
                health_remaining * CCombat.FIXED_DAMAGE_AMOUNT, 100
            );
            tempvar actual_health_remaining = new_health;
        }

        // if health 0 the battalion is dead. Return 0,0
        let is_dead = is_le(actual_health_remaining, 0);
        if (is_dead == TRUE) {
            return (0, 0);
        }

        // smallest amount of battalions is 1 - Battles reduce the Battalions.
        let is_battalion_alive = is_le(actual_health_remaining, 100);
        let (adjusted_battalions, _) = unsigned_div_rem(actual_health_remaining, 100);
        if (is_battalion_alive == TRUE) {
            tempvar battalions = 1;
        } else {
            tempvar battalions = adjusted_battalions;
        }

        return (actual_health_remaining, battalions);
    }

    // @notice calculates the health percentage loss of a battle. 450 is half the size of a fully maxxed Army
    // @param outcome: battle outcome
    // @return health_percentage: percentage loss
    func calculate_health_loss_percentage{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(outcome: felt, is_attacking: felt) -> (health_percentage: felt) {
        alloc_locals;

        if (is_attacking == TRUE) {
            let less_than = is_le(outcome, 0);

            if (less_than == TRUE) {
                let (i, _) = unsigned_div_rem(((-outcome)) * 1000, 450);
                return (health_percentage=1000 - i);
            }
        } else {
            let less_than = is_le(0, outcome);

            if (less_than == TRUE) {
                let (i, _) = unsigned_div_rem(((-outcome)) * 1000, 450);
                return (health_percentage=1000 - i);
            }
        }

        return (health_percentage=1000);
    }

    // @notice updates Army
    // @param attack_army_statistics: ArmyStatistics of attacking Army
    // @param defending_army_statistics: ArmyStatistics of defending Army
    // @param attack_army: Army to be updated
    // @returns Army after it has had health modifier applied
    func update_army{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        attack_army_statistics: ArmyStatistics,
        defending_army_statistics: ArmyStatistics,
        attack_army: Army,
        outcome: felt,
        is_attacking: felt,
    ) -> (updated_army: Army) {
        alloc_locals;

        // get HP loss
        let (hp_loss) = calculate_health_loss_percentage(outcome, is_attacking);

        // get health for each battalion type
        let (light_cavalry_health, light_cavalry_battalions) = calculate_health_remaining(
            attack_army.light_cavalry.health * attack_army.light_cavalry.quantity,
            attack_army_statistics.infantry_attack,
            defending_army_statistics.infantry_defence,
            hp_loss,
        );
        let (heavy_cavalry_health, heavy_cavalry_battalions) = calculate_health_remaining(
            attack_army.heavy_cavalry.health * attack_army.heavy_cavalry.quantity,
            attack_army_statistics.infantry_attack,
            defending_army_statistics.infantry_defence,
            hp_loss,
        );
        let (archer_health, archer_battalions) = calculate_health_remaining(
            attack_army.archer.health * attack_army.archer.quantity,
            attack_army_statistics.cavalry_attack,
            defending_army_statistics.cavalry_defence,
            hp_loss,
        );
        let (longbow_health, longbow_battalions) = calculate_health_remaining(
            attack_army.longbow.health * attack_army.longbow.quantity,
            attack_army_statistics.cavalry_attack,
            defending_army_statistics.cavalry_defence,
            hp_loss,
        );
        let (mage_health, mage_battalions) = calculate_health_remaining(
            attack_army.mage.health * attack_army.mage.quantity,
            attack_army_statistics.archery_attack,
            defending_army_statistics.archery_defence,
            hp_loss,
        );
        let (archanist_health, archanist_battalions) = calculate_health_remaining(
            attack_army.arcanist.health * attack_army.arcanist.quantity,
            attack_army_statistics.archery_attack,
            defending_army_statistics.archery_defence,
            hp_loss,
        );
        let (light_infantry_health, light_infantry_battalions) = calculate_health_remaining(
            attack_army.light_infantry.health * attack_army.light_infantry.quantity,
            attack_army_statistics.magic_attack,
            defending_army_statistics.magic_defence,
            hp_loss,
        );
        let (heavy_infantry_health, heavy_infantry_battalions) = calculate_health_remaining(
            attack_army.heavy_infantry.health * attack_army.heavy_infantry.quantity,
            attack_army_statistics.magic_attack,
            defending_army_statistics.magic_defence,
            hp_loss,
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

    // -----------------------------------
    // Packing & Unpacking
    // -----------------------------------

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

    // -----------------------------------
    // Asserts
    // -----------------------------------

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

    // -----------------------------------
    // Getters
    // -----------------------------------

    // @notice Gets attack value
    // @param battalion_id: Battalion ID
    // @ returns attack value
    func attack_value{range_check_ptr}(battalion_id: felt) -> (attack: felt) {
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

    func flatten_ids{range_check_ptr}(
        battalion_ids_len: felt,
        battalion_ids: felt*,
        battalion_qty_len: felt,
        battalion_qty: felt*,
        all_ids: felt*,
    ) {
        alloc_locals;

        if (battalion_ids_len == 0) {
            return ();
        }

        flatten_recursive([battalion_qty], all_ids, [battalion_ids]);

        return flatten_ids(
            battalion_ids_len - 1,
            battalion_ids + 1,
            battalion_qty_len - 1,
            battalion_qty + 1,
            all_ids + [battalion_qty],
        );
    }

    func flatten_recursive{range_check_ptr}(len_all_ids: felt, all_ids: felt*, id: felt) {
        alloc_locals;

        if (len_all_ids == 0) {
            return ();
        }

        assert [all_ids] = id;

        return flatten_recursive(len_all_ids - 1, all_ids + 1, id);
    }

    func id_length{range_check_ptr}(all_qtys_len: felt, all_qtys: felt*, id: felt) -> felt {
        alloc_locals;

        if (all_qtys_len == 0) {
            return (id);
        }

        return id_length(all_qtys_len - 1, all_qtys + 1, id + [all_qtys]);
    }
}
