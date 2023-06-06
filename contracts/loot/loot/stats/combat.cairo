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
from contracts.loot.constants.combat import WeaponEfficacy
from contracts.loot.beast.stats.beast import BeastStats
from contracts.loot.beast.library import BeastLib
from contracts.loot.loot.stats.item import ItemStats
from contracts.loot.constants.adventurer import AdventurerState
from contracts.loot.constants.beast import Beast, BeastStatic, BeastDynamic
from contracts.loot.constants.obstacle import Obstacle, ObstacleUtils
from contracts.loot.utils.constants import (
    MAX_CRITICAL_HIT_CHANCE,
    ITEM_RANK_MAX,
)

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

    // @title Get Elemental Bonus
    // @dev Calculates the damage modifier based on the attack and armor types.
    //
    // @param attack_type The type of the attacking element.
    // @param armor_type The type of the defending element.
    // @param original_damage The original damage value.
    // @return damage The modified damage value based on the attack and armor types.
    func adjust_damage_for_elemental{syscall_ptr: felt*, range_check_ptr}(
        attack_type: felt, armor_type: felt, original_damage: felt
    ) -> (damage: felt) {
        alloc_locals;

        // Use 50% of the original damage as our damage modifier which will give us
        // access to -50% (ineffective elemental), 100% (neutral), 150% (effective elemental)
        let (damage_boost_base, _) = unsigned_div_rem(original_damage, 2);

        // get attack effectiveness
        let (attack_effectiveness) = weapon_vs_armor_efficacy(attack_type, armor_type);

        // if weapon is ineffective against armor
        if (attack_effectiveness == WeaponEfficacy.Low) {
            // return half the damage
            let half_damage = original_damage - damage_boost_base;
            return (half_damage,);
        }

        // if weapon is neutral against armor
        if (attack_effectiveness == WeaponEfficacy.Medium) {
            // return original damage
            return (original_damage,);
        }

        // if weapon is effective against armor
        if (attack_effectiveness == WeaponEfficacy.High) {
            // return damage + 50%
            let one_and_a_half_damage = original_damage + damage_boost_base;
            return (one_and_a_half_damage,);
        }

        // fall through, return original damage
        return (original_damage,);
    }

    // @title Name Prefix_1 Match Bonus Calculation
    // @dev Calculates the damage bonus based on a match between attack_name_prefix1 and armor_name_prefix1.
    // @param original_damage The original damage value.
    // @param damage_multiplier The damage multiplier.
    // @param attack_name_prefix1 The name prefix 1 of the attack.
    // @param armor_name_prefix1 The name prefix 1 of the armor.
    // @return damage_bonus The calculated damage bonus.
    func get_name_prefix1_match_bonus{syscall_ptr: felt*, range_check_ptr}(
        original_damage: felt,
        damage_multiplier: felt,
        attack_name_prefix1: felt,
        armor_name_prefix1: felt,
    ) -> (damage_bonus: felt) {
        alloc_locals;

        let no_damage_bonus = 0;
        // if weapon doesn't have a prefix1
        if (attack_name_prefix1 == 0) {
            // return 0
            return (no_damage_bonus,);
        }

        // Odds of a prefix1 (namePrefix) match is 1/68
        if (attack_name_prefix1 == armor_name_prefix1) {
            // Apply a significant damage boost of 4x, 5x, 6x, 7x
            let name_prefix1_boost = original_damage * (damage_multiplier + 4);
            return (name_prefix1_boost,);
        }

        return (no_damage_bonus,);
    }

    // @title Name Prefix_2 Match Bonus Calculation
    // @dev Calculates the damage bonus based on a match between attack_name_prefix2 and armor_name_prefix2.
    // @param original_damage The original damage value.
    // @param damage_multiplier The damage multiplier.
    // @param attack_name_prefix2 The name prefix 2 of the attack.
    // @param armor_name_prefix2 The name prefix 2 of the armor.
    // @return damage_bonus The calculated damage bonus.
    func get_name_prefix2_match_bonus{syscall_ptr: felt*, range_check_ptr}(
        original_damage: felt,
        damage_multiplier: felt,
        attack_name_prefix2: felt,
        armor_name_prefix2: felt,
    ) -> (damage_bonus: felt) {
        alloc_locals;

        let no_damage_bonus = 0;
        // if weapon doesn't have a prefix2
        if (attack_name_prefix2 == 0) {
            // return 0
            return (no_damage_bonus,);
        }

        // Odds of a prefix2 match (nameSuffix) match is 1/18
        if (attack_name_prefix2 == armor_name_prefix2) {
            // Apply a less significant damage boost of 1.25x, 1.5x, 1.75x, 2x

            // Divide the original damage by 4 to get a 25% base boost
            let (damage_boost_base, _) = unsigned_div_rem(original_damage, 4);

            // Multiply the quarter of the original damage by a multiplier (1-4 inclusive)
            let name_prefix2_bonus = damage_boost_base * (damage_multiplier + 1);

            return (name_prefix2_bonus,);
        }

        return (no_damage_bonus,);
    }

    // @title Name Match Bonus Calculation
    // @dev Calculates the total damage bonus based on matches between attack_name_prefix1, attack_name_prefix2,
    // armor_name_prefix1, and armor_name_prefix2.
    // @param original_damage The original damage value.
    // @param attack_name_prefix1 The name prefix 1 of the attack.
    // @param attack_name_prefix2 The name prefix 2 of the attack.
    // @param armor_name_prefix1 The name prefix 1 of the armor.
    // @param armor_name_prefix2 The name prefix 2 of the armor.
    // @param rnd A random value used for calculations.
    // @return damage_bonus The calculated total damage bonus.
    func get_name_match_bonus{syscall_ptr: felt*, range_check_ptr}(
        original_damage: felt,
        attack_name_prefix1: felt,
        attack_name_prefix2: felt,
        armor_name_prefix1: felt,
        armor_name_prefix2: felt,
        rnd: felt,
    ) -> (damage_bonus: felt) {
        alloc_locals;

        let (_, damage_multplier) = unsigned_div_rem(rnd, 4);

        let (name_prefix1_bonus) = get_name_prefix1_match_bonus(
            original_damage, damage_multplier, attack_name_prefix1, armor_name_prefix1
        );

        let (name_prefix2_bonus) = get_name_prefix2_match_bonus(
            original_damage, damage_multplier, attack_name_prefix2, armor_name_prefix2
        );

        let total_name_bonus = name_prefix1_bonus + name_prefix2_bonus;

        return (total_name_bonus,);
    }

    // @title Is Critical Hit
    // @dev Determines whether a hit is a critical hit based on luck and random values.
    // @param original_damage The original damage value.
    // @param luck The luck attribute of the entity.
    // @param rnd A random value used for calculations.
    // @return is_critical_hit A boolean indicating whether the hit is a critical hit.
    func is_critical_hit{syscall_ptr: felt*, range_check_ptr}(luck: felt, rnd: felt) -> (
        is_critical_hit: felt
    ) {
        alloc_locals;
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
        return (critical_hit,);
    }

    // @title Get Critical Hit Bonus
    // @dev Calculates the damage bonus for a critical hit based on luck and random values.
    // @param original_damage The original damage value.
    // @param luck The luck attribute of the entity.
    // @param rnd A random value used for calculations.
    // @return damage_bonus The calculated damage bonus for a critical hit.
    func get_critical_hit_bonus{syscall_ptr: felt*, range_check_ptr}(
        original_damage: felt, luck: felt, rnd: felt
    ) -> (damage_bonus: felt) {
        alloc_locals;

        let (is_critical_hit_) = is_critical_hit(luck, rnd);
        if (is_critical_hit_ == TRUE) {
            let (critical_damage_dealt) = calculate_critical_damage(original_damage, rnd);
            return (critical_damage_dealt,);
        }

        return (0,);
    }

    // @title Attack Minus Defense
    // @notice This function calculates the damage dealt in a combat scenario based on the attack and defense hit points (HP) of two entities.
    // @dev If the defense HP is greater than the attack HP, this function uses adventurer level as the minimum damage dealt
    // @param attack_hp The hit points of the attacking entity.
    // @param defense_hp The hit points of the defending entity.
    // @param adventurer_level The level of the adventurer.
    // @return damage The amount of damage dealt in the combat scenario.
    func attack_minus_defense{syscall_ptr: felt*, range_check_ptr}(
        attack_hp: felt, defense_hp: felt, adventurer_level: felt
    ) -> (damage: felt) {
        alloc_locals;

        // if defense HP + adventurer level is less than or equal to attack hp
        // the reason we add adventurer_level is to prevent a situation in which
        // adventurer_level (minimum damage) would result in higher damage than attack minus defense
        let dealt_below_minimum_damage = is_le_felt(defense_hp + adventurer_level, attack_hp);
        if (dealt_below_minimum_damage == TRUE) {
            // use the difference for damage dealt
            let damage_dealt = attack_hp - defense_hp;
            return (damage_dealt,);
        }

        // if the attack HP is lower than the defense HP, use adventurer level as minimum
        return (adventurer_level,);
    }

    // @title Core damage calculation
    // @dev Calculates the damage inflicted by an attack based on various parameters.
    // @param attack_type The type of attack.
    // @param attack_rank The rank of the attacking item.
    // @param attack_greatness The greatness of the attacking item.
    // @param attack_name_prefix1 The name prefix 1 of the attacking item.
    // @param attack_name_prefix2 The name prefix 2 of the attacking item.
    // @param armor_type The type of armor.
    // @param armor_rank The rank of the armor.
    // @param armor_greatness The greatness of the armor.
    // @param armor_name_prefix1 The name prefix 1 of the armor.
    // @param armor_name_prefix2 The name prefix 2 of the armor.
    // @param entity_level The level of the entity.
    // @param strength The strength of the entity.
    // @param luck The luck of the entity.
    // @param rnd A random value used for calculations.
    // @return damage The calculated damage.
    func calculate_damage{syscall_ptr: felt*, range_check_ptr}(
        attack_type: felt,
        attack_rank: felt,
        attack_greatness: felt,
        attack_name_prefix1: felt,
        attack_name_prefix2: felt,
        armor_type: felt,
        armor_rank: felt,
        armor_greatness: felt,
        armor_name_prefix1: felt,
        armor_name_prefix2: felt,
        entity_level: felt,
        strength: felt,
        luck: felt,
        rnd: felt,
    ) -> (damage: felt) {
        alloc_locals;

        // get base damage based on rank and greatness of attack weapon and armor

        // raw attack HP
        let raw_attack_hp = (ITEM_RANK_MAX - attack_rank) * attack_greatness;

        // raw defense HP
        let raw_defense_hp = (ITEM_RANK_MAX - armor_rank) * armor_greatness;

        // base damage is attack HP minus defense HP with a minimum of entity/adventurer level
        let (base_damage) = attack_minus_defense(raw_attack_hp, raw_defense_hp, entity_level);

        // apply elemental bonus to raw attack hp
        // if we applied it to base_damage above, it significantly weaknes
        // the elemental effect
        let (base_damage_with_elemental) = adjust_damage_for_elemental(
            attack_type, armor_type, raw_attack_hp
        );

        // get damage bonus based on item and armor names
        let (name_damage_bonus) = get_name_match_bonus(
            raw_attack_hp,
            attack_name_prefix1,
            attack_name_prefix2,
            armor_name_prefix1,
            armor_name_prefix2,
            rnd,
        );

        // get damage bonus for critical hit
        let (critical_hit_bonus) = get_critical_hit_bonus(raw_attack_hp, luck, rnd);

        // get damage bonus for entity stats (level and strength)
        let (entity_level_bonus) = get_entity_level_bonus(raw_attack_hp, entity_level + strength);

        // add bonuses to base damage
        let final_damage = base_damage_with_elemental + critical_hit_bonus + name_damage_bonus +
            entity_level_bonus;

        // return resulting damage
        return (final_damage,);
    }

    // @title Calculate Damage from Weapon
    // @dev Calculates the damage inflicted by a weapon against a specific piece of armor.
    // @param weapon The attacking weapon.
    // @param armor The defending armor.
    // @param unpacked_adventurer The state of the adventurer.
    // @param rnd A random value used for calculations.
    // @return damage The calculated damage.
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
            weapon.Prefix_1,
            weapon.Prefix_2,
            armor_type,
            armor.Rank,
            armor.Greatness,
            armor.Prefix_1,
            armor.Prefix_2,
            unpacked_adventurer.Level,
            unpacked_adventurer.Strength,
            unpacked_adventurer.Luck,
            rnd,
        );

        // return damage
        return (damage_dealt,);
    }

    // @title Calculate Damage from Beast
    // @dev Calculates the damage inflicted by a beast by converting it into a Loot weapon.
    // @param beast The attacking beast.
    // @param armor The defending armor.
    // @param critical_damage_rnd A random value used for calculating critical damage.
    // @param adventurer_level The level of the adventurer.
    // @return damage The calculated damage.
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
                beast.Prefix_1,
                beast.Prefix_2,
                Type.Armor.generic,
                armor.Rank,
                armor.Greatness,
                armor.Prefix_1,
                armor.Prefix_2,
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
                beast.Prefix_1,
                beast.Prefix_2,
                armor_type,
                armor.Rank,
                armor.Greatness,
                armor.Prefix_1,
                armor.Prefix_2,
                1,
                0,
                beast_luck,
                critical_damage_rnd,
            );
        }
    }

    // @title Calculate Damage to Beast
    // @dev Calculates the damage inflicted to a beast using an equipped Loot weapon.
    // @param beast The defending beast.
    // @param weapon The attacking weapon.
    // @param unpacked_adventurer The state of the adventurer.
    // @param rnd A random value used for calculations.
    // @return damage The calculated damage.
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
                0,
                0,
                armor_type,
                beast.Rank,
                beast.Level,
                beast.Prefix_1,
                beast.Prefix_2,
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
                weapon.Prefix_1,
                weapon.Prefix_2,
                armor_type,
                beast.Rank,
                beast.Level,
                beast.Prefix_1,
                beast.Prefix_2,
                unpacked_adventurer.Level,
                unpacked_adventurer.Strength,
                unpacked_adventurer.Luck,
                rnd,
            );
        }
    }

    // @title Calculate Damage from Obstacle
    // @dev Calculates the damage inflicted by an obstacle against a specific piece of armor.
    // @param obstacle The attacking obstacle.
    // @param armor The defending armor.
    // @return damage The calculated damage.
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
                obstacle.Prefix_1,
                obstacle.Prefix_2,
                Type.Armor.generic,
                armor.Rank,
                armor.Greatness,
                armor.Prefix_1,
                armor.Prefix_2,
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
                obstacle.Prefix_1,
                obstacle.Prefix_2,
                armor_type,
                armor.Rank,
                armor.Greatness,
                armor.Prefix_1,
                armor.Prefix_2,
                1,
                0,
                0,
                1,
            );
        }
    }

    // @title Calculate XP Earned
    // @dev Calculates the amount of XP earned based on the rank and level.
    // @param rank The rank of the entity.
    // @param level The level of the entity.
    // @return xp_earned The amount of XP earned.
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
    func get_entity_level_bonus{syscall_ptr: felt*, range_check_ptr}(
        damage: felt, entity_level: felt
    ) -> (entity_level_damage: felt) {
        // @distracteddev: provide some multi here with adventurer level: e.g. damage + (1 + ((1 - level) * 0.1))
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
        original_damage: felt, rnd: felt
    ) -> (crtical_damage_bonus: felt) {
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
    }
}
