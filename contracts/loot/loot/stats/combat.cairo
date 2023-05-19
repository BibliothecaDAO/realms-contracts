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
from contracts.loot.utils.constants import MAX_CRITICAL_HIT_CHANCE

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
        strength: felt,
        luck: felt,
        rnd: felt,
    ) -> (damage: felt) {
        alloc_locals;

        const rank_ceiling = 6;
        const minimum_damage = 3;

        // use weapon rank and greatness to give every item a damage rating of 0-100
        // TODO: add item weight into damage calculation
        let attack_hp = (rank_ceiling - attack_rank) * attack_greatness;

        // use armor rank and greatness to give armor a defense rating of 0-100
        // TODO: add item weight into strength calculation
        let defense_hp = (rank_ceiling - armor_rank) * armor_greatness;

        // if armor hitpoints is less than weapon hitpoints, then damage was dealt
        let dealt_below_minimum_damage = is_le_felt(defense_hp + minimum_damage, attack_hp);
        if (dealt_below_minimum_damage == TRUE) {
            // then we use that for our weapon damage
            tempvar temp_weapon_damage = attack_hp - defense_hp;
        } else {
            // if base damage is 0 or below, use minimum damage of 3
            tempvar temp_weapon_damage = minimum_damage;
        }

        let weapon_damage = temp_weapon_damage;

        // account for elemental effectiveness
        let (attack_effectiveness) = weapon_vs_armor_efficacy(attack_type, armor_type);
        let (total_weapon_damage) = get_attack_effectiveness(attack_effectiveness, weapon_damage);

        // @distracteddev: calculate whether hit is critical and add luck
        // 0-9 = 1 in 6, 10-19 = 1 in 5, 20-29 = 1 in 4, 30-39 = 1 in 3, 40-46 = 1 in 2
        // formula = damage * (1.5 * rand(6 - (luck/10))

        let (critical_hit_chance, _) = unsigned_div_rem(luck, 10);

        // there is no implied cap on item greatness so luck is unbound
        // but for purposes of critical damage calculation, the max critical hit chance is 5
        let critical_hit_chance_within_range = is_le(critical_hit_chance, MAX_CRITICAL_HIT_CHANCE);
        // if the critical hit chance is 5 or less
        if (critical_hit_chance_within_range == TRUE) {
            // use the unalterted critical hit chance
            tempvar temp_critical_hit_chance = critical_hit_chance;
        } else {
            // if it is above 5, then set it to 5
            tempvar temp_critical_hit_chance = MAX_CRITICAL_HIT_CHANCE;
        }
        let critical_hit_chance = temp_critical_hit_chance;

        let (_, critical_rand) = unsigned_div_rem(rnd, (6 - critical_hit_chance));
        let critical_hit = is_le(critical_rand, 0);
        // @distracteddev: provide some multi here with adventurer level: e.g. damage + (1 + ((1 - level) * 0.1))
        let (adventurer_level_damage) = calculate_entity_level_boost(
            total_weapon_damage, entity_level + strength
        );
        let (critical_damage_dealt) = calculate_critical_damage(
            adventurer_level_damage, critical_hit, rnd
        );
        return (critical_damage_dealt,);
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
            attack_type,
            weapon.Rank,
            weapon.Greatness,
            armor_type,
            armor.Rank,
            armor.Greatness,
            unpacked_adventurer.Level,
            unpacked_adventurer.Strength,
            unpacked_adventurer.Luck,
            rnd,
        );

        // return damage
        return (damage_dealt,);
    }

    // Calculates damage dealt from a beast by converting beast into a Loot weapon and calling calculate_damage_from_weapon
    func calculate_damage_from_beast{syscall_ptr: felt*, range_check_ptr}(
        beast: Beast, armor: Item, critical_damage_rnd: felt, adventurer_level: felt
    ) -> (damage: felt) {
        alloc_locals;

        // Get beast attack type
        let (attack_type) = BeastStats.get_attack_type_from_id(beast.Id);

        // beast luck will scale with adventurer level
        let beast_luck = adventurer_level;

        // if adventurer doesn't have armor in the location being attacked
        if (armor.Id == 0) {
            // we use generic armor which will result in max damage for adventurer
            return calculate_damage(
                attack_type,
                beast.Rank,
                beast.Level,
                Type.Armor.generic,
                armor.Rank,
                armor.Greatness,
                1,
                0,
                beast_luck,
                critical_damage_rnd,
            );
        } else {
            let (armor_type) = ItemStats.item_type(armor.Id);
            // pass details of attack and armor to core damage calculation function
            // @distracteddev: added param to change based on adventurer level
            // return damage
            return calculate_damage(
                attack_type,
                beast.Rank,
                beast.Level,
                armor_type,
                armor.Rank,
                armor.Greatness,
                1,
                0,
                beast_luck,
                critical_damage_rnd,
            );
        }
    }

    // Calculates damage dealt to a beast by using equipped Loot weapon and calling calculate_damage_from_weapon
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
                Type.Weapon.generic,
                weapon.Rank,
                1,
                armor_type,
                beast.Rank,
                beast.Level,
                unpacked_adventurer.Level,
                unpacked_adventurer.Strength,
                unpacked_adventurer.Luck,
                rnd,
            );
        } else {
            // return damage
            return calculate_damage(
                weapon.Type,
                weapon.Rank,
                weapon.Greatness,
                armor_type,
                beast.Rank,
                beast.Level,
                unpacked_adventurer.Level,
                unpacked_adventurer.Strength,
                unpacked_adventurer.Luck,
                rnd,
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
                obstacle.Type,
                obstacle.Rank,
                obstacle.Greatness,
                Type.Armor.generic,
                armor.Rank,
                armor.Greatness,
                1,
                0,
                0,
                1,
            );
        } else {
            // return damage dealt
            return calculate_damage(
                obstacle.Type,
                obstacle.Rank,
                obstacle.Greatness,
                armor_type,
                armor.Rank,
                armor.Greatness,
                1,
                0,
                0,
                1,
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
        let (level_divided_by_x, _) = unsigned_div_rem(level_times_ten, 5);

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

    // @notice Calculates the damage boost based on the input damage and entity level.
    // @dev This function is used to calculate the damage boost for an entity based on its level.
    // @param damage The base damage.
    // @param entity_level The level of the entity.
    // @return entity_level_damage The calculated damage after applying the level boost.
    func calculate_entity_level_boost{syscall_ptr: felt*, range_check_ptr}(
        damage: felt, entity_level: felt
    ) -> (entity_level_damage: felt) {
        let format_level_boost = damage * (90 + (entity_level * 10));
        let (entity_level_damage, _) = unsigned_div_rem(format_level_boost, 100);
        return (entity_level_damage,);
    }

    // @notice Calculates the critical damage based on the original damage, critical hit flag, and random number.
    // @dev This function is used to calculate the damage dealt when a critical hit occurs..
    // @param original_damage The original damage dealt.
    // @param critical_hit Flag indicating whether a critical hit occurred (TRUE for critical hit, FALSE otherwise).
    // @param rnd Random number used to determine the damage boost multiplier.
    // @return critical_damage The calculated critical damage.
    func calculate_critical_damage{syscall_ptr: felt*, range_check_ptr}(
        original_damage: felt, critical_hit: felt, rnd: felt
    ) -> (crtical_damage: felt) {
        // if adventurer dealt critical hit
        if (critical_hit == TRUE) {
            // divide the damage by four to get base damage boost
            let (damage_boost_base, _) = unsigned_div_rem(original_damage, 4);

            // damage multplier is 1-4 which will equate to a 25-100% damage boost
            let (_, damage_multplier) = unsigned_div_rem(rnd, 4);

            // multiply base damage boost (25% of original damage) by damage multiplier (1-4)
            let critical_hit_damage_bonus = damage_boost_base * (damage_multplier + 1);

            // add damage multplier to original damage
            let critical_damage = original_damage + critical_hit_damage_bonus;

            // return critical damage
            return (critical_damage,);
        } else {
            // if no critical hit, return original damage
            return (original_damage,);
        }
    }
}
