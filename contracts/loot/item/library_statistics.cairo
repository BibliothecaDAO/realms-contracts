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

from contracts.loot.item.constants import (
    ItemAgility,
    Item,
    ItemSlot,
    ItemClass,
    ItemVitality,
    ItemArmour,
    ItemWisdom,
    ItemAttack,
)

namespace Statistics:
    # Get Item Class
    func item_class{syscall_ptr : felt*, range_check_ptr}(item_id : felt) -> (class : felt):
        alloc_locals

        let (type_label) = get_label_location(item_slot)

        return ([type_label + item_id - 1])

        item_slot:
        dw ItemClass.Pendant
        dw ItemClass.Necklace
        dw ItemClass.Amulet
        # TODO: add
    end

    # Item location on Adventurer
    func item_slot{syscall_ptr : felt*, range_check_ptr}(item_id : felt) -> (slot : felt):
        alloc_locals

        let (type_label) = get_label_location(item_slot)

        return ([type_label + item_id - 1])

        item_slot:
        dw ItemSlot.Pendant
        dw ItemSlot.Necklace
        dw ItemSlot.Amulet
        # TODO: add
    end

    func base_agility{syscall_ptr : felt*, range_check_ptr}(item_id : felt) -> (agility : felt):
        alloc_locals

        let (type_label) = get_label_location(item_agility)

        return ([type_label + item_id - 1])

        item_agility:
        dw ItemAgility.Pendant
        dw ItemAgility.Necklace
        dw ItemAgility.Amulet
        dw ItemAgility.SilverRing
        dw ItemAgility.BronzeRing
        dw ItemAgility.PlatinumRing
        dw ItemAgility.TitaniumRing
        dw ItemAgility.GoldRing
        dw ItemAgility.GhostWand
        dw ItemAgility.GraveWand
        dw ItemAgility.BoneWand
        dw ItemAgility.Wand
        dw ItemAgility.Grimoire
        dw ItemAgility.Chronicle
        dw ItemAgility.Tome
        dw ItemAgility.Book
        dw ItemAgility.DivineRobe
        dw ItemAgility.SilkRobe
        dw ItemAgility.LinenRobe
        dw ItemAgility.Robe
        dw ItemAgility.Shirt
        dw ItemAgility.Crown
        dw ItemAgility.DivineHood
        dw ItemAgility.SilkHood
        dw ItemAgility.LinenHood
        dw ItemAgility.Hood
        dw ItemAgility.BrightsilkSash
        dw ItemAgility.SilkSash
        dw ItemAgility.WoolSash
        dw ItemAgility.LinenSash
        dw ItemAgility.Sash
        dw ItemAgility.DivineSlippers
        dw ItemAgility.SilkSlippers
        dw ItemAgility.WoolShoes
        dw ItemAgility.LinenShoes
        dw ItemAgility.Shoes
        dw ItemAgility.DivineGloves
        dw ItemAgility.SilkGloves
        dw ItemAgility.WoolGloves
        dw ItemAgility.LinenGloves
        dw ItemAgility.Gloves
        dw ItemAgility.Katana
        dw ItemAgility.Falchion
        dw ItemAgility.Scimitar
        dw ItemAgility.LongSword
        dw ItemAgility.ShortSword
        dw ItemAgility.DemonHusk
        dw ItemAgility.DragonskinArmor
        dw ItemAgility.StuddedLeatherArmor
        dw ItemAgility.HardLeatherArmor
        dw ItemAgility.LeatherArmor
        dw ItemAgility.DemonCrown
        dw ItemAgility.DragonsCrown
        dw ItemAgility.WarCap
        dw ItemAgility.LeatherCap
        dw ItemAgility.Cap
        dw ItemAgility.DemonhideBelt
        dw ItemAgility.DragonskinBelt
        dw ItemAgility.StuddedLeatherBelt
        dw ItemAgility.HardLeatherBelt
        dw ItemAgility.LeatherBelt
        dw ItemAgility.DemonhideBoots
        dw ItemAgility.DragonskinBoots
        dw ItemAgility.StuddedLeatherBoots
        dw ItemAgility.HardLeatherBoots
        dw ItemAgility.LeatherBoots
        dw ItemAgility.DemonsHands
        dw ItemAgility.DragonskinGloves
        dw ItemAgility.StuddedLeatherGloves
        dw ItemAgility.HardLeatherGloves
        dw ItemAgility.LeatherGloves
        dw ItemAgility.Warhammer
        dw ItemAgility.Quarterstaff
        dw ItemAgility.Maul
        dw ItemAgility.Mace
        dw ItemAgility.Club
        dw ItemAgility.HolyChestplate
        dw ItemAgility.OrnateChestplate
        dw ItemAgility.PlateMail
        dw ItemAgility.ChainMail
        dw ItemAgility.RingMail
        dw ItemAgility.AncientHelm
        dw ItemAgility.OrnateHelm
        dw ItemAgility.GreatHelm
        dw ItemAgility.FullHelm
        dw ItemAgility.Helm
        dw ItemAgility.OrnateBelt
        dw ItemAgility.WarBelt
        dw ItemAgility.PlatedBelt
        dw ItemAgility.MeshBelt
        dw ItemAgility.HeavyBelt
        dw ItemAgility.HolyGreaves
        dw ItemAgility.OrnateGreaves
        dw ItemAgility.Greaves
        dw ItemAgility.ChainBoots
        dw ItemAgility.HeavyBoots
        dw ItemAgility.HolyGauntlets
        dw ItemAgility.OrnateGauntlets
        dw ItemAgility.Gauntlets
        dw ItemAgility.ChainGloves
        dw ItemAgility.HeavyGloves
    end
    func base_attack{syscall_ptr : felt*, range_check_ptr}(item_id : felt) -> (attack : felt):
        alloc_locals

        let (type_label) = get_label_location(item_attack)

        return ([type_label + item_id - 1])

        item_attack:
        dw ItemAttack.Pendant
        dw ItemAttack.Necklace
        dw ItemAttack.Amulet
        dw ItemAttack.SilverRing
        dw ItemAttack.BronzeRing
        dw ItemAttack.PlatinumRing
        dw ItemAttack.TitaniumRing
        dw ItemAttack.GoldRing
        dw ItemAttack.GhostWand
        dw ItemAttack.GraveWand
        dw ItemAttack.BoneWand
        dw ItemAttack.Wand
        dw ItemAttack.Grimoire
        dw ItemAttack.Chronicle
        dw ItemAttack.Tome
        dw ItemAttack.Book
        dw ItemAttack.DivineRobe
        dw ItemAttack.SilkRobe
        dw ItemAttack.LinenRobe
        dw ItemAttack.Robe
        dw ItemAttack.Shirt
        dw ItemAttack.Crown
        dw ItemAttack.DivineHood
        dw ItemAttack.SilkHood
        dw ItemAttack.LinenHood
        dw ItemAttack.Hood
        dw ItemAttack.BrightsilkSash
        dw ItemAttack.SilkSash
        dw ItemAttack.WoolSash
        dw ItemAttack.LinenSash
        dw ItemAttack.Sash
        dw ItemAttack.DivineSlippers
        dw ItemAttack.SilkSlippers
        dw ItemAttack.WoolShoes
        dw ItemAttack.LinenShoes
        dw ItemAttack.Shoes
        dw ItemAttack.DivineGloves
        dw ItemAttack.SilkGloves
        dw ItemAttack.WoolGloves
        dw ItemAttack.LinenGloves
        dw ItemAttack.Gloves
        dw ItemAttack.Katana
        dw ItemAttack.Falchion
        dw ItemAttack.Scimitar
        dw ItemAttack.LongSword
        dw ItemAttack.ShortSword
        dw ItemAttack.DemonHusk
        dw ItemAttack.DragonskinArmor
        dw ItemAttack.StuddedLeatherArmor
        dw ItemAttack.HardLeatherArmor
        dw ItemAttack.LeatherArmor
        dw ItemAttack.DemonCrown
        dw ItemAttack.DragonsCrown
        dw ItemAttack.WarCap
        dw ItemAttack.LeatherCap
        dw ItemAttack.Cap
        dw ItemAttack.DemonhideBelt
        dw ItemAttack.DragonskinBelt
        dw ItemAttack.StuddedLeatherBelt
        dw ItemAttack.HardLeatherBelt
        dw ItemAttack.LeatherBelt
        dw ItemAttack.DemonhideBoots
        dw ItemAttack.DragonskinBoots
        dw ItemAttack.StuddedLeatherBoots
        dw ItemAttack.HardLeatherBoots
        dw ItemAttack.LeatherBoots
        dw ItemAttack.DemonsHands
        dw ItemAttack.DragonskinGloves
        dw ItemAttack.StuddedLeatherGloves
        dw ItemAttack.HardLeatherGloves
        dw ItemAttack.LeatherGloves
        dw ItemAttack.Warhammer
        dw ItemAttack.Quarterstaff
        dw ItemAttack.Maul
        dw ItemAttack.Mace
        dw ItemAttack.Club
        dw ItemAttack.HolyChestplate
        dw ItemAttack.OrnateChestplate
        dw ItemAttack.PlateMail
        dw ItemAttack.ChainMail
        dw ItemAttack.RingMail
        dw ItemAttack.AncientHelm
        dw ItemAttack.OrnateHelm
        dw ItemAttack.GreatHelm
        dw ItemAttack.FullHelm
        dw ItemAttack.Helm
        dw ItemAttack.OrnateBelt
        dw ItemAttack.WarBelt
        dw ItemAttack.PlatedBelt
        dw ItemAttack.MeshBelt
        dw ItemAttack.HeavyBelt
        dw ItemAttack.HolyGreaves
        dw ItemAttack.OrnateGreaves
        dw ItemAttack.Greaves
        dw ItemAttack.ChainBoots
        dw ItemAttack.HeavyBoots
        dw ItemAttack.HolyGauntlets
        dw ItemAttack.OrnateGauntlets
        dw ItemAttack.Gauntlets
        dw ItemAttack.ChainGloves
        dw ItemAttack.HeavyGloves
    end
    func base_armour{syscall_ptr : felt*, range_check_ptr}(item_id : felt) -> (armour : felt):
        alloc_locals

        let (type_label) = get_label_location(item_armour)

        return ([type_label + item_id - 1])

        item_armour:
        dw ItemArmour.Pendant
        dw ItemArmour.Necklace
        dw ItemArmour.Amulet
        dw ItemArmour.SilverRing
        dw ItemArmour.BronzeRing
        dw ItemArmour.PlatinumRing
        dw ItemArmour.TitaniumRing
        dw ItemArmour.GoldRing
        dw ItemArmour.GhostWand
        dw ItemArmour.GraveWand
        dw ItemArmour.BoneWand
        dw ItemArmour.Wand
        dw ItemArmour.Grimoire
        dw ItemArmour.Chronicle
        dw ItemArmour.Tome
        dw ItemArmour.Book
        dw ItemArmour.DivineRobe
        dw ItemArmour.SilkRobe
        dw ItemArmour.LinenRobe
        dw ItemArmour.Robe
        dw ItemArmour.Shirt
        dw ItemArmour.Crown
        dw ItemArmour.DivineHood
        dw ItemArmour.SilkHood
        dw ItemArmour.LinenHood
        dw ItemArmour.Hood
        dw ItemArmour.BrightsilkSash
        dw ItemArmour.SilkSash
        dw ItemArmour.WoolSash
        dw ItemArmour.LinenSash
        dw ItemArmour.Sash
        dw ItemArmour.DivineSlippers
        dw ItemArmour.SilkSlippers
        dw ItemArmour.WoolShoes
        dw ItemArmour.LinenShoes
        dw ItemArmour.Shoes
        dw ItemArmour.DivineGloves
        dw ItemArmour.SilkGloves
        dw ItemArmour.WoolGloves
        dw ItemArmour.LinenGloves
        dw ItemArmour.Gloves
        dw ItemArmour.Katana
        dw ItemArmour.Falchion
        dw ItemArmour.Scimitar
        dw ItemArmour.LongSword
        dw ItemArmour.ShortSword
        dw ItemArmour.DemonHusk
        dw ItemArmour.DragonskinArmor
        dw ItemArmour.StuddedLeatherArmor
        dw ItemArmour.HardLeatherArmor
        dw ItemArmour.LeatherArmor
        dw ItemArmour.DemonCrown
        dw ItemArmour.DragonsCrown
        dw ItemArmour.WarCap
        dw ItemArmour.LeatherCap
        dw ItemArmour.Cap
        dw ItemArmour.DemonhideBelt
        dw ItemArmour.DragonskinBelt
        dw ItemArmour.StuddedLeatherBelt
        dw ItemArmour.HardLeatherBelt
        dw ItemArmour.LeatherBelt
        dw ItemArmour.DemonhideBoots
        dw ItemArmour.DragonskinBoots
        dw ItemArmour.StuddedLeatherBoots
        dw ItemArmour.HardLeatherBoots
        dw ItemArmour.LeatherBoots
        dw ItemArmour.DemonsHands
        dw ItemArmour.DragonskinGloves
        dw ItemArmour.StuddedLeatherGloves
        dw ItemArmour.HardLeatherGloves
        dw ItemArmour.LeatherGloves
        dw ItemArmour.Warhammer
        dw ItemArmour.Quarterstaff
        dw ItemArmour.Maul
        dw ItemArmour.Mace
        dw ItemArmour.Club
        dw ItemArmour.HolyChestplate
        dw ItemArmour.OrnateChestplate
        dw ItemArmour.PlateMail
        dw ItemArmour.ChainMail
        dw ItemArmour.RingMail
        dw ItemArmour.AncientHelm
        dw ItemArmour.OrnateHelm
        dw ItemArmour.GreatHelm
        dw ItemArmour.FullHelm
        dw ItemArmour.Helm
        dw ItemArmour.OrnateBelt
        dw ItemArmour.WarBelt
        dw ItemArmour.PlatedBelt
        dw ItemArmour.MeshBelt
        dw ItemArmour.HeavyBelt
        dw ItemArmour.HolyGreaves
        dw ItemArmour.OrnateGreaves
        dw ItemArmour.Greaves
        dw ItemArmour.ChainBoots
        dw ItemArmour.HeavyBoots
        dw ItemArmour.HolyGauntlets
        dw ItemArmour.OrnateGauntlets
        dw ItemArmour.Gauntlets
        dw ItemArmour.ChainGloves
        dw ItemArmour.HeavyGloves
    end
    func base_wisdom{syscall_ptr : felt*, range_check_ptr}(item_id : felt) -> (wisdom : felt):
        alloc_locals

        let (type_label) = get_label_location(item_wisdom)

        return ([type_label + item_id - 1])

        item_wisdom:
        dw ItemWisdom.Pendant
        dw ItemWisdom.Necklace
        dw ItemWisdom.Amulet
        dw ItemWisdom.SilverRing
        dw ItemWisdom.BronzeRing
        dw ItemWisdom.PlatinumRing
        dw ItemWisdom.TitaniumRing
        dw ItemWisdom.GoldRing
        dw ItemWisdom.GhostWand
        dw ItemWisdom.GraveWand
        dw ItemWisdom.BoneWand
        dw ItemWisdom.Wand
        dw ItemWisdom.Grimoire
        dw ItemWisdom.Chronicle
        dw ItemWisdom.Tome
        dw ItemWisdom.Book
        dw ItemWisdom.DivineRobe
        dw ItemWisdom.SilkRobe
        dw ItemWisdom.LinenRobe
        dw ItemWisdom.Robe
        dw ItemWisdom.Shirt
        dw ItemWisdom.Crown
        dw ItemWisdom.DivineHood
        dw ItemWisdom.SilkHood
        dw ItemWisdom.LinenHood
        dw ItemWisdom.Hood
        dw ItemWisdom.BrightsilkSash
        dw ItemWisdom.SilkSash
        dw ItemWisdom.WoolSash
        dw ItemWisdom.LinenSash
        dw ItemWisdom.Sash
        dw ItemWisdom.DivineSlippers
        dw ItemWisdom.SilkSlippers
        dw ItemWisdom.WoolShoes
        dw ItemWisdom.LinenShoes
        dw ItemWisdom.Shoes
        dw ItemWisdom.DivineGloves
        dw ItemWisdom.SilkGloves
        dw ItemWisdom.WoolGloves
        dw ItemWisdom.LinenGloves
        dw ItemWisdom.Gloves
        dw ItemWisdom.Katana
        dw ItemWisdom.Falchion
        dw ItemWisdom.Scimitar
        dw ItemWisdom.LongSword
        dw ItemWisdom.ShortSword
        dw ItemWisdom.DemonHusk
        dw ItemWisdom.DragonskinArmor
        dw ItemWisdom.StuddedLeatherArmor
        dw ItemWisdom.HardLeatherArmor
        dw ItemWisdom.LeatherArmor
        dw ItemWisdom.DemonCrown
        dw ItemWisdom.DragonsCrown
        dw ItemWisdom.WarCap
        dw ItemWisdom.LeatherCap
        dw ItemWisdom.Cap
        dw ItemWisdom.DemonhideBelt
        dw ItemWisdom.DragonskinBelt
        dw ItemWisdom.StuddedLeatherBelt
        dw ItemWisdom.HardLeatherBelt
        dw ItemWisdom.LeatherBelt
        dw ItemWisdom.DemonhideBoots
        dw ItemWisdom.DragonskinBoots
        dw ItemWisdom.StuddedLeatherBoots
        dw ItemWisdom.HardLeatherBoots
        dw ItemWisdom.LeatherBoots
        dw ItemWisdom.DemonsHands
        dw ItemWisdom.DragonskinGloves
        dw ItemWisdom.StuddedLeatherGloves
        dw ItemWisdom.HardLeatherGloves
        dw ItemWisdom.LeatherGloves
        dw ItemWisdom.Warhammer
        dw ItemWisdom.Quarterstaff
        dw ItemWisdom.Maul
        dw ItemWisdom.Mace
        dw ItemWisdom.Club
        dw ItemWisdom.HolyChestplate
        dw ItemWisdom.OrnateChestplate
        dw ItemWisdom.PlateMail
        dw ItemWisdom.ChainMail
        dw ItemWisdom.RingMail
        dw ItemWisdom.AncientHelm
        dw ItemWisdom.OrnateHelm
        dw ItemWisdom.GreatHelm
        dw ItemWisdom.FullHelm
        dw ItemWisdom.Helm
        dw ItemWisdom.OrnateBelt
        dw ItemWisdom.WarBelt
        dw ItemWisdom.PlatedBelt
        dw ItemWisdom.MeshBelt
        dw ItemWisdom.HeavyBelt
        dw ItemWisdom.HolyGreaves
        dw ItemWisdom.OrnateGreaves
        dw ItemWisdom.Greaves
        dw ItemWisdom.ChainBoots
        dw ItemWisdom.HeavyBoots
        dw ItemWisdom.HolyGauntlets
        dw ItemWisdom.OrnateGauntlets
        dw ItemWisdom.Gauntlets
        dw ItemWisdom.ChainGloves
        dw ItemWisdom.HeavyGloves
    end
    func base_vitality{syscall_ptr : felt*, range_check_ptr}(item_id : felt) -> (vitality : felt):
        alloc_locals

        let (type_label) = get_label_location(item_vitality)

        return ([type_label + item_id - 1])

        item_vitality:
        dw ItemVitality.Pendant
        dw ItemVitality.Necklace
        dw ItemVitality.Amulet
        dw ItemVitality.SilverRing
        dw ItemVitality.BronzeRing
        dw ItemVitality.PlatinumRing
        dw ItemVitality.TitaniumRing
        dw ItemVitality.GoldRing
        dw ItemVitality.GhostWand
        dw ItemVitality.GraveWand
        dw ItemVitality.BoneWand
        dw ItemVitality.Wand
        dw ItemVitality.Grimoire
        dw ItemVitality.Chronicle
        dw ItemVitality.Tome
        dw ItemVitality.Book
        dw ItemVitality.DivineRobe
        dw ItemVitality.SilkRobe
        dw ItemVitality.LinenRobe
        dw ItemVitality.Robe
        dw ItemVitality.Shirt
        dw ItemVitality.Crown
        dw ItemVitality.DivineHood
        dw ItemVitality.SilkHood
        dw ItemVitality.LinenHood
        dw ItemVitality.Hood
        dw ItemVitality.BrightsilkSash
        dw ItemVitality.SilkSash
        dw ItemVitality.WoolSash
        dw ItemVitality.LinenSash
        dw ItemVitality.Sash
        dw ItemVitality.DivineSlippers
        dw ItemVitality.SilkSlippers
        dw ItemVitality.WoolShoes
        dw ItemVitality.LinenShoes
        dw ItemVitality.Shoes
        dw ItemVitality.DivineGloves
        dw ItemVitality.SilkGloves
        dw ItemVitality.WoolGloves
        dw ItemVitality.LinenGloves
        dw ItemVitality.Gloves
        dw ItemVitality.Katana
        dw ItemVitality.Falchion
        dw ItemVitality.Scimitar
        dw ItemVitality.LongSword
        dw ItemVitality.ShortSword
        dw ItemVitality.DemonHusk
        dw ItemVitality.DragonskinArmor
        dw ItemVitality.StuddedLeatherArmor
        dw ItemVitality.HardLeatherArmor
        dw ItemVitality.LeatherArmor
        dw ItemVitality.DemonCrown
        dw ItemVitality.DragonsCrown
        dw ItemVitality.WarCap
        dw ItemVitality.LeatherCap
        dw ItemVitality.Cap
        dw ItemVitality.DemonhideBelt
        dw ItemVitality.DragonskinBelt
        dw ItemVitality.StuddedLeatherBelt
        dw ItemVitality.HardLeatherBelt
        dw ItemVitality.LeatherBelt
        dw ItemVitality.DemonhideBoots
        dw ItemVitality.DragonskinBoots
        dw ItemVitality.StuddedLeatherBoots
        dw ItemVitality.HardLeatherBoots
        dw ItemVitality.LeatherBoots
        dw ItemVitality.DemonsHands
        dw ItemVitality.DragonskinGloves
        dw ItemVitality.StuddedLeatherGloves
        dw ItemVitality.HardLeatherGloves
        dw ItemVitality.LeatherGloves
        dw ItemVitality.Warhammer
        dw ItemVitality.Quarterstaff
        dw ItemVitality.Maul
        dw ItemVitality.Mace
        dw ItemVitality.Club
        dw ItemVitality.HolyChestplate
        dw ItemVitality.OrnateChestplate
        dw ItemVitality.PlateMail
        dw ItemVitality.ChainMail
        dw ItemVitality.RingMail
        dw ItemVitality.AncientHelm
        dw ItemVitality.OrnateHelm
        dw ItemVitality.GreatHelm
        dw ItemVitality.FullHelm
        dw ItemVitality.Helm
        dw ItemVitality.OrnateBelt
        dw ItemVitality.WarBelt
        dw ItemVitality.PlatedBelt
        dw ItemVitality.MeshBelt
        dw ItemVitality.HeavyBelt
        dw ItemVitality.HolyGreaves
        dw ItemVitality.OrnateGreaves
        dw ItemVitality.Greaves
        dw ItemVitality.ChainBoots
        dw ItemVitality.HeavyBoots
        dw ItemVitality.HolyGauntlets
        dw ItemVitality.OrnateGauntlets
        dw ItemVitality.Gauntlets
        dw ItemVitality.ChainGloves
        dw ItemVitality.HeavyGloves
    end
end
