%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from starkware.cairo.common.pow import pow

from contracts.loot.constants.item import (
    ItemIds,
    ItemSlot,
    ItemType,
    ItemMaterial
)
from contracts.loot.constants.rankings import ItemRank
from contracts.loot.contracts.stats.item import Statistics

@external
func test_item_slot{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (slot) = Statistics.item_slot(ItemIds.WoolGloves)
    assert slot = ItemSlot.WoolGloves

    return ()
end

@external
func test_item_type{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (typea) = Statistics.item_type(ItemIds.GraveWand)
    assert typea = ItemType.GraveWand

    let (typeb) = Statistics.item_type(ItemIds.LinenHood)
    assert typeb = ItemType.LinenHood

    let (typeb) = Statistics.item_type(ItemIds.HeavyGloves)
    assert typeb = ItemType.HeavyGloves

    return ()
end

@external
func test_item_material{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (typea) = Statistics.item_material(ItemIds.PlatinumRing)
    assert typea = ItemMaterial.PlatinumRing

    let (typeb) = Statistics.item_material(ItemIds.DemonhideBelt)
    assert typeb = ItemMaterial.DemonhideBelt

    let (typeb) = Statistics.item_material(ItemIds.OrnateGauntlets)
    assert typeb = ItemMaterial.OrnateGauntlets

    return ()
end

@external
func test_item_rank{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (ranka) = Statistics.item_rank(ItemIds.GoldRing)
    assert ranka = ItemRank.GoldRing

    let (rankb) = Statistics.item_rank(ItemIds.DragonsCrown)
    assert rankb = ItemRank.DragonsCrown

    let (rankc) = Statistics.item_rank(ItemIds.ChainGloves)
    assert rankc = ItemRank.ChainGloves

    return ()
end

