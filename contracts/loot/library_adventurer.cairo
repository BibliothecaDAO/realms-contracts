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

from contracts.loot.library_item import LootItems

namespace Adventurer:
    func calculate_adventurer_stats{syscall_ptr : felt*, range_check_ptr}(
        weapon : Item,
        chest : Item,
        head : Item,
        waist : Item,
        feet : Item,
        hands : Item,
        neck : Item,
        ring : Item,
    ) -> (Agility, Attack, Armour, Wisdom, Vitality):
        alloc_locals

        # computed
        let (
            weapon_agility, weapon_attack, weapon_armour, weapon_wisdom, weapon_vitality
        ) = LootItems.calculate_item_stats(weapon)
        let (
            chest_agility, chest_attack, chest_armour, chest_wisdom, chest_vitality
        ) = LootItems.calculate_item_stats(chest)
        let (
            head_agility, head_attack, head_armour, head_wisdom, head_vitality
        ) = LootItems.calculate_item_stats(head)
        let (
            waist_agility, waist_attack, waist_armour, waist_wisdom, waist_vitality
        ) = LootItems.calculate_item_stats(waist)
        let (
            feet_agility, feet_attack, feet_armour, feet_wisdom, feet_vitality
        ) = LootItems.calculate_item_stats(feet)
        let (
            hands_agility, hands_attack, hands_armour, hands_wisdom, hands_vitality
        ) = LootItems.calculate_item_stats(hands)
        let (
            neck_agility, neck_attack, neck_armour, neck_wisdom, neck_vitality
        ) = LootItems.calculate_item_stats(neck)
        let (
            ring_agility, ring_attack, ring_armour, ring_wisdom, ring_vitality
        ) = LootItems.calculate_item_stats(ring)

        let agility = weapon_agility + chest_agility + head_agility + waist_agility + feet_agility + hands_agility + neck_agility + ring_agility
        let attack = weapon_attack + chest_attack + head_attack + waist_attack + feet_attack + hands_attack + neck_attack + ring_attack
        let armour = weapon_armour + chest_armour + head_armour + waist_armour + feet_armour + hands_armour + neck_armour + ring_armour
        let wisdom = weapon_wisdom + chest_wisdom + head_wisdom + waist_wisdom + feet_wisdom + hands_wisdom + neck_wisdom + ring_wisdom
        let vitality = weapon_vitality + chest_vitality + head_vitality + waist_vitality + feet_vitality + hands_vitality + neck_vitality + ring_vitality

        return (agility, attack, armour, wisdom, vitality)
    end
end
