# SPDX-License-Identifier: MIT
#

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.registers import get_label_location

from contracts.loot.constants.item import Type
from contracts.loot.constants.combat import WeaponEfficacy
from contracts.loot.contracts.stats.item import ItemStats

namespace CombatStats:
    func weapon_vs_armor_efficacy{syscall_ptr : felt*, range_check_ptr}(weapon_item_id : felt, armor_item_id : felt) -> (class : felt):
        alloc_locals

        let (weapon_type) = ItemStats.item_type(weapon_item_id)
        let (armor_type) = ItemStats.item_type(armor_item_id)

        let (blade_location) = get_label_location(blade_efficacy)
        let (bludgeon_location) = get_label_location(bludgeon_efficacy)
        let (magic_location) = get_label_location(magic_efficacy)

        if weapon_type == Type.Weapon.blade:
            [ap] = blade_location; ap++
        else:
            if weapon_type == Type.Weapon.bludgeon:
                [ap] = bludgeon_location; ap++
            else:
                if weapon_type == Type.Weapon.magic:
                    [ap] = magic_location; ap++
                end
            end
        end

        let label_location = [ap - 1]
        return ([label_location + armor_type - Type.Armor.generic])

        blade_efficacy:
        dw WeaponEfficacy.Low
        dw WeaponEfficacy.Low
        dw WeaponEfficacy.Medium
        dw WeaponEfficacy.High

        bludgeon_efficacy:
        dw WeaponEfficacy.Low
        dw WeaponEfficacy.Medium
        dw WeaponEfficacy.High
        dw WeaponEfficacy.Low

        magic_efficacy:
        dw WeaponEfficacy.Low
        dw WeaponEfficacy.High
        dw WeaponEfficacy.Low
        dw WeaponEfficacy.Medium
    end
end
