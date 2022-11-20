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
    BeastType,
    BeastRank
)
from contracts.loot.constants.rankings import ItemRank
from contracts.loot.constants.physics import MaterialDensity

namespace BeastStats {

    func get_type_from_id{syscall_ptr: felt*, range_check_ptr}(beast_id: felt) -> (type: felt) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + beast_id - 1],);

        labels:
        dw BeastType.Phoenix;
        dw BeastType.Griffin;
        dw BeastType.Minotaur;
        dw BeastType.Basilisk;
        dw BeastType.Wraith;
        dw BeastType.Ghoul;
        dw BeastType.Goblin;
        dw BeastType.Skeleton;
        dw BeastType.Giant;
        dw BeastType.Yeti;
        dw BeastType.Orc;
        dw BeastType.Beserker;
        dw BeastType.Ogre;
        dw BeastType.Dragon;
        dw BeastType.Vampire;
        dw BeastType.Werewolf;
        dw BeastType.Spider;
        dw BeastType.Rat;
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
        dw BeastRank.Wraith;
        dw BeastRank.Ghoul;
        dw BeastRank.Goblin;
        dw BeastRank.Skeleton;
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

}
