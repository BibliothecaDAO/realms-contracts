// SPDX-License-Identifier: MIT
//

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
    ItemIndex,
    SlotItemsLength,
    ItemType,
    ItemMaterial,
    ItemNamePrefixes,
    ItemNameSuffixes,
    ItemSuffixes,
)
from contracts.loot.constants.rankings import ItemRank
from contracts.loot.constants.physics import MaterialDensity

namespace ItemStats {
    func item_slot{syscall_ptr: felt*, range_check_ptr}(item_id: felt) -> (slot: felt) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + item_id - 1],);

        labels:
        dw ItemSlot.Pendant;
        dw ItemSlot.Necklace;
        dw ItemSlot.Amulet;
        dw ItemSlot.SilverRing;
        dw ItemSlot.BronzeRing;
        dw ItemSlot.PlatinumRing;
        dw ItemSlot.TitaniumRing;
        dw ItemSlot.GoldRing;
        dw ItemSlot.GhostWand;
        dw ItemSlot.GraveWand;
        dw ItemSlot.BoneWand;
        dw ItemSlot.Wand;
        dw ItemSlot.Grimoire;
        dw ItemSlot.Chronicle;
        dw ItemSlot.Tome;
        dw ItemSlot.Book;
        dw ItemSlot.DivineRobe;
        dw ItemSlot.SilkRobe;
        dw ItemSlot.LinenRobe;
        dw ItemSlot.Robe;
        dw ItemSlot.Shirt;
        dw ItemSlot.Crown;
        dw ItemSlot.DivineHood;
        dw ItemSlot.SilkHood;
        dw ItemSlot.LinenHood;
        dw ItemSlot.Hood;
        dw ItemSlot.BrightsilkSash;
        dw ItemSlot.SilkSash;
        dw ItemSlot.WoolSash;
        dw ItemSlot.LinenSash;
        dw ItemSlot.Sash;
        dw ItemSlot.DivineSlippers;
        dw ItemSlot.SilkSlippers;
        dw ItemSlot.WoolShoes;
        dw ItemSlot.LinenShoes;
        dw ItemSlot.Shoes;
        dw ItemSlot.DivineGloves;
        dw ItemSlot.SilkGloves;
        dw ItemSlot.WoolGloves;
        dw ItemSlot.LinenGloves;
        dw ItemSlot.Gloves;
        dw ItemSlot.Katana;
        dw ItemSlot.Falchion;
        dw ItemSlot.Scimitar;
        dw ItemSlot.LongSword;
        dw ItemSlot.ShortSword;
        dw ItemSlot.DemonHusk;
        dw ItemSlot.DragonskinArmor;
        dw ItemSlot.StuddedLeatherArmor;
        dw ItemSlot.HardLeatherArmor;
        dw ItemSlot.LeatherArmor;
        dw ItemSlot.DemonCrown;
        dw ItemSlot.DragonsCrown;
        dw ItemSlot.WarCap;
        dw ItemSlot.LeatherCap;
        dw ItemSlot.Cap;
        dw ItemSlot.DemonhideBelt;
        dw ItemSlot.DragonskinBelt;
        dw ItemSlot.StuddedLeatherBelt;
        dw ItemSlot.HardLeatherBelt;
        dw ItemSlot.LeatherBelt;
        dw ItemSlot.DemonhideBoots;
        dw ItemSlot.DragonskinBoots;
        dw ItemSlot.StuddedLeatherBoots;
        dw ItemSlot.HardLeatherBoots;
        dw ItemSlot.LeatherBoots;
        dw ItemSlot.DemonsHands;
        dw ItemSlot.DragonskinGloves;
        dw ItemSlot.StuddedLeatherGloves;
        dw ItemSlot.HardLeatherGloves;
        dw ItemSlot.LeatherGloves;
        dw ItemSlot.Warhammer;
        dw ItemSlot.Quarterstaff;
        dw ItemSlot.Maul;
        dw ItemSlot.Mace;
        dw ItemSlot.Club;
        dw ItemSlot.HolyChestplate;
        dw ItemSlot.OrnateChestplate;
        dw ItemSlot.PlateMail;
        dw ItemSlot.ChainMail;
        dw ItemSlot.RingMail;
        dw ItemSlot.AncientHelm;
        dw ItemSlot.OrnateHelm;
        dw ItemSlot.GreatHelm;
        dw ItemSlot.FullHelm;
        dw ItemSlot.Helm;
        dw ItemSlot.OrnateBelt;
        dw ItemSlot.WarBelt;
        dw ItemSlot.PlatedBelt;
        dw ItemSlot.MeshBelt;
        dw ItemSlot.HeavyBelt;
        dw ItemSlot.HolyGreaves;
        dw ItemSlot.OrnateGreaves;
        dw ItemSlot.Greaves;
        dw ItemSlot.ChainBoots;
        dw ItemSlot.HeavyBoots;
        dw ItemSlot.HolyGauntlets;
        dw ItemSlot.OrnateGauntlets;
        dw ItemSlot.Gauntlets;
        dw ItemSlot.ChainGloves;
        dw ItemSlot.HeavyGloves;
    }

    func loot_banned_name{syscall_ptr: felt*, range_check_ptr}(index: felt) -> (is_banned: felt) {
        let (_, r) = unsigned_div_rem(index, 3);
        if (r == 0) {
            return (TRUE,);
        } else {
            return (FALSE,);
        }
    }

    func loot_slot_length{syscall_ptr: felt*, range_check_ptr}(slot: felt) -> (slot_length: felt) {
        let (label_location) = get_label_location(labels);
        return ([label_location + slot - 1],);

        labels:
        dw SlotItemsLength.Weapon;
        dw SlotItemsLength.Chest;
        dw SlotItemsLength.Head;
        dw SlotItemsLength.Waist;
        dw SlotItemsLength.Foot;
        dw SlotItemsLength.Hand;
        dw SlotItemsLength.Neck;
        dw SlotItemsLength.Ring;
    }

    func loot_item_index{syscall_ptr: felt*, range_check_ptr}(item_id: felt) -> (item_index: felt) {
        let (label_location) = get_label_location(labels);
        return ([label_location + item_id - 1],);

        labels:
        dw ItemIndex.Pendant;
        dw ItemIndex.Necklace;
        dw ItemIndex.Amulet;
        dw ItemIndex.SilverRing;
        dw ItemIndex.BronzeRing;
        dw ItemIndex.PlatinumRing;
        dw ItemIndex.TitaniumRing;
        dw ItemIndex.GoldRing;
        dw ItemIndex.GhostWand;
        dw ItemIndex.GraveWand;
        dw ItemIndex.BoneWand;
        dw ItemIndex.Wand;
        dw ItemIndex.Grimoire;
        dw ItemIndex.Chronicle;
        dw ItemIndex.Tome;
        dw ItemIndex.Book;
        dw ItemIndex.DivineRobe;
        dw ItemIndex.SilkRobe;
        dw ItemIndex.LinenRobe;
        dw ItemIndex.Robe;
        dw ItemIndex.Shirt;
        dw ItemIndex.Crown;
        dw ItemIndex.DivineHood;
        dw ItemIndex.SilkHood;
        dw ItemIndex.LinenHood;
        dw ItemIndex.Hood;
        dw ItemIndex.BrightsilkSash;
        dw ItemIndex.SilkSash;
        dw ItemIndex.WoolSash;
        dw ItemIndex.LinenSash;
        dw ItemIndex.Sash;
        dw ItemIndex.DivineSlippers;
        dw ItemIndex.SilkSlippers;
        dw ItemIndex.WoolShoes;
        dw ItemIndex.LinenShoes;
        dw ItemIndex.Shoes;
        dw ItemIndex.DivineGloves;
        dw ItemIndex.SilkGloves;
        dw ItemIndex.WoolGloves;
        dw ItemIndex.LinenGloves;
        dw ItemIndex.Gloves;
        dw ItemIndex.Katana;
        dw ItemIndex.Falchion;
        dw ItemIndex.Scimitar;
        dw ItemIndex.LongSword;
        dw ItemIndex.ShortSword;
        dw ItemIndex.DemonHusk;
        dw ItemIndex.DragonskinArmor;
        dw ItemIndex.StuddedLeatherArmor;
        dw ItemIndex.HardLeatherArmor;
        dw ItemIndex.LeatherArmor;
        dw ItemIndex.DemonCrown;
        dw ItemIndex.DragonsCrown;
        dw ItemIndex.WarCap;
        dw ItemIndex.LeatherCap;
        dw ItemIndex.Cap;
        dw ItemIndex.DemonhideBelt;
        dw ItemIndex.DragonskinBelt;
        dw ItemIndex.StuddedLeatherBelt;
        dw ItemIndex.HardLeatherBelt;
        dw ItemIndex.LeatherBelt;
        dw ItemIndex.DemonhideBoots;
        dw ItemIndex.DragonskinBoots;
        dw ItemIndex.StuddedLeatherBoots;
        dw ItemIndex.HardLeatherBoots;
        dw ItemIndex.LeatherBoots;
        dw ItemIndex.DemonsHands;
        dw ItemIndex.DragonskinGloves;
        dw ItemIndex.StuddedLeatherGloves;
        dw ItemIndex.HardLeatherGloves;
        dw ItemIndex.LeatherGloves;
        dw ItemIndex.Warhammer;
        dw ItemIndex.Quarterstaff;
        dw ItemIndex.Maul;
        dw ItemIndex.Mace;
        dw ItemIndex.Club;
        dw ItemIndex.HolyChestplate;
        dw ItemIndex.OrnateChestplate;
        dw ItemIndex.PlateMail;
        dw ItemIndex.ChainMail;
        dw ItemIndex.RingMail;
        dw ItemIndex.AncientHelm;
        dw ItemIndex.OrnateHelm;
        dw ItemIndex.GreatHelm;
        dw ItemIndex.FullHelm;
        dw ItemIndex.Helm;
        dw ItemIndex.OrnateBelt;
        dw ItemIndex.WarBelt;
        dw ItemIndex.PlatedBelt;
        dw ItemIndex.MeshBelt;
        dw ItemIndex.HeavyBelt;
        dw ItemIndex.HolyGreaves;
        dw ItemIndex.OrnateGreaves;
        dw ItemIndex.Greaves;
        dw ItemIndex.ChainBoots;
        dw ItemIndex.HeavyBoots;
        dw ItemIndex.HolyGauntlets;
        dw ItemIndex.OrnateGauntlets;
        dw ItemIndex.Gauntlets;
        dw ItemIndex.ChainGloves;
        dw ItemIndex.HeavyGloves;
    }

    func item_type{syscall_ptr: felt*, range_check_ptr}(item_id: felt) -> (type: felt) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + item_id - 1],);

        labels:
        dw ItemType.Pendant;
        dw ItemType.Necklace;
        dw ItemType.Amulet;
        dw ItemType.SilverRing;
        dw ItemType.BronzeRing;
        dw ItemType.PlatinumRing;
        dw ItemType.TitaniumRing;
        dw ItemType.GoldRing;
        dw ItemType.GhostWand;
        dw ItemType.GraveWand;
        dw ItemType.BoneWand;
        dw ItemType.Wand;
        dw ItemType.Grimoire;
        dw ItemType.Chronicle;
        dw ItemType.Tome;
        dw ItemType.Book;
        dw ItemType.DivineRobe;
        dw ItemType.SilkRobe;
        dw ItemType.LinenRobe;
        dw ItemType.Robe;
        dw ItemType.Shirt;
        dw ItemType.Crown;
        dw ItemType.DivineHood;
        dw ItemType.SilkHood;
        dw ItemType.LinenHood;
        dw ItemType.Hood;
        dw ItemType.BrightsilkSash;
        dw ItemType.SilkSash;
        dw ItemType.WoolSash;
        dw ItemType.LinenSash;
        dw ItemType.Sash;
        dw ItemType.DivineSlippers;
        dw ItemType.SilkSlippers;
        dw ItemType.WoolShoes;
        dw ItemType.LinenShoes;
        dw ItemType.Shoes;
        dw ItemType.DivineGloves;
        dw ItemType.SilkGloves;
        dw ItemType.WoolGloves;
        dw ItemType.LinenGloves;
        dw ItemType.Gloves;
        dw ItemType.Katana;
        dw ItemType.Falchion;
        dw ItemType.Scimitar;
        dw ItemType.LongSword;
        dw ItemType.ShortSword;
        dw ItemType.DemonHusk;
        dw ItemType.DragonskinArmor;
        dw ItemType.StuddedLeatherArmor;
        dw ItemType.HardLeatherArmor;
        dw ItemType.LeatherArmor;
        dw ItemType.DemonCrown;
        dw ItemType.DragonsCrown;
        dw ItemType.WarCap;
        dw ItemType.LeatherCap;
        dw ItemType.Cap;
        dw ItemType.DemonhideBelt;
        dw ItemType.DragonskinBelt;
        dw ItemType.StuddedLeatherBelt;
        dw ItemType.HardLeatherBelt;
        dw ItemType.LeatherBelt;
        dw ItemType.DemonhideBoots;
        dw ItemType.DragonskinBoots;
        dw ItemType.StuddedLeatherBoots;
        dw ItemType.HardLeatherBoots;
        dw ItemType.LeatherBoots;
        dw ItemType.DemonsHands;
        dw ItemType.DragonskinGloves;
        dw ItemType.StuddedLeatherGloves;
        dw ItemType.HardLeatherGloves;
        dw ItemType.LeatherGloves;
        dw ItemType.Warhammer;
        dw ItemType.Quarterstaff;
        dw ItemType.Maul;
        dw ItemType.Mace;
        dw ItemType.Club;
        dw ItemType.HolyChestplate;
        dw ItemType.OrnateChestplate;
        dw ItemType.PlateMail;
        dw ItemType.ChainMail;
        dw ItemType.RingMail;
        dw ItemType.AncientHelm;
        dw ItemType.OrnateHelm;
        dw ItemType.GreatHelm;
        dw ItemType.FullHelm;
        dw ItemType.Helm;
        dw ItemType.OrnateBelt;
        dw ItemType.WarBelt;
        dw ItemType.PlatedBelt;
        dw ItemType.MeshBelt;
        dw ItemType.HeavyBelt;
        dw ItemType.HolyGreaves;
        dw ItemType.OrnateGreaves;
        dw ItemType.Greaves;
        dw ItemType.ChainBoots;
        dw ItemType.HeavyBoots;
        dw ItemType.HolyGauntlets;
        dw ItemType.OrnateGauntlets;
        dw ItemType.Gauntlets;
        dw ItemType.ChainGloves;
        dw ItemType.HeavyGloves;
    }

    func item_material{syscall_ptr: felt*, range_check_ptr}(item_id: felt) -> (material: felt) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + item_id - 1],);

        labels:
        dw ItemMaterial.Pendant;
        dw ItemMaterial.Necklace;
        dw ItemMaterial.Amulet;
        dw ItemMaterial.SilverRing;
        dw ItemMaterial.BronzeRing;
        dw ItemMaterial.PlatinumRing;
        dw ItemMaterial.TitaniumRing;
        dw ItemMaterial.GoldRing;
        dw ItemMaterial.GhostWand;
        dw ItemMaterial.GraveWand;
        dw ItemMaterial.BoneWand;
        dw ItemMaterial.Wand;
        dw ItemMaterial.Grimoire;
        dw ItemMaterial.Chronicle;
        dw ItemMaterial.Tome;
        dw ItemMaterial.Book;
        dw ItemMaterial.DivineRobe;
        dw ItemMaterial.SilkRobe;
        dw ItemMaterial.LinenRobe;
        dw ItemMaterial.Robe;
        dw ItemMaterial.Shirt;
        dw ItemMaterial.Crown;
        dw ItemMaterial.DivineHood;
        dw ItemMaterial.SilkHood;
        dw ItemMaterial.LinenHood;
        dw ItemMaterial.Hood;
        dw ItemMaterial.BrightsilkSash;
        dw ItemMaterial.SilkSash;
        dw ItemMaterial.WoolSash;
        dw ItemMaterial.LinenSash;
        dw ItemMaterial.Sash;
        dw ItemMaterial.DivineSlippers;
        dw ItemMaterial.SilkSlippers;
        dw ItemMaterial.WoolShoes;
        dw ItemMaterial.LinenShoes;
        dw ItemMaterial.Shoes;
        dw ItemMaterial.DivineGloves;
        dw ItemMaterial.SilkGloves;
        dw ItemMaterial.WoolGloves;
        dw ItemMaterial.LinenGloves;
        dw ItemMaterial.Gloves;
        dw ItemMaterial.Katana;
        dw ItemMaterial.Falchion;
        dw ItemMaterial.Scimitar;
        dw ItemMaterial.LongSword;
        dw ItemMaterial.ShortSword;
        dw ItemMaterial.DemonHusk;
        dw ItemMaterial.DragonskinArmor;
        dw ItemMaterial.StuddedLeatherArmor;
        dw ItemMaterial.HardLeatherArmor;
        dw ItemMaterial.LeatherArmor;
        dw ItemMaterial.DemonCrown;
        dw ItemMaterial.DragonsCrown;
        dw ItemMaterial.WarCap;
        dw ItemMaterial.LeatherCap;
        dw ItemMaterial.Cap;
        dw ItemMaterial.DemonhideBelt;
        dw ItemMaterial.DragonskinBelt;
        dw ItemMaterial.StuddedLeatherBelt;
        dw ItemMaterial.HardLeatherBelt;
        dw ItemMaterial.LeatherBelt;
        dw ItemMaterial.DemonhideBoots;
        dw ItemMaterial.DragonskinBoots;
        dw ItemMaterial.StuddedLeatherBoots;
        dw ItemMaterial.HardLeatherBoots;
        dw ItemMaterial.LeatherBoots;
        dw ItemMaterial.DemonsHands;
        dw ItemMaterial.DragonskinGloves;
        dw ItemMaterial.StuddedLeatherGloves;
        dw ItemMaterial.HardLeatherGloves;
        dw ItemMaterial.LeatherGloves;
        dw ItemMaterial.Warhammer;
        dw ItemMaterial.Quarterstaff;
        dw ItemMaterial.Maul;
        dw ItemMaterial.Mace;
        dw ItemMaterial.Club;
        dw ItemMaterial.HolyChestplate;
        dw ItemMaterial.OrnateChestplate;
        dw ItemMaterial.PlateMail;
        dw ItemMaterial.ChainMail;
        dw ItemMaterial.RingMail;
        dw ItemMaterial.AncientHelm;
        dw ItemMaterial.OrnateHelm;
        dw ItemMaterial.GreatHelm;
        dw ItemMaterial.FullHelm;
        dw ItemMaterial.Helm;
        dw ItemMaterial.OrnateBelt;
        dw ItemMaterial.WarBelt;
        dw ItemMaterial.PlatedBelt;
        dw ItemMaterial.MeshBelt;
        dw ItemMaterial.HeavyBelt;
        dw ItemMaterial.HolyGreaves;
        dw ItemMaterial.OrnateGreaves;
        dw ItemMaterial.Greaves;
        dw ItemMaterial.ChainBoots;
        dw ItemMaterial.HeavyBoots;
        dw ItemMaterial.HolyGauntlets;
        dw ItemMaterial.OrnateGauntlets;
        dw ItemMaterial.Gauntlets;
        dw ItemMaterial.ChainGloves;
        dw ItemMaterial.HeavyGloves;
    }

    func material_density{syscall_ptr: felt*, range_check_ptr}(material_id: felt) -> (
        density: felt
    ) {
        alloc_locals;

        let (_, label_id) = unsigned_div_rem(material_id, 100);

        let isle10 = is_le(1000, material_id);
        let isle20 = is_le(2000, material_id);
        let isle30 = is_le(3000, material_id);
        let isle31 = is_le(3100, material_id);
        let isle32 = is_le(3200, material_id);
        let isle33 = is_le(3300, material_id);
        let isle34 = is_le(3400, material_id);
        let isle40 = is_le(4000, material_id);
        let isle50 = is_le(5000, material_id);
        let isle51 = is_le(5100, material_id);
        let isle52 = is_le(5200, material_id);

        let idx = label_id + isle10 * 1 + isle20 * 10 + isle30 * 7 + isle31 * 1 + isle32 * 12 +
            isle33 * 12 + isle34 * 12 + isle40 * 12 + isle50 * 2 + isle51 * 1 + isle52 * 10;

        let (label_location) = get_label_location(labels);
        return ([label_location + idx],);

        labels:
        dw MaterialDensity.generic;
        dw MaterialDensity.Metal.generic;
        dw MaterialDensity.Metal.ancient;
        dw MaterialDensity.Metal.holy;
        dw MaterialDensity.Metal.ornate;
        dw MaterialDensity.Metal.gold;
        dw MaterialDensity.Metal.silver;
        dw MaterialDensity.Metal.bronze;
        dw MaterialDensity.Metal.platinum;
        dw MaterialDensity.Metal.titanium;
        dw MaterialDensity.Metal.steel;
        dw MaterialDensity.Cloth.generic;
        dw MaterialDensity.Cloth.royal;
        dw MaterialDensity.Cloth.divine;
        dw MaterialDensity.Cloth.brightsilk;
        dw MaterialDensity.Cloth.silk;
        dw MaterialDensity.Cloth.wool;
        dw MaterialDensity.Cloth.linen;
        dw MaterialDensity.Biotic.generic;
        dw MaterialDensity.Biotic.Demon.generic;
        dw MaterialDensity.Biotic.Demon.blood;
        dw MaterialDensity.Biotic.Demon.bones;
        dw MaterialDensity.Biotic.Demon.brain;
        dw MaterialDensity.Biotic.Demon.eyes;
        dw MaterialDensity.Biotic.Demon.hide;
        dw MaterialDensity.Biotic.Demon.flesh;
        dw MaterialDensity.Biotic.Demon.hair;
        dw MaterialDensity.Biotic.Demon.heart;
        dw MaterialDensity.Biotic.Demon.entrails;
        dw MaterialDensity.Biotic.Demon.hands;
        dw MaterialDensity.Biotic.Demon.feet;
        dw MaterialDensity.Biotic.Dragon.generic;
        dw MaterialDensity.Biotic.Dragon.blood;
        dw MaterialDensity.Biotic.Dragon.bones;
        dw MaterialDensity.Biotic.Dragon.brain;
        dw MaterialDensity.Biotic.Dragon.eyes;
        dw MaterialDensity.Biotic.Dragon.skin;
        dw MaterialDensity.Biotic.Dragon.flesh;
        dw MaterialDensity.Biotic.Dragon.hair;
        dw MaterialDensity.Biotic.Dragon.heart;
        dw MaterialDensity.Biotic.Dragon.entrails;
        dw MaterialDensity.Biotic.Dragon.hands;
        dw MaterialDensity.Biotic.Dragon.feet;
        dw MaterialDensity.Biotic.Animal.generic;
        dw MaterialDensity.Biotic.Animal.blood;
        dw MaterialDensity.Biotic.Animal.bones;
        dw MaterialDensity.Biotic.Animal.brain;
        dw MaterialDensity.Biotic.Animal.eyes;
        dw MaterialDensity.Biotic.Animal.hide;
        dw MaterialDensity.Biotic.Animal.flesh;
        dw MaterialDensity.Biotic.Animal.hair;
        dw MaterialDensity.Biotic.Animal.heart;
        dw MaterialDensity.Biotic.Animal.entrails;
        dw MaterialDensity.Biotic.Animal.hands;
        dw MaterialDensity.Biotic.Animal.feet;
        dw MaterialDensity.Biotic.Human.generic;
        dw MaterialDensity.Biotic.Human.blood;
        dw MaterialDensity.Biotic.Human.bones;
        dw MaterialDensity.Biotic.Human.brain;
        dw MaterialDensity.Biotic.Human.eyes;
        dw MaterialDensity.Biotic.Human.hide;
        dw MaterialDensity.Biotic.Human.flesh;
        dw MaterialDensity.Biotic.Human.hair;
        dw MaterialDensity.Biotic.Human.heart;
        dw MaterialDensity.Biotic.Human.entrails;
        dw MaterialDensity.Biotic.Human.hands;
        dw MaterialDensity.Biotic.Human.feet;
        dw MaterialDensity.Paper.generic;
        dw MaterialDensity.Paper.magical;
        dw MaterialDensity.Wood.generic;
        dw MaterialDensity.Wood.Hard.generic;
        dw MaterialDensity.Wood.Hard.walnut;
        dw MaterialDensity.Wood.Hard.mahogany;
        dw MaterialDensity.Wood.Hard.maple;
        dw MaterialDensity.Wood.Hard.oak;
        dw MaterialDensity.Wood.Hard.rosewood;
        dw MaterialDensity.Wood.Hard.cherry;
        dw MaterialDensity.Wood.Hard.balsa;
        dw MaterialDensity.Wood.Hard.birch;
        dw MaterialDensity.Wood.Hard.holly;
        dw MaterialDensity.Wood.Soft.generic;
        dw MaterialDensity.Wood.Soft.cedar;
        dw MaterialDensity.Wood.Soft.pine;
        dw MaterialDensity.Wood.Soft.fir;
        dw MaterialDensity.Wood.Soft.hemlock;
        dw MaterialDensity.Wood.Soft.spruce;
        dw MaterialDensity.Wood.Soft.elder;
        dw MaterialDensity.Wood.Soft.yew;
    }

    func item_rank{syscall_ptr: felt*, range_check_ptr}(item_id: felt) -> (rank: felt) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + item_id - 1],);

        labels:
        dw ItemRank.Pendant;
        dw ItemRank.Necklace;
        dw ItemRank.Amulet;
        dw ItemRank.SilverRing;
        dw ItemRank.BronzeRing;
        dw ItemRank.PlatinumRing;
        dw ItemRank.TitaniumRing;
        dw ItemRank.GoldRing;
        dw ItemRank.GhostWand;
        dw ItemRank.GraveWand;
        dw ItemRank.BoneWand;
        dw ItemRank.Wand;
        dw ItemRank.Grimoire;
        dw ItemRank.Chronicle;
        dw ItemRank.Tome;
        dw ItemRank.Book;
        dw ItemRank.DivineRobe;
        dw ItemRank.SilkRobe;
        dw ItemRank.LinenRobe;
        dw ItemRank.Robe;
        dw ItemRank.Shirt;
        dw ItemRank.Crown;
        dw ItemRank.DivineHood;
        dw ItemRank.SilkHood;
        dw ItemRank.LinenHood;
        dw ItemRank.Hood;
        dw ItemRank.BrightsilkSash;
        dw ItemRank.SilkSash;
        dw ItemRank.WoolSash;
        dw ItemRank.LinenSash;
        dw ItemRank.Sash;
        dw ItemRank.DivineSlippers;
        dw ItemRank.SilkSlippers;
        dw ItemRank.WoolShoes;
        dw ItemRank.LinenShoes;
        dw ItemRank.Shoes;
        dw ItemRank.DivineGloves;
        dw ItemRank.SilkGloves;
        dw ItemRank.WoolGloves;
        dw ItemRank.LinenGloves;
        dw ItemRank.Gloves;
        dw ItemRank.Katana;
        dw ItemRank.Falchion;
        dw ItemRank.Scimitar;
        dw ItemRank.LongSword;
        dw ItemRank.ShortSword;
        dw ItemRank.DemonHusk;
        dw ItemRank.DragonskinArmor;
        dw ItemRank.StuddedLeatherArmor;
        dw ItemRank.HardLeatherArmor;
        dw ItemRank.LeatherArmor;
        dw ItemRank.DemonCrown;
        dw ItemRank.DragonsCrown;
        dw ItemRank.WarCap;
        dw ItemRank.LeatherCap;
        dw ItemRank.Cap;
        dw ItemRank.DemonhideBelt;
        dw ItemRank.DragonskinBelt;
        dw ItemRank.StuddedLeatherBelt;
        dw ItemRank.HardLeatherBelt;
        dw ItemRank.LeatherBelt;
        dw ItemRank.DemonhideBoots;
        dw ItemRank.DragonskinBoots;
        dw ItemRank.StuddedLeatherBoots;
        dw ItemRank.HardLeatherBoots;
        dw ItemRank.LeatherBoots;
        dw ItemRank.DemonsHands;
        dw ItemRank.DragonskinGloves;
        dw ItemRank.StuddedLeatherGloves;
        dw ItemRank.HardLeatherGloves;
        dw ItemRank.LeatherGloves;
        dw ItemRank.Warhammer;
        dw ItemRank.Quarterstaff;
        dw ItemRank.Maul;
        dw ItemRank.Mace;
        dw ItemRank.Club;
        dw ItemRank.HolyChestplate;
        dw ItemRank.OrnateChestplate;
        dw ItemRank.PlateMail;
        dw ItemRank.ChainMail;
        dw ItemRank.RingMail;
        dw ItemRank.AncientHelm;
        dw ItemRank.OrnateHelm;
        dw ItemRank.GreatHelm;
        dw ItemRank.FullHelm;
        dw ItemRank.Helm;
        dw ItemRank.OrnateBelt;
        dw ItemRank.WarBelt;
        dw ItemRank.PlatedBelt;
        dw ItemRank.MeshBelt;
        dw ItemRank.HeavyBelt;
        dw ItemRank.HolyGreaves;
        dw ItemRank.OrnateGreaves;
        dw ItemRank.Greaves;
        dw ItemRank.ChainBoots;
        dw ItemRank.HeavyBoots;
        dw ItemRank.HolyGauntlets;
        dw ItemRank.OrnateGauntlets;
        dw ItemRank.Gauntlets;
        dw ItemRank.ChainGloves;
        dw ItemRank.HeavyGloves;
    }

    func item_name_prefix{syscall_ptr: felt*, range_check_ptr}(item_id: felt) -> (rank: felt) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + item_id - 1],);

        labels:
        dw ItemNamePrefixes.Agony;
        dw ItemNamePrefixes.Apocalypse;
        dw ItemNamePrefixes.Armageddon;
        dw ItemNamePrefixes.Beast;
        dw ItemNamePrefixes.Behemoth;
        dw ItemNamePrefixes.Blight;
        dw ItemNamePrefixes.Blood;
        dw ItemNamePrefixes.Bramble;
        dw ItemNamePrefixes.Brimstone;
        dw ItemNamePrefixes.Brood;
        dw ItemNamePrefixes.Carrion;
        dw ItemNamePrefixes.Cataclysm;
        dw ItemNamePrefixes.Chimeric;
        dw ItemNamePrefixes.Corpse;
        dw ItemNamePrefixes.Corruption;
        dw ItemNamePrefixes.Damnation;
        dw ItemNamePrefixes.Death;
        dw ItemNamePrefixes.Demon;
        dw ItemNamePrefixes.Dire;
        dw ItemNamePrefixes.Dragon;
        dw ItemNamePrefixes.Dread;
        dw ItemNamePrefixes.Doom;
        dw ItemNamePrefixes.Dusk;
        dw ItemNamePrefixes.Eagle;
        dw ItemNamePrefixes.Empyrean;
        dw ItemNamePrefixes.Fate;
        dw ItemNamePrefixes.Foe;
        dw ItemNamePrefixes.Gale;
        dw ItemNamePrefixes.Ghoul;
        dw ItemNamePrefixes.Gloom;
        dw ItemNamePrefixes.Glyph;
        dw ItemNamePrefixes.Golem;
        dw ItemNamePrefixes.Grim;
        dw ItemNamePrefixes.Hate;
        dw ItemNamePrefixes.Havoc;
        dw ItemNamePrefixes.Honour;
        dw ItemNamePrefixes.Horror;
        dw ItemNamePrefixes.Hypnotic;
        dw ItemNamePrefixes.Kraken;
        dw ItemNamePrefixes.Loath;
        dw ItemNamePrefixes.Maelstrom;
        dw ItemNamePrefixes.Mind;
        dw ItemNamePrefixes.Miracle;
        dw ItemNamePrefixes.Morbid;
        dw ItemNamePrefixes.Oblivion;
        dw ItemNamePrefixes.Onslaught;
        dw ItemNamePrefixes.Pain;
        dw ItemNamePrefixes.Pandemonium;
        dw ItemNamePrefixes.Phoenix;
        dw ItemNamePrefixes.Plague;
        dw ItemNamePrefixes.Rage;
        dw ItemNamePrefixes.Rapture;
        dw ItemNamePrefixes.Rune;
        dw ItemNamePrefixes.Skull;
        dw ItemNamePrefixes.Sol;
        dw ItemNamePrefixes.Soul;
        dw ItemNamePrefixes.Sorrow;
        dw ItemNamePrefixes.Spirit;
        dw ItemNamePrefixes.Storm;
        dw ItemNamePrefixes.Tempest;
        dw ItemNamePrefixes.Torment;
        dw ItemNamePrefixes.Vengeance;
        dw ItemNamePrefixes.Victory;
        dw ItemNamePrefixes.Viper;
        dw ItemNamePrefixes.Vortex;
        dw ItemNamePrefixes.Woe;
        dw ItemNamePrefixes.Wrath;
        dw ItemNamePrefixes.Lights;
        dw ItemNamePrefixes.Shimmering;
    }

    func item_name_suffix{syscall_ptr: felt*, range_check_ptr}(item_id: felt) -> (rank: felt) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + item_id - 1],);

        labels:
        dw ItemNameSuffixes.Bane;
        dw ItemNameSuffixes.Root;
        dw ItemNameSuffixes.Bite;
        dw ItemNameSuffixes.Song;
        dw ItemNameSuffixes.Roar;
        dw ItemNameSuffixes.Grasp;
        dw ItemNameSuffixes.Instrument;
        dw ItemNameSuffixes.Glow;
        dw ItemNameSuffixes.Bender;
        dw ItemNameSuffixes.Shadow;
        dw ItemNameSuffixes.Whisper;
        dw ItemNameSuffixes.Shout;
        dw ItemNameSuffixes.Growl;
        dw ItemNameSuffixes.Tear;
        dw ItemNameSuffixes.Peak;
        dw ItemNameSuffixes.Form;
        dw ItemNameSuffixes.Sun;
        dw ItemNameSuffixes.Moon;
    }

    func item_suffix{syscall_ptr: felt*, range_check_ptr}(item_id: felt) -> (rank: felt) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + item_id - 1],);

        labels:
        dw ItemSuffixes.of_Power;
        dw ItemSuffixes.of_Giant;
        dw ItemSuffixes.of_Titans;
        dw ItemSuffixes.of_Skill;
        dw ItemSuffixes.of_Perfection;
        dw ItemSuffixes.of_Brilliance;
        dw ItemSuffixes.of_Enlightenment;
        dw ItemSuffixes.of_Protection;
        dw ItemSuffixes.of_Anger;
        dw ItemSuffixes.of_Rage;
        dw ItemSuffixes.of_Fury;
        dw ItemSuffixes.of_Vitriol;
        dw ItemSuffixes.of_the_Fox;
        dw ItemSuffixes.of_Detection;
        dw ItemSuffixes.of_Reflection;
        dw ItemSuffixes.of_the_Twins;
    }
}
