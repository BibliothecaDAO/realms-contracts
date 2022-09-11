%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from starkware.cairo.common.pow import pow

from contracts.loot.constants.item import ItemIds
from contracts.loot.constants.combat import WeaponEfficacy
from contracts.loot.contracts.stats.combat import CombatStats

@external
func test_weapon_vs_armor_efficacy{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (val1) = CombatStats.weapon_vs_armor_efficacy(ItemIds.Katana, ItemIds.OrnateChestplate)
    assert val1 = WeaponEfficacy.Low

    let (val2) = CombatStats.weapon_vs_armor_efficacy(ItemIds.Maul, ItemIds.DemonHusk)
    assert val2 = WeaponEfficacy.High

    let (val3) = CombatStats.weapon_vs_armor_efficacy(ItemIds.GraveWand, ItemIds.LinenShoes)
    assert val3 = WeaponEfficacy.Medium

    return ()
end

