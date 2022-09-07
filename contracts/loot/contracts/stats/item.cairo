%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.registers import get_label_location

from contracts.loot.constants.item import (
    ItemIds,
    ItemSlot,
    ItemType,
    ItemMaterial
)

namespace Statistics:
    func item_slot{syscall_ptr : felt*, range_check_ptr}(item_id : felt) -> (slot : felt):
        alloc_locals

        let (label_location) = get_label_location(labels)
        return ([label_location + item_id - 1])

        labels:
        dw ItemSlot.Pendant
        dw ItemSlot.Necklace
        dw ItemSlot.Amulet
        dw ItemSlot.SilverRing
        dw ItemSlot.BronzeRing
        dw ItemSlot.PlatinumRing
        dw ItemSlot.TitaniumRing
        dw ItemSlot.GoldRing
        dw ItemSlot.GhostWand
        dw ItemSlot.GraveWand
        dw ItemSlot.BoneWand
        dw ItemSlot.Wand
        dw ItemSlot.Grimoire
        dw ItemSlot.Chronicle
        dw ItemSlot.Tome
        dw ItemSlot.Book
        dw ItemSlot.DivineRobe
        dw ItemSlot.SilkRobe
        dw ItemSlot.LinenRobe
        dw ItemSlot.Robe
        dw ItemSlot.Shirt
        dw ItemSlot.Crown
        dw ItemSlot.DivineHood
        dw ItemSlot.SilkHood
        dw ItemSlot.LinenHood
        dw ItemSlot.Hood
        dw ItemSlot.BrightsilkSash
        dw ItemSlot.SilkSash
        dw ItemSlot.WoolSash
        dw ItemSlot.LinenSash
        dw ItemSlot.Sash
        dw ItemSlot.DivineSlippers
        dw ItemSlot.SilkSlippers
        dw ItemSlot.WoolShoes
        dw ItemSlot.LinenShoes
        dw ItemSlot.Shoes
        dw ItemSlot.DivineGloves
        dw ItemSlot.SilkGloves
        dw ItemSlot.WoolGloves
        dw ItemSlot.LinenGloves
        dw ItemSlot.Gloves
        dw ItemSlot.Katana
        dw ItemSlot.Falchion
        dw ItemSlot.Scimitar
        dw ItemSlot.LongSword
        dw ItemSlot.ShortSword
        dw ItemSlot.DemonHusk
        dw ItemSlot.DragonskinArmor
        dw ItemSlot.StuddedLeatherArmor
        dw ItemSlot.HardLeatherArmor
        dw ItemSlot.LeatherArmor
        dw ItemSlot.DemonCrown
        dw ItemSlot.DragonsCrown
        dw ItemSlot.WarCap
        dw ItemSlot.LeatherCap
        dw ItemSlot.Cap
        dw ItemSlot.DemonhideBelt
        dw ItemSlot.DragonskinBelt
        dw ItemSlot.StuddedLeatherBelt
        dw ItemSlot.HardLeatherBelt
        dw ItemSlot.LeatherBelt
        dw ItemSlot.DemonhideBoots
        dw ItemSlot.DragonskinBoots
        dw ItemSlot.StuddedLeatherBoots
        dw ItemSlot.HardLeatherBoots
        dw ItemSlot.LeatherBoots
        dw ItemSlot.DemonsHands
        dw ItemSlot.DragonskinGloves
        dw ItemSlot.StuddedLeatherGloves
        dw ItemSlot.HardLeatherGloves
        dw ItemSlot.LeatherGloves
        dw ItemSlot.Warhammer
        dw ItemSlot.Quarterstaff
        dw ItemSlot.Maul
        dw ItemSlot.Mace
        dw ItemSlot.Club
        dw ItemSlot.HolyChestplate
        dw ItemSlot.OrnateChestplate
        dw ItemSlot.PlateMail
        dw ItemSlot.ChainMail
        dw ItemSlot.RingMail
        dw ItemSlot.AncientHelm
        dw ItemSlot.OrnateHelm
        dw ItemSlot.GreatHelm
        dw ItemSlot.FullHelm
        dw ItemSlot.Helm
        dw ItemSlot.OrnateBelt
        dw ItemSlot.WarBelt
        dw ItemSlot.PlatedBelt
        dw ItemSlot.MeshBelt
        dw ItemSlot.HeavyBelt
        dw ItemSlot.HolyGreaves
        dw ItemSlot.OrnateGreaves
        dw ItemSlot.Greaves
        dw ItemSlot.ChainBoots
        dw ItemSlot.HeavyBoots
        dw ItemSlot.HolyGauntlets
        dw ItemSlot.OrnateGauntlets
        dw ItemSlot.Gauntlets
        dw ItemSlot.ChainGloves
        dw ItemSlot.HeavyGloves
    end

    func item_type{syscall_ptr : felt*, range_check_ptr}(item_id : felt) -> (type : felt):
        alloc_locals

        let (label_location) = get_label_location(labels)
        return ([label_location + item_id - 1])

        labels:
        dw ItemType.Pendant
        dw ItemType.Necklace
        dw ItemType.Amulet
        dw ItemType.SilverRing
        dw ItemType.BronzeRing
        dw ItemType.PlatinumRing
        dw ItemType.TitaniumRing
        dw ItemType.GoldRing
        dw ItemType.GhostWand
        dw ItemType.GraveWand
        dw ItemType.BoneWand
        dw ItemType.Wand
        dw ItemType.Grimoire
        dw ItemType.Chronicle
        dw ItemType.Tome
        dw ItemType.Book
        dw ItemType.DivineRobe
        dw ItemType.SilkRobe
        dw ItemType.LinenRobe
        dw ItemType.Robe
        dw ItemType.Shirt
        dw ItemType.Crown
        dw ItemType.DivineHood
        dw ItemType.SilkHood
        dw ItemType.LinenHood
        dw ItemType.Hood
        dw ItemType.BrightsilkSash
        dw ItemType.SilkSash
        dw ItemType.WoolSash
        dw ItemType.LinenSash
        dw ItemType.Sash
        dw ItemType.DivineSlippers
        dw ItemType.SilkSlippers
        dw ItemType.WoolShoes
        dw ItemType.LinenShoes
        dw ItemType.Shoes
        dw ItemType.DivineGloves
        dw ItemType.SilkGloves
        dw ItemType.WoolGloves
        dw ItemType.LinenGloves
        dw ItemType.Gloves
        dw ItemType.Katana
        dw ItemType.Falchion
        dw ItemType.Scimitar
        dw ItemType.LongSword
        dw ItemType.ShortSword
        dw ItemType.DemonHusk
        dw ItemType.DragonskinArmor
        dw ItemType.StuddedLeatherArmor
        dw ItemType.HardLeatherArmor
        dw ItemType.LeatherArmor
        dw ItemType.DemonCrown
        dw ItemType.DragonsCrown
        dw ItemType.WarCap
        dw ItemType.LeatherCap
        dw ItemType.Cap
        dw ItemType.DemonhideBelt
        dw ItemType.DragonskinBelt
        dw ItemType.StuddedLeatherBelt
        dw ItemType.HardLeatherBelt
        dw ItemType.LeatherBelt
        dw ItemType.DemonhideBoots
        dw ItemType.DragonskinBoots
        dw ItemType.StuddedLeatherBoots
        dw ItemType.HardLeatherBoots
        dw ItemType.LeatherBoots
        dw ItemType.DemonsHands
        dw ItemType.DragonskinGloves
        dw ItemType.StuddedLeatherGloves
        dw ItemType.HardLeatherGloves
        dw ItemType.LeatherGloves
        dw ItemType.Warhammer
        dw ItemType.Quarterstaff
        dw ItemType.Maul
        dw ItemType.Mace
        dw ItemType.Club
        dw ItemType.HolyChestplate
        dw ItemType.OrnateChestplate
        dw ItemType.PlateMail
        dw ItemType.ChainMail
        dw ItemType.RingMail
        dw ItemType.AncientHelm
        dw ItemType.OrnateHelm
        dw ItemType.GreatHelm
        dw ItemType.FullHelm
        dw ItemType.Helm
        dw ItemType.OrnateBelt
        dw ItemType.WarBelt
        dw ItemType.PlatedBelt
        dw ItemType.MeshBelt
        dw ItemType.HeavyBelt
        dw ItemType.HolyGreaves
        dw ItemType.OrnateGreaves
        dw ItemType.Greaves
        dw ItemType.ChainBoots
        dw ItemType.HeavyBoots
        dw ItemType.HolyGauntlets
        dw ItemType.OrnateGauntlets
        dw ItemType.Gauntlets
        dw ItemType.ChainGloves
        dw ItemType.HeavyGloves
    end

    func item_material{syscall_ptr : felt*, range_check_ptr}(item_id : felt) -> (material : felt):
        alloc_locals

        let (label_location) = get_label_location(labels)
        return ([label_location + item_id - 1])

        labels:
        dw ItemMaterial.Pendant
        dw ItemMaterial.Necklace
        dw ItemMaterial.Amulet
        dw ItemMaterial.SilverRing
        dw ItemMaterial.BronzeRing
        dw ItemMaterial.PlatinumRing
        dw ItemMaterial.TitaniumRing
        dw ItemMaterial.GoldRing
        dw ItemMaterial.GhostWand
        dw ItemMaterial.GraveWand
        dw ItemMaterial.BoneWand
        dw ItemMaterial.Wand
        dw ItemMaterial.Grimoire
        dw ItemMaterial.Chronicle
        dw ItemMaterial.Tome
        dw ItemMaterial.Book
        dw ItemMaterial.DivineRobe
        dw ItemMaterial.SilkRobe
        dw ItemMaterial.LinenRobe
        dw ItemMaterial.Robe
        dw ItemMaterial.Shirt
        dw ItemMaterial.Crown
        dw ItemMaterial.DivineHood
        dw ItemMaterial.SilkHood
        dw ItemMaterial.LinenHood
        dw ItemMaterial.Hood
        dw ItemMaterial.BrightsilkSash
        dw ItemMaterial.SilkSash
        dw ItemMaterial.WoolSash
        dw ItemMaterial.LinenSash
        dw ItemMaterial.Sash
        dw ItemMaterial.DivineSlippers
        dw ItemMaterial.SilkSlippers
        dw ItemMaterial.WoolShoes
        dw ItemMaterial.LinenShoes
        dw ItemMaterial.Shoes
        dw ItemMaterial.DivineGloves
        dw ItemMaterial.SilkGloves
        dw ItemMaterial.WoolGloves
        dw ItemMaterial.LinenGloves
        dw ItemMaterial.Gloves
        dw ItemMaterial.Katana
        dw ItemMaterial.Falchion
        dw ItemMaterial.Scimitar
        dw ItemMaterial.LongSword
        dw ItemMaterial.ShortSword
        dw ItemMaterial.DemonHusk
        dw ItemMaterial.DragonskinArmor
        dw ItemMaterial.StuddedLeatherArmor
        dw ItemMaterial.HardLeatherArmor
        dw ItemMaterial.LeatherArmor
        dw ItemMaterial.DemonCrown
        dw ItemMaterial.DragonsCrown
        dw ItemMaterial.WarCap
        dw ItemMaterial.LeatherCap
        dw ItemMaterial.Cap
        dw ItemMaterial.DemonhideBelt
        dw ItemMaterial.DragonskinBelt
        dw ItemMaterial.StuddedLeatherBelt
        dw ItemMaterial.HardLeatherBelt
        dw ItemMaterial.LeatherBelt
        dw ItemMaterial.DemonhideBoots
        dw ItemMaterial.DragonskinBoots
        dw ItemMaterial.StuddedLeatherBoots
        dw ItemMaterial.HardLeatherBoots
        dw ItemMaterial.LeatherBoots
        dw ItemMaterial.DemonsHands
        dw ItemMaterial.DragonskinGloves
        dw ItemMaterial.StuddedLeatherGloves
        dw ItemMaterial.HardLeatherGloves
        dw ItemMaterial.LeatherGloves
        dw ItemMaterial.Warhammer
        dw ItemMaterial.Quarterstaff
        dw ItemMaterial.Maul
        dw ItemMaterial.Mace
        dw ItemMaterial.Club
        dw ItemMaterial.HolyChestplate
        dw ItemMaterial.OrnateChestplate
        dw ItemMaterial.PlateMail
        dw ItemMaterial.ChainMail
        dw ItemMaterial.RingMail
        dw ItemMaterial.AncientHelm
        dw ItemMaterial.OrnateHelm
        dw ItemMaterial.GreatHelm
        dw ItemMaterial.FullHelm
        dw ItemMaterial.Helm
        dw ItemMaterial.OrnateBelt
        dw ItemMaterial.WarBelt
        dw ItemMaterial.PlatedBelt
        dw ItemMaterial.MeshBelt
        dw ItemMaterial.HeavyBelt
        dw ItemMaterial.HolyGreaves
        dw ItemMaterial.OrnateGreaves
        dw ItemMaterial.Greaves
        dw ItemMaterial.ChainBoots
        dw ItemMaterial.HeavyBoots
        dw ItemMaterial.HolyGauntlets
        dw ItemMaterial.OrnateGauntlets
        dw ItemMaterial.Gauntlets
        dw ItemMaterial.ChainGloves
        dw ItemMaterial.HeavyGloves
    end
end
