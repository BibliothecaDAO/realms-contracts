%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div
from contracts.loot.library_adventurer import Adventurer
from contracts.loot.ItemConstants import ItemIds
from starkware.cairo.common.pow import pow

from contracts.loot.ItemConstants import ItemAgility, Item

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
    let chest = Item(
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
    let head = Item(
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
    let waist = Item(
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
    let feet = Item(
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
    let hands = Item(
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
    let neck = Item(
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
    let ring = Item(
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

    let (agility, attack, armour, wisdom, vitality) = Adventurer.calculate_adventurer_stats(
        weapon, chest, head, waist, feet, hands, neck, ring
    )

    %{ print('agility: ', ids.agility) %}
    %{ print('attack: ', ids.attack) %}
    %{ print('armour: ', ids.armour) %}
    %{ print('wisdom: ', ids.wisdom) %}
    %{ print('vitality: ', ids.vitality) %}

    return ()
end
