%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from starkware.cairo.common.pow import pow

from contracts.loot.constants.item import Item, ItemIds, ItemType, ItemSlot, ItemMaterial, State
from contracts.loot.constants.rankings import ItemRank
from contracts.loot.constants.combat import WeaponEfficacy
from contracts.loot.loot.stats.combat import CombatStats

@external
func test_weapon_vs_armor_efficacy{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    # Blade vs Metal inflicts minimal damage
    let (blade_vs_metal) = CombatStats.weapon_vs_armor_efficacy(
        ItemIds.Katana, ItemIds.OrnateChestplate
    )
    assert blade_vs_metal = WeaponEfficacy.Low
    # Blade vs Hide inflicts normal damage
    let (blade_vs_hide) = CombatStats.weapon_vs_armor_efficacy(
        ItemIds.ShortSword, ItemIds.HardLeatherArmor
    )
    assert blade_vs_hide = WeaponEfficacy.Medium
    # Blade vs Cloth inflicts high damage
    let (blade_vs_cloth) = CombatStats.weapon_vs_armor_efficacy(
        ItemIds.LongSword, ItemIds.DivineRobe
    )
    assert blade_vs_cloth = WeaponEfficacy.High

    # Bludgeon vs Metal inflicts normal damage
    let (bludgeon_vs_metal) = CombatStats.weapon_vs_armor_efficacy(
        ItemIds.Maul, ItemIds.HolyChestplate
    )
    assert bludgeon_vs_metal = WeaponEfficacy.Medium
    # Bludgeon vs Hide  inflicts high damage
    let (bludgeon_vs_hide) = CombatStats.weapon_vs_armor_efficacy(
        ItemIds.Mace, ItemIds.HardLeatherArmor
    )
    assert bludgeon_vs_hide = WeaponEfficacy.High
    # Bludgeon vs Cloth inflicts low damage
    let (bludgeon_vs_cloth) = CombatStats.weapon_vs_armor_efficacy(
        ItemIds.Warhammer, ItemIds.LinenRobe
    )
    assert bludgeon_vs_cloth = WeaponEfficacy.Low

    # Magic vs Metal  inflicts high damage
    let (magic_vs_metal) = CombatStats.weapon_vs_armor_efficacy(ItemIds.Grimoire, ItemIds.RingMail)
    assert magic_vs_metal = WeaponEfficacy.High
    # Magic vs Hide inflicts low damage
    let (magic_vs_hide) = CombatStats.weapon_vs_armor_efficacy(
        ItemIds.GraveWand, ItemIds.DragonskinArmor
    )
    assert magic_vs_hide = WeaponEfficacy.Low
    # Magic vs Cloth inflicts normal damage
    let (magic_vs_cloth) = CombatStats.weapon_vs_armor_efficacy(ItemIds.GhostWand, ItemIds.Shirt)
    assert magic_vs_cloth = WeaponEfficacy.Medium

    return ()
end

@external
func test_calculate_damage{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    # Greatness 20 Katana vs Greatness 0 Robe (gg)
    # TODO: This needs to use items instead of just itemIds since ItemIds don't inherently have a greatness

    # Create a greatness 20 katana
    let g20_katana = Item(
        ItemIds.Katana,
        ItemSlot.Katana,
        ItemType.Katana,
        ItemMaterial.Katana,
        ItemRank.Katana,
        1,
        1,
        1,
        20,
        1,
        1,
        0,
        0,
    )

    let g0_shirt = Item(
        ItemIds.Shirt,
        ItemSlot.Shirt,
        ItemType.Shirt,
        ItemMaterial.Shirt,
        ItemRank.Shirt,
        1,
        1,
        1,
        0,
        1,
        1,
        0,
        0,
    )

    let (g20_katana_vs_g0_robe) = CombatStats.calculate_damage(g20_katana, g0_shirt)
    assert g20_katana_vs_g0_robe = 200

    return ()
end
