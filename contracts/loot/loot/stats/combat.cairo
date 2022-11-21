// SPDX-License-Identifier: MIT
//

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le, is_not_zero, is_le_felt
from starkware.cairo.common.registers import get_label_location

from contracts.loot.constants.item import Item, Type, ItemIds, Slot
from contracts.loot.constants.combat import WeaponEfficacy, WeaponEfficiacyDamageMultiplier
from contracts.loot.beast.stats.beast import BeastStats
from contracts.loot.loot.stats.item import ItemStats
from contracts.loot.constants.beast import Beast, BeastStatic, BeastDynamic
from contracts.loot.constants.obstacle import Obstacle, ObstacleUtils

namespace CombatStats {
    func weapon_vs_armor_efficacy{syscall_ptr: felt*, range_check_ptr}(
        weapon_type: felt, armor_type: felt
    ) -> (class: felt) {
        alloc_locals;

        let (blade_location) = get_label_location(blade_efficacy);
        let (bludgeon_location) = get_label_location(bludgeon_efficacy);
        let (magic_location) = get_label_location(magic_efficacy);

        if (weapon_type == Type.Weapon.blade) {
            [ap] = blade_location, ap++;
        } else {
            if (weapon_type == Type.Weapon.bludgeon) {
                [ap] = bludgeon_location, ap++;
            } else {
                if (weapon_type == Type.Weapon.magic) {
                    [ap] = magic_location, ap++;
                }
            }
        }

        let label_location = [ap - 1];
        return ([label_location + armor_type - Type.Armor.generic],);

        blade_efficacy:
        dw WeaponEfficacy.Low;
        dw WeaponEfficacy.Low;
        dw WeaponEfficacy.Medium;
        dw WeaponEfficacy.High;

        bludgeon_efficacy:
        dw WeaponEfficacy.Low;
        dw WeaponEfficacy.Medium;
        dw WeaponEfficacy.High;
        dw WeaponEfficacy.Low;

        magic_efficacy:
        dw WeaponEfficacy.Low;
        dw WeaponEfficacy.High;
        dw WeaponEfficacy.Low;
        dw WeaponEfficacy.Medium;
    }

    func get_attack_effectiveness{syscall_ptr: felt*, range_check_ptr}(
        attack_effectiveness: felt, base_weapon_damage: felt
    ) -> (damage: felt) {
        alloc_locals;

        if (attack_effectiveness == WeaponEfficacy.Low) {
            return (base_weapon_damage * WeaponEfficiacyDamageMultiplier.Low,);
        }

        if (attack_effectiveness == WeaponEfficacy.Medium) {
            return (base_weapon_damage * WeaponEfficiacyDamageMultiplier.Medium,);
        }

        if (attack_effectiveness == WeaponEfficacy.High) {
            return (base_weapon_damage * WeaponEfficiacyDamageMultiplier.High,);
        }

        return (0,);
    }

    // calculate_damage_from_weapon calculates the damage a weapon inflicts against a specific piece of armor
    // parameters: Item weapon, Item armor
    // returns: damage
    func calculate_damage{syscall_ptr: felt*, range_check_ptr}(
        attack_type: felt,
        attack_rank: felt,
        attack_greatness: felt,
        armor_type: felt,
        armor_rank: felt,
        armor_greatness: felt,
    ) -> (damage: felt) {
        alloc_locals;

        const rank_ceiling = 6;

        // use weapon rank and greatness to give every item a damage rating of 0-100
        let base_weapon_damage = (rank_ceiling - attack_rank) * attack_greatness;

        // Get effectiveness of weapon vs armor
        let (attack_effectiveness) = weapon_vs_armor_efficacy(attack_type, armor_type);
        // let (total_weapon_damage) = get_attack_effectiveness(
        //     attack_effectiveness, base_weapon_damage
        // );

        // // use armor rank and greatness to give armor a defense rating of 0-100
        // let armor_strength = (rank_ceiling - armor_rank) * armor_greatness;

        // // check if armor strength is less than or equal to weapon damage
        // let dealt_damage = is_le_felt(armor_strength, total_weapon_damage);
        // if (dealt_damage == 1) {
        //     // if it is, damage dealt will be positive so return it
        //     let damage_dealt = total_weapon_damage - armor_strength;
        //     return (damage_dealt,);
        // } else {
        //     // otherwise damage dealt will be negative so we return 0
        //     return (0,);
        // }

        return (attack_effectiveness,);
    }

    // calculate_damage_from_weapon calculates the damage a weapon inflicts against a specific piece of armor
    // parameters: Item weapon, Item armor
    // returns: damage
    func calculate_damage_from_weapon{syscall_ptr: felt*, range_check_ptr}(
        weapon: Item, armor: Item
    ) -> (damage: felt) {
        alloc_locals;

        // Get attack attributes
        let (attack_type) = ItemStats.item_type(weapon.Id);

        // Get armor attributes
        let (armor_type) = ItemStats.item_type(armor.Id);

        // pass details of attack and armor to core damage calculation function
        let (damage_dealt) = calculate_damage(
            attack_type, weapon.Rank, weapon.Greatness, armor_type, armor.Rank, armor.Greatness
        );

        // return damage
        return (damage_dealt,);
    }

    // Calculates damage dealt from a beast by converting beast into a Loot weapon and calling calculate_damage_from_weapon
    func calculate_damage_from_beast{syscall_ptr: felt*, range_check_ptr}(
        beast: Beast, armor: Item
    ) -> (damage: felt) {
        alloc_locals;

        // Get beast type
        let (attack_type) = BeastStats.get_type_from_id(beast.Id);

        // Get armor type
        let (armor_type) = ItemStats.item_type(armor.Id);

        // pass details of attack and armor to core damage calculation function
        let (damage_dealt) = calculate_damage(
            attack_type, beast.Rank, beast.XP, armor_type, armor.Rank, armor.Greatness
        );

        // return damage
        return (damage_dealt,);
    }

    // Calculates damage dealt from a beast by converting beast into a Loot weapon and calling calculate_damage_from_weapon
    func calculate_damage_to_beast{syscall_ptr: felt*, range_check_ptr}(
        beast: Beast, weapon: Item
    ) -> (damage: felt) {
        alloc_locals;

        // pass details of attack and armor to core damage calculation function
        // NOTE: for now beast armor is set as generic (they don't have armor)
        let (damage_dealt) = calculate_damage(
            weapon.Type, weapon.Rank, weapon.Greatness, Type.Armor.generic, beast.Rank, beast.XP
        );

        // return damage
        return (damage_dealt,);
    }

    // Calculate damage from an obstacle
    func calculate_damage_from_obstacle{syscall_ptr: felt*, range_check_ptr}(
        obstacle: Obstacle, armor: Item
    ) -> (damage: felt) {
        alloc_locals;

        // Get beast type
        let (attack_type) = ObstacleUtils.get_type_from_id(obstacle.Id);

        // Get armor type
        let (armor_type) = ItemStats.item_type(armor.Id);

        // pass details of attack and armor to core damage calculation function
        let (damage_dealt) = calculate_damage(
            attack_type, obstacle.Rank, obstacle.Greatness, armor_type, armor.Rank, armor.Greatness
        );

        // return damage dealt
        return (damage_dealt,);
    }
}
