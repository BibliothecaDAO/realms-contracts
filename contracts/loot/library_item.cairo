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

from contracts.loot.ItemConstants import ItemAgility, Item

namespace LootItems:
    func calculate_item_stats{syscall_ptr : felt*, range_check_ptr}(item_id : felt) -> (
        item : Item
    ):
        alloc_locals
        # computed
        let (Agility) = base_agility(item_id)
        let (Attack) = base_agility(item_id)
        let (Armour) = base_agility(item_id)
        let (Wisdom) = base_agility(item_id)
        let (Vitality) = base_agility(item_id)

        # State based
        let (Prefix) = base_agility(item_id)
        let (Suffix) = base_agility(item_id)
        let (Order) = base_agility(item_id)
        let (Bonus) = base_agility(item_id)

        return (
            item=Item(item_id, 1, Agility, Attack, Armour, Wisdom, Vitality, Prefix, Suffix, Order, Bonus, 1, 12123123),
        )
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
end
