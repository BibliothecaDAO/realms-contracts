# BUILDINGS LIBRARY
#   functions for
#
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.registers import get_label_location

from contracts.loot.ItemConstants import ItemAgility, Item, ItemSlot, ItemClass

from contracts.loot.library_statistics import Statistics

namespace LootItems:
    func calculate_item_stats{syscall_ptr : felt*, range_check_ptr}(item : Item) -> (
        Agility, Attack, Armour, Wisdom, Vitality
    ):
        alloc_locals

        # computed
        let (Agility) = Statistics.base_agility(item.Id)
        let (Attack) = Statistics.base_attack(item.Id)
        let (Armour) = Statistics.base_armour(item.Id)
        let (Wisdom) = Statistics.base_wisdom(item.Id)
        let (Vitality) = Statistics.base_vitality(item.Id)

        # TODO: ADD Dynamic
        # let (Prefix) = base_agility(item_id)
        # let (Suffix) = base_agility(item_id)
        # let (Order) = base_agility(item_id)
        # let (Bonus) = base_agility(item_id)

        return (Agility, Attack, Armour, Wisdom, Vitality)
    end
end
