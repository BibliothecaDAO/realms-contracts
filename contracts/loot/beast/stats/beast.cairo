// SPDX-License-Identifier: MIT
//

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.registers import get_label_location

from contracts.loot.constants.beast import (
    BeastAttackType,
    BeastArmorType,
    BeastRank,
    BeastAttackLocation,
)
from contracts.loot.constants.rankings import ItemRank
from contracts.loot.constants.physics import MaterialDensity

namespace BeastStats {
    func get_attack_type_from_id{syscall_ptr: felt*, range_check_ptr}(beast_id: felt) -> (
        type: felt
    ) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + beast_id - 1],);

        labels:
        dw BeastAttackType.Phoenix;
        dw BeastAttackType.Griffin;
        dw BeastAttackType.Minotaur;
        dw BeastAttackType.Basilisk;
        dw BeastAttackType.Gnome;
        dw BeastAttackType.Giant;
        dw BeastAttackType.Yeti;
        dw BeastAttackType.Orc;
        dw BeastAttackType.Beserker;
        dw BeastAttackType.Ogre;
        dw BeastAttackType.Dragon;
        dw BeastAttackType.Vampire;
        dw BeastAttackType.Werewolf;
        dw BeastAttackType.Spider;
        dw BeastAttackType.Rat;
    }

    func get_armor_type_from_id{syscall_ptr: felt*, range_check_ptr}(beast_id: felt) -> (
        type: felt
    ) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + beast_id - 1],);

        labels:
        dw BeastArmorType.Phoenix;
        dw BeastArmorType.Griffin;
        dw BeastArmorType.Minotaur;
        dw BeastArmorType.Basilisk;
        dw BeastArmorType.Gnome;
        dw BeastArmorType.Giant;
        dw BeastArmorType.Yeti;
        dw BeastArmorType.Orc;
        dw BeastArmorType.Beserker;
        dw BeastArmorType.Ogre;
        dw BeastArmorType.Dragon;
        dw BeastArmorType.Vampire;
        dw BeastArmorType.Werewolf;
        dw BeastArmorType.Spider;
        dw BeastArmorType.Rat;
    }

    func get_rank_from_id{syscall_ptr: felt*, range_check_ptr}(beast_id: felt) -> (rank: felt) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + beast_id - 1],);

        labels:
        dw BeastRank.Phoenix;
        dw BeastRank.Griffin;
        dw BeastRank.Minotaur;
        dw BeastRank.Basilisk;
        dw BeastRank.Gnome;
        dw BeastRank.Giant;
        dw BeastRank.Yeti;
        dw BeastRank.Orc;
        dw BeastRank.Beserker;
        dw BeastRank.Ogre;
        dw BeastRank.Dragon;
        dw BeastRank.Vampire;
        dw BeastRank.Werewolf;
        dw BeastRank.Spider;
        dw BeastRank.Rat;
    }

    func get_attack_location_from_id{syscall_ptr: felt*, range_check_ptr}(beast_id: felt) -> (
        location: felt
    ) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + beast_id - 1],);

        labels:
        dw BeastAttackLocation.Phoenix;
        dw BeastAttackLocation.Griffin;
        dw BeastAttackLocation.Minotaur;
        dw BeastAttackLocation.Basilisk;
        dw BeastAttackLocation.Gnome;
        dw BeastAttackLocation.Giant;
        dw BeastAttackLocation.Yeti;
        dw BeastAttackLocation.Orc;
        dw BeastAttackLocation.Beserker;
        dw BeastAttackLocation.Ogre;
        dw BeastAttackLocation.Dragon;
        dw BeastAttackLocation.Vampire;
        dw BeastAttackLocation.Werewolf;
        dw BeastAttackLocation.Spider;
        dw BeastAttackLocation.Rat;
    }
}
