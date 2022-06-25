%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div
from contracts.loot.library_adventurer import Adventurer
from contracts.loot.ItemConstants import ItemIds
from starkware.cairo.common.pow import pow

from contracts.loot.ItemConstants import ItemAgility, Item

@external
func test_base_fetch{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (agility, attack, armour, wisdom, vitality) = Adventurer.calculate_adventurer_stats(
        ItemIds.Katana,
        ItemIds.DivineRobe,
        ItemIds.DemonCrown,
        ItemIds.BrightsilkSash,
        ItemIds.DivineSlippers,
        ItemIds.DivineGloves,
        ItemIds.Amulet,
        ItemIds.GoldRing,
    )

    %{ print('agility: ', ids.agility) %}
    %{ print('attack: ', ids.attack) %}
    %{ print('armour: ', ids.armour) %}
    %{ print('wisdom: ', ids.wisdom) %}
    %{ print('vitality: ', ids.vitality) %}
    return ()
end
