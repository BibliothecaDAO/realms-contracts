%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from starkware.cairo.common.pow import pow

from contracts.loot.constants.item import ItemIds, ItemSlot, ItemType, ItemMaterial, Material
from contracts.loot.constants.rankings import ItemRank
from contracts.loot.loot.stats.item import ItemStats
from contracts.loot.constants.physics import MaterialDensity

@external
func test_item_slot{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (slot) = ItemStats.item_slot(ItemIds.WoolGloves)
    assert slot = ItemSlot.WoolGloves

    return ()
end

@external
func test_item_type{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (typea) = ItemStats.item_type(ItemIds.GraveWand)
    assert typea = ItemType.GraveWand

    let (typeb) = ItemStats.item_type(ItemIds.LinenHood)
    assert typeb = ItemType.LinenHood

    let (typeb) = ItemStats.item_type(ItemIds.HeavyGloves)
    assert typeb = ItemType.HeavyGloves

    return ()
end

@external
func test_item_material{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (typea) = ItemStats.item_material(ItemIds.PlatinumRing)
    assert typea = ItemMaterial.PlatinumRing

    let (typeb) = ItemStats.item_material(ItemIds.DemonhideBelt)
    assert typeb = ItemMaterial.DemonhideBelt

    let (typeb) = ItemStats.item_material(ItemIds.OrnateGauntlets)
    assert typeb = ItemMaterial.OrnateGauntlets

    return ()
end

@external
func test_item_rank{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (ranka) = ItemStats.item_rank(ItemIds.GoldRing)
    assert ranka = ItemRank.GoldRing

    let (rankb) = ItemStats.item_rank(ItemIds.DragonsCrown)
    assert rankb = ItemRank.DragonsCrown

    let (rankc) = ItemStats.item_rank(ItemIds.ChainGloves)
    assert rankc = ItemRank.ChainGloves

    return ()
end

@external
func test_material_density{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (densitya) = ItemStats.material_density(Material.Metal.generic)
    assert densitya = MaterialDensity.Metal.generic

    let (densityb) = ItemStats.material_density(Material.Metal.gold)
    assert densityb = MaterialDensity.Metal.gold

    let (densityc) = ItemStats.material_density(Material.Cloth.brightsilk)
    assert densityc = MaterialDensity.Cloth.brightsilk

    let (densityd) = ItemStats.material_density(Material.Biotic.Demon.hide)
    assert densityd = MaterialDensity.Biotic.Demon.hide

    let (densitye) = ItemStats.material_density(Material.Biotic.Human.bones)
    assert densitye = MaterialDensity.Biotic.Human.bones

    let (densityf) = ItemStats.material_density(Material.Wood.Hard.walnut)
    assert densityf = MaterialDensity.Wood.Hard.walnut

    let (densityg) = ItemStats.material_density(Material.Wood.Soft.yew)
    assert densityg = MaterialDensity.Wood.Soft.yew

    return ()
end
