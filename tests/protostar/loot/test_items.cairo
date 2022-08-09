%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from contracts.loot.item.library_item import LootItems
from contracts.loot.item.constants import ItemIds, ItemAgility, Item
from starkware.cairo.common.pow import pow

from contracts.loot.item.library_statistics import Statistics

namespace TEST_ITEM:
    const Id = 1
    const Class = 1  # location for now
    const Slot = 1
    const Agility = 1
    const Attack = 1
    const Armour = 1
    const Wisdom = 1
    const Vitality = 1
    const Prefix = 1
    const Suffix = 1
    const Order = 1
    const Bonus = 1
    const Level = 1
    const Age = 1
    const XP = 1
end

@external
func test_base_fetch{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (agility) = Statistics.base_agility(ItemIds.Pendant)

    %{ print(ids.agility) %}
    return ()
end

@external
func test_item_slot{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (slot) = Statistics.item_slot(ItemIds.Pendant)

    %{ print(ids.slot) %}
    return ()
end

@external
func test_item_class{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (item_class) = Statistics.item_class(ItemIds.Pendant)

    %{ print(ids.item_class) %}
    return ()
end

@external
func test_calculate_item_stats{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let weapon = Item(
        TEST_ITEM.Id,
        TEST_ITEM.Class,
        TEST_ITEM.Slot,
        TEST_ITEM.Agility,
        TEST_ITEM.Attack,
        TEST_ITEM.Armour,
        TEST_ITEM.Wisdom,
        TEST_ITEM.Vitality,
        TEST_ITEM.Prefix,
        TEST_ITEM.Suffix,
        TEST_ITEM.Order,
        TEST_ITEM.Bonus,
        TEST_ITEM.Level,
        TEST_ITEM.Age,
        TEST_ITEM.XP,
    )

    let (Agility, Attack, Armour, Wisdom, Vitality) = LootItems.calculate_item_stats(weapon)

    %{ print(ids.Agility) %}

    return ()
end
