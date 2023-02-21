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
from starkware.cairo.common.pow import pow

from contracts.loot.constants.item import Item, Type, ItemIds, Slot
from contracts.loot.constants.combat import WeaponEfficacy, WeaponEfficiacyDamageMultiplier
from contracts.loot.beast.stats.beast import BeastStats
from contracts.loot.beast.library import BeastLib
from contracts.loot.loot.stats.item import ItemStats
from contracts.loot.constants.adventurer import AdventurerState
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

        // This section of code determines which of the lookup tables get referenced
        if (weapon_type == Type.Weapon.blade) {
            // Use the blade_efficacy lookup table
            [ap] = blade_location, ap++;
        } else {
            if (weapon_type == Type.Weapon.bludgeon) {
                // Use the bludgeon_efficacy lookup table
                [ap] = bludgeon_location, ap++;
            } else {
                if (weapon_type == Type.Weapon.magic) {
                    // Use the magic_efficacy lookup table
                    [ap] = magic_location, ap++;
                } else {
                    // This is the generic weapon (melee) fall through, always does low
                    return (WeaponEfficacy.Low,);
                }
            }
        }
        let label_location = [ap - 1];

        // This determines which index we use in the selected lookup table
        return ([label_location + armor_type - Type.Armor.generic],);

        blade_efficacy:
        dw WeaponEfficacy.High;
        dw WeaponEfficacy.Low;
        dw WeaponEfficacy.Medium;
        dw WeaponEfficacy.High;

        bludgeon_efficacy:
        dw WeaponEfficacy.High;
        dw WeaponEfficacy.Medium;
        dw WeaponEfficacy.High;
        dw WeaponEfficacy.Low;

        magic_efficacy:
        dw WeaponEfficacy.High;
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
        entity_level: felt,
        rnd: felt
    ) -> (damage: felt) {
        alloc_locals;

        const rank_ceiling = 6;

        // use weapon rank and greatness to give every item a damage rating of 0-100
        // TODO: add item weight into damage calculation
        let base_weapon_damage = (rank_ceiling - attack_rank) * attack_greatness;

        // Get effectiveness of weapon vs armor
        let (attack_effectiveness) = weapon_vs_armor_efficacy(attack_type, armor_type);

        // use armor rank and greatness to give armor a defense rating of 0-100
        // TODO: add item weight into strength calculation
        let armor_strength = (rank_ceiling - armor_rank) * armor_greatness;

        let weapon_damage = base_weapon_damage - armor_strength;

        let (total_weapon_damage) = get_attack_effectiveness(
            attack_effectiveness, weapon_damage
        );

        // check if armor strength is less than or equal to weapon damage
        let dealt_damage = is_le_felt(armor_strength, base_weapon_damage);
        if (dealt_damage == 1) {
            // if it is, damage dealt will be positive so return it
            // @distracteddev: calculate whether hit is critical, formula = damage * (1.5)^critical
            let (_, critical_hit_chance) = unsigned_div_rem(rnd, 4);
            let critical_hit = is_le(critical_hit_chance, 0);
            // @distracteddev: provide some multi here with adventurer level: e.g. damage + (1 + ((1 - level) * 0.1))
            let (adventurer_level_damage) = calculate_entity_level_boost(total_weapon_damage, entity_level);
            let (critical_damage_dealt) = calculate_critical_damage(adventurer_level_damage, critical_hit);
            return (critical_damage_dealt,);
        } else {
            // otherwise damage dealt will be negative so we return 0
            return (0,);
        }
    }

    // calculate_damage_from_weapon calculates the damage a weapon inflicts against a specific piece of armor
    // parameters: Item weapon, Item armor
    // returns: damage
    func calculate_damage_from_weapon{syscall_ptr: felt*, range_check_ptr}(
        weapon: Item, armor: Item, unpacked_adventurer: AdventurerState, rnd: felt
    ) -> (damage: felt) {
        alloc_locals;

        // Get attack attributes
        let (attack_type) = ItemStats.item_type(weapon.Id);

        // Get armor attributes
        let (armor_type) = ItemStats.item_type(armor.Id);

        // pass details of attack and armor to core damage calculation function
        let (damage_dealt) = calculate_damage(
            attack_type, weapon.Rank, weapon.Greatness, armor_type, armor.Rank, armor.Greatness, unpacked_adventurer.Level, rnd
        );

        // return damage
        return (damage_dealt,);
    }

    // Calculates damage dealt from a beast by converting beast into a Loot weapon and calling calculate_damage_from_weapon
    func calculate_damage_from_beast{syscall_ptr: felt*, range_check_ptr}(
        beast: Beast, armor: Item, rnd: felt
    ) -> (damage: felt) {
        alloc_locals;

        // Get beast attack type
        let (attack_type) = BeastStats.get_attack_type_from_id(beast.Id);

        // Get armor type
        // NOTE: @loothero if no armor then armor type is generic
        if (armor.Id == 0) {
            // force armor_type generic
            return  calculate_damage(
                attack_type, beast.Rank, beast.Level, Type.Armor.generic, armor.Rank, armor.Greatness, 1, rnd
            );
        } else {
            let (armor_type) = ItemStats.item_type(armor.Id);
            // pass details of attack and armor to core damage calculation function
            // @distracteddev: added param to change based on adventurer level
            // return damage
            return  calculate_damage(
                attack_type, beast.Rank, beast.Level, armor_type, armor.Rank, armor.Greatness, 1, rnd
            );
        }
    }

    // Calculates damage dealt from a beast by converting beast into a Loot weapon and calling calculate_damage_from_weapon
    func calculate_damage_to_beast{syscall_ptr: felt*, range_check_ptr}(
        beast: Beast, weapon: Item, unpacked_adventurer: AdventurerState, rnd: felt
    ) -> (damage: felt) {
        alloc_locals;

        // Get beast attack type
        let (armor_type) = BeastStats.get_armor_type_from_id(beast.Id);

        // If adventurer has no weapon, they get get generic (melee)
        if (weapon.Id == 0) {
            // force generic type and greatness 1
            return calculate_damage(
                Type.Weapon.generic, weapon.Rank, 1, armor_type, beast.Rank, beast.Level, unpacked_adventurer.Level, rnd
            );
        } else {
            // return damage
            return calculate_damage(
                weapon.Type, weapon.Rank, weapon.Greatness, armor_type, beast.Rank, beast.Level, unpacked_adventurer.Level, rnd
            );
        }
    }

    // Calculate damage from an obstacle
    func calculate_damage_from_obstacle{syscall_ptr: felt*, range_check_ptr}(
        obstacle: Obstacle, armor: Item
    ) -> (damage: felt) {
        alloc_locals;

        // Get armor type
        let (armor_type) = ItemStats.item_type(armor.Id);

        if (armor.Id == 0) {
            // force armor type generic
            return calculate_damage(
                obstacle.Type, obstacle.Rank, obstacle.Greatness, Type.Armor.generic, armor.Rank, armor.Greatness, 1, 1
            );
        } else {
            // return damage dealt
            return calculate_damage(
                obstacle.Type, obstacle.Rank, obstacle.Greatness, armor_type, armor.Rank, armor.Greatness, 1, 1
            );
        }
    }

    func calculate_xp_earned{syscall_ptr: felt*, range_check_ptr}(rank: felt, level: felt) -> (
        xp_earned: felt
    ) {
        const rank_ceiling = 6;
        let xp_earned = (rank_ceiling - rank) * level;
        return (xp_earned,);
    }

    // @notice Checks xp to see if adventurer, or NPC has reached next level
    // The formula for reaching the next level is approximately: ((current_level*10)/x)^y
    // X: 3, Y: 2
    // Level	XP
    //     0    0
    //     1	9
    //     2	36
    //     3	100
    //     4	169
    //     5	256
    //     6	400
    //     7	529
    //     8	676
    //     9	900
    // @param: xp: The XP of the adventurer or NPC
    // @param: level: The level of the adventurer or NPC
    // @return success: true or false

    // TODO: Enable this to handle multi-level situations by returning number of levels increased
    func check_for_level_increase{syscall_ptr: felt*, range_check_ptr}(xp: felt, level: felt) -> (
        level_increase: felt
    ) {
        alloc_locals;

        // multiply current level by 10 to keep function greater than 1
        let level_times_ten = level * 10;

        // divide current level by 3 and ignore the remainder
        let (level_divided_by_x, _) = unsigned_div_rem(level_times_ten, 3);

        // square the integer portion to get xp required for next level
        let (xp_required_for_next_level) = pow(level_divided_by_x, 2);

        // amount of xp required is less than current xp, the adventurer/npc has leveled up
        let leveled_up = is_le(xp_required_for_next_level, xp);

        if (leveled_up == TRUE) {
            return (TRUE,);
        } else {
            return (FALSE,);
        }
    }

    func calculate_entity_level_boost{syscall_ptr: felt*, range_check_ptr}(damage: felt, entity_level: felt) -> (
        entity_level_damage: felt
    ) {
        let format_level_boost = damage * (90 + (entity_level * 10));
        let (entity_level_damage,_) = unsigned_div_rem(format_level_boost, 100); 
        return (entity_level_damage,);
    }

    func calculate_critical_damage{syscall_ptr: felt*, range_check_ptr}(damage: felt, critical: felt) -> (
        crtical_damage: felt
    ) {
        if (critical == TRUE) {
            let format_critical_damage = damage * 150;
            let (critical_damage,_) = unsigned_div_rem(format_critical_damage, 100); 
            return (critical_damage,);
        } else {
            return (damage,);
        }
    }
}
