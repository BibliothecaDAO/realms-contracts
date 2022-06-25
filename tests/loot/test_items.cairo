%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div
from contracts.settling_game.utils.game_structs import (
    BuildingsFood,
    BuildingsPopulation,
    BuildingsCulture,
)
from contracts.loot.library_item import LootItems
from contracts.loot.ItemConstants import ItemIds
from starkware.cairo.common.pow import pow

from contracts.loot.ItemConstants import ItemAgility, Item

@external
func test_base_fetch{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (agility) = LootItems.base_agility(ItemIds.Pendant)

    %{ print(ids.agility) %}
    return ()
end

@external
func test_calculate_item_stats{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (item : Item) = LootItems.calculate_item_stats(ItemIds.Pendant)

    let agility = item.Agility

    %{ print(ids.agility) %}

    return ()
end
