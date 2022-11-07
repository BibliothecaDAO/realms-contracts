// amarna: disable=arithmetic-add,arithmetic-div,arithmetic-mul,arithmetic-sub
// -----------------------------------
//   module.Uri Library
//   Builds a JSON array which to represent Realm metadata
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_unsigned_div_rem
from starkware.cairo.common.math import unsigned_div_rem

from contracts.loot.constants.adventurer import AdventurerState
from contracts.loot.constants.item import ItemIds

namespace Utils {
    namespace Symbols {
        const LeftBracket = 123;
        const RightBracket = 125;
        const InvertedCommas = 34;
        const Comma = 44;
    }

    namespace TraitKeys {
        const Race = '{"trait_type":"Race",';
        const HomeRealm = '{"trait_type":"Home Realm",';
        const Birthdate = '{"trait_type":"Birthdate",';
        // evolving stats
        const Health = '{"trait_type":"Health",';
        const Level = '{"trait_type":"Level",';
        const Order = '{"trait_type":"Order",';
        // physical
        const Strength = '{"trait_type":"Strength",';
        const Dexterity = '{"trait_type":"Dexterity",';
        const Vitality = '{"trait_type":"Vitality",';
        // Mental
        const Intelligence = '{"trait_type":"Intelligence",';
        const Wisdom = '{"trait_type":"Wisdom",';
        const Charisma = '{"trait_type":"Charisma",';
        // Meta physical
        const Luck = '{"trait_type":"Luck",';
        // XP
        const XP = '{"trait_type":"XP",';
        // P2
        const Weapon = '{"trait_type":"Weapon",';
        const Chest = '{"trait_type":"Chest",';
        const Head = '{"trait_type":"Head",';
        const Waist = '{"trait_type":"Waist",';
        // Packed Stats p3
        const Feet = '{"trait_type":"Feet",';
        const Hands = '{"trait_type":"Hand",';
        const Neck = '{"trait_type":"Neck",';
        const Ring = '{"trait_type":"Ring",';
        const ValueKey = '"value":"';
    }

    namespace NeckItems {
        const Pendant = 'Pendant';
        const Necklace = 'Necklace';
        const Amulet = 'Amulet';
    }

    namespace Rings {
        const SilverRing = 'Silver Ring';
        const BronzeRing = 'Bronze Ring';
        const PlatinumRing = 'Platinum Ring';
        const TitaniumRing = 'Titanium Ring';
        const GoldRing = 'GoldRing';
    }

    namespace Weapons {
        const GhostWand = 'Ghost Wand';
        const GraveWand = 'Grave Wand';
        const BoneWand = 'Bone Wand';
        const Wand = 'Wand';
        const Grimoire = 'Grimoire';
        const Chronicle = 'Chronicle';
        const Tome = 'Tome';
        const Book = 'Book';
        const Katana = 'Katana';
        const Falchion = 'Falchion';
        const Scimitar = 'Scimitar';
        const LongSword = 'Long Sword';
        const ShortSword = 'Short Sword';
        const Warhammer = 'Warhammer';
        const Quarterstaff = 'Quarterstaff';
        const Maul = 'Maul';
        const Mace = 'Mace';
        const Club = 'Club';
    }

    namespace ChestItems {
        const DivineRobe = 'Divine Robe';
        const SilkRobe = 'Silk Robe';
        const LinenRobe = 'Linen Robe';
        const Robe = 'Robe';
        const Shirt = 'Shirt';
        const DemonHusk = 'Demon Husk';
        const DragonskinArmor = 'Dragonskin Armor';
        const StuddedLeatherArmor = 'Studded Leather Armor';
        const HardLeatherArmor = 'Hard Leather Armor';
        const LeatherArmor = 'Leather Armor';
        const HolyChestplate = 'Holy Chestplate';
        const OrnateChestplate = 'Ornate ChestPlate';
        const PlateMail = 'Plate Mail';
        const ChainMail = 'Chain Mail';
        const RingMail = 'Ring Mail';
    }

    namespace HeadItems {
        const Crown = 'Crown';
        const DivineHood = 'Divine Hood';
        const SilkHood = 'Silk Hood';
        const LinenHood = 'Linen Hood';
        const Hood = 'Hood';
        const DemonCrown = 'Demon Crown';
        const DragonsCrown = 'Dragons Crown';
        const WarCap = 'War Cap';
        const LeatherCap = 'Leather Cap';
        const Cap = 'Cap';
        const AncientHelm = 'Ancient Helm';
        const OrnateHelm = 'Ornate Helm';
        const GreatHelm = 'Great Helm';
        const FullHelm = 'Full Helm';
        const Helm = 'Helm';
    }

    namespace WaistItems {
        const BrightsilkSash = 'Brightsilk Sash';
        const SilkSash = 'Silk Sash';
        const WoolSash = 'Wool Sash';
        const LinenSash = 'Linen Sash';
        const Sash = 'Sash';
        const DemonhideBelt = 'Demonhide Belt';
        const DragonskinBelt = 'Dragonskin Belt';
        const StuddedLeatherBelt = 'Studded Leather Belt';
        const HardLeatherBelt = 'Hard Leather Belt';
        const LeatherBelt = 'Leather Belt';
        const OrnateBelt = 'Ornate Belt';
        const WarBelt = 'War Belt';
        const PlatedBelt = 'Plated Belt';
        const MeshBelt = 'Mesh Belt';
        const HeavyBelt = 'Heavy Belt';
    }

    namespace FootItems {
        const DivineSlippers = 'Divine Slippers';
        const SilkSlippers = 'Silk Slippers';
        const WoolShoes = 'Wool Shoes';
        const LinenShoes = 'Linen Shoes';
        const Shoes = 'Shoes';
        const DemonhideBoots = 'Demonhide Boots';
        const DragonskinBoots = 'Dragonskin Boots';
        const StuddedLeatherBoots = 'Studded Leather Boots';
        const HardLeatherBoots = 'Hard Leather Boots';
        const LeatherBoots = 'Leather Boots';
        const ChainBoots = 'Chain Boots';
        const HeavyBoots = 'Heavy Boots';
        const HolyGauntlets = 'Holy Gauntlets';
        const OrnateGauntlets = 'Ornate Gauntlets';
        const Gauntlets = 'Gauntlets';
    }

    namespace HandItems {
        const DivineGloves = 'Divine Gloves';
        const SilkGloves = 'Silk Gloves';
        const WoolGloves = 'Wool Gloves';
        const LinenGloves = 'Linen Gloves';
        const Gloves = 'Gloves';
        const DemonsHands = 'Demons Hands';
        const DragonskinGloves = 'Dragonskin Gloves';
        const StuddedLeatherGloves = 'Studded Leather Gloves';
        const HardLeatherGloves = 'Hard Leather Gloves';
        const LeatherGloves = 'Leather Gloves';
        const HolyGreaves = 'Holy Greaves';
        const OrnateGreaves = 'Ornate Greaves';
        const Greaves = 'Greaves';
        const ChainGloves = 'Chain Gloves';
        const HeavyGloves = 'Heavy Gloves';
    }
}

namespace Uri {
    // @notice build uri array from stored adventurer data
    // @implicit range_check_ptr
    // @param adventurer_id: id of the adventurer
    // @param adventurer_data: unpacked data for adventurer
    func build{range_check_ptr}(
        adventurer_id: Uint256, adventurer_data: AdventurerState
    ) -> (encoded_len: felt, encoded: felt*) {
        alloc_locals;

        // pre-defined for reusability
        let left_bracket = Utils.Symbols.LeftBracket;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        let data_format = 'data:application/json,';

        // keys
        let description_key = '"description":';
        let name_key = '"name":';
        let image_key = '"image":';
        let attributes_key = '"attributes":';

        let left_square_bracket = 91;
        let right_square_bracket = 93;

        // get value of description
        let description_value = '"Adventurer"';

        // adventurer image url values
        let image_url_1 = 'https://d23fdhqc1jb9no';
        let image_url_2 = '.cloudfront.net/_Realms/';

        let (values: felt*) = alloc();
        assert values [0] = data_format;
        assert values[1] = left_bracket;  // start
        // description key
        assert values[2] = description_key;
        assert values[3] = description_value;
        assert values[4] = comma;
        // name value
        assert values[5] = name_key;
        assert values[6] = inverted_commas;
        assert values[7] = adventurer_data.Name;
        assert values[8] = inverted_commas;
        assert values[9] = comma;
        // image value
        assert values[10] = image_key;
        assert values[11] = inverted_commas;
        assert values[12] = image_url_1;
        assert values[13] = image_url_2;
        let (id_size) = append_uint256_ascii(adventurer_id, values + 14);
        let id_index = 14 + id_size;
        assert values[id_index] = '.webp';
        assert values[id_index + 1] = inverted_commas;
        assert values[id_index + 2] = comma;
        assert values[id_index + 3] = attributes_key;
        assert values[id_index + 4] = left_square_bracket;
        // race
        assert values[id_index + 5] = Utils.TraitKeys.Race;
        assert values[id_index + 6] = Utils.TraitKeys.ValueKey;
        assert values[id_index + 7] = adventurer_data.Race;
        assert values[id_index + 8] = inverted_commas;
        assert values[id_index + 9] = right_bracket;
        // home realm
        assert values[id_index + 10] = Utils.TraitKeys.HomeRealm;
        assert values[id_index + 11] = Utils.TraitKeys.ValueKey;
        assert values[id_index + 12] = adventurer_data.HomeRealm;
        assert values[id_index + 13] = inverted_commas;
        assert values[id_index + 14] = right_bracket;
        // birth date
        assert values[id_index + 15] = Utils.TraitKeys.Birthdate;
        assert values[id_index + 16] = Utils.TraitKeys.ValueKey;
        assert values[id_index + 17] = adventurer_data.Birthdate;
        assert values[id_index + 18] = inverted_commas;
        assert values[id_index + 19] = right_bracket;
        // health
        assert values[id_index + 20] = Utils.TraitKeys.Health;
        assert values[id_index + 21] = Utils.TraitKeys.ValueKey;

        let (health_size) = append_felt_ascii(adventurer_data.Health, values + id_index + 22);
        let health_index = id_index + 22 + health_size;
        
        assert values[health_index] = inverted_commas;
        assert values[health_index + 1] = right_bracket;
        // level
        assert values[health_index + 2] = Utils.TraitKeys.Level;
        assert values[health_index + 3] = Utils.TraitKeys.ValueKey;

        let (level_size) = append_felt_ascii(adventurer_data.Level, values + health_index + 4);
        let level_index = health_index + 4 + level_size;
        
        assert values[level_index] = inverted_commas;
        assert values[level_index + 1] = right_bracket;
        // order
        assert values[level_index + 2] = Utils.TraitKeys.Order;
        assert values[level_index + 3] = Utils.TraitKeys.ValueKey;

        let (order_size) = append_felt_ascii(adventurer_data.Order, values + level_index + 4);
        let order_index = level_index + 4 + order_size;
        
        assert values[order_index] = inverted_commas;
        assert values[order_index + 1] = right_bracket;
        // strength
        assert values[order_index + 2] = Utils.TraitKeys.Strength;
        assert values[order_index + 3] = Utils.TraitKeys.ValueKey;

        let (strength_size) = append_felt_ascii(adventurer_data.Strength, values + order_index + 4);
        let strength_index = order_index + 4 + strength_size;
        
        assert values[strength_index] = inverted_commas;
        assert values[strength_index + 1] = right_bracket;
        // dexterity
        assert values[strength_index + 2] = Utils.TraitKeys.Dexterity;
        assert values[strength_index + 3] = Utils.TraitKeys.ValueKey;

        let (dexterity_size) = append_felt_ascii(adventurer_data.Dexterity, values + strength_index + 4);
        let dexterity_index = strength_index + 4 + dexterity_size;
        
        assert values[dexterity_index] = inverted_commas;
        assert values[dexterity_index + 1] = right_bracket;
        // vitality
        assert values[dexterity_index + 2] = Utils.TraitKeys.Vitality;
        assert values[dexterity_index + 3] = Utils.TraitKeys.ValueKey;

        let (vitality_size) = append_felt_ascii(adventurer_data.Vitality, values + dexterity_index + 4);
        let vitality_index = dexterity_index + 4 + vitality_size;
        
        assert values[vitality_index] = inverted_commas;
        assert values[vitality_index + 1] = right_bracket;
        // intelligence
        assert values[vitality_index + 2] = Utils.TraitKeys.Intelligence;
        assert values[vitality_index + 3] = Utils.TraitKeys.ValueKey;

        let (intelligence_size) = append_felt_ascii(adventurer_data.Intelligence, values + vitality_index + 4);
        let intelligence_index = vitality_index + 4 + intelligence_size;
        
        assert values[intelligence_index] = inverted_commas;
        assert values[intelligence_index + 1] = right_bracket;
        // wisdom
        assert values[intelligence_index + 2] = Utils.TraitKeys.Wisdom;
        assert values[intelligence_index + 3] = Utils.TraitKeys.ValueKey;

        let (wisdom_size) = append_felt_ascii(adventurer_data.Wisdom, values + intelligence_index + 4);
        let wisdom_index = intelligence_index + 4 + wisdom_size;
        
        assert values[wisdom_index] = inverted_commas;
        assert values[wisdom_index + 1] = right_bracket;
        // charisma
        assert values[wisdom_index + 2] = Utils.TraitKeys.Charisma;
        assert values[wisdom_index + 3] = Utils.TraitKeys.ValueKey;

        let (charisma_size) = append_felt_ascii(adventurer_data.Charisma, values + wisdom_index + 4);
        let charisma_index = wisdom_index + 4 + charisma_size;
        
        assert values[charisma_index] = inverted_commas;
        assert values[charisma_index + 1] = right_bracket;
        // luck
        assert values[charisma_index + 2] = Utils.TraitKeys.Luck;
        assert values[charisma_index + 3] = Utils.TraitKeys.ValueKey;

        let (luck_size) = append_felt_ascii(adventurer_data.Luck, values + charisma_index + 4);
        let luck_index = charisma_index + 4 + luck_size;
        
        assert values[luck_index] = inverted_commas;
        assert values[luck_index + 1] = right_bracket;
        // XP
        assert values[luck_index + 2] = Utils.TraitKeys.XP;
        assert values[luck_index + 3] = Utils.TraitKeys.ValueKey;

        let (xp_size) = append_felt_ascii(adventurer_data.XP, values + luck_index + 4);
        let xp_index = luck_index + 4 + xp_size;
        
        assert values[xp_index] = inverted_commas;
        assert values[xp_index + 1] = right_bracket;

        // Weapon
        let (weapon_index) = append_weapon(adventurer_data.WeaponId, xp_index + 2, values);

        // Chest
        let (chest_index) = append_chest_item(adventurer_data.ChestId, weapon_index, values);

        return (encoded_len=chest_index, encoded=values);
    }

    // @notice append felts to uri array for weapon
    // @implicit range_check_ptr
    // @param weapon_id: id of the weapon, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return weapon_index: new index of the array
    func append_weapon{range_check_ptr}(weapon_id: felt, values_index: felt, values: felt*) -> (
        weapon_index: felt
    ) {
        if (weapon_id == 0) {
            return (values_index,);
        }
        if (weapon_id == ItemIds.GhostWand) {
            assert values[values_index + 2] = Utils.Weapons.GhostWand;
        }
        if (weapon_id == ItemIds.GraveWand) {
            assert values[values_index + 2] = Utils.Weapons.GraveWand;
        }
        if (weapon_id == ItemIds.BoneWand) {
            assert values[values_index + 2] = Utils.Weapons.BoneWand;
        }
        if (weapon_id == ItemIds.Wand) {
            assert values[values_index + 2] = Utils.Weapons.Wand;
        }
        if (weapon_id == ItemIds.Grimoire) {
            assert values[values_index + 2] = Utils.Weapons.Grimoire;
        }
        if (weapon_id == ItemIds.Chronicle) {
            assert values[values_index + 2] = Utils.Weapons.Chronicle;
        }
        if (weapon_id == ItemIds.Tome) {
            assert values[values_index + 2] = Utils.Weapons.Tome;
        }
        if (weapon_id == ItemIds.Book) {
            assert values[values_index + 2] = Utils.Weapons.Book;
        }
        if (weapon_id == ItemIds.Katana) {
            assert values[values_index + 2] = Utils.Weapons.Katana;
        }
        if (weapon_id == ItemIds.Falchion) {
            assert values[values_index + 2] = Utils.Weapons.Falchion;
        }
        if (weapon_id == ItemIds.Scimitar) {
            assert values[values_index + 2] = Utils.Weapons.Scimitar;
        }
        if (weapon_id == ItemIds.LongSword) {
            assert values[values_index + 2] = Utils.Weapons.LongSword;
        }
        if (weapon_id == ItemIds.ShortSword) {
            assert values[values_index + 2] = Utils.Weapons.ShortSword;
        }
        if (weapon_id == ItemIds.Warhammer) {
            assert values[values_index + 2] = Utils.Weapons.Warhammer;
        }
        if (weapon_id == ItemIds.Quarterstaff) {
            assert values[values_index + 2] = Utils.Weapons.Quarterstaff;
        }
        if (weapon_id == ItemIds.Maul) {
            assert values[values_index + 2] = Utils.Weapons.Maul;
        }
        if (weapon_id == ItemIds.Mace) {
            assert values[values_index + 2] = Utils.Weapons.Mace;
        }
        if (weapon_id == ItemIds.Club) {
            assert values[values_index + 2] = Utils.Weapons.Club;
        }

        let weapon_key = Utils.TraitKeys.Weapon;
        let value_key = Utils.TraitKeys.ValueKey;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;

        assert values[values_index] = weapon_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;

        return (values_index + 5,);
    }

    // @notice append felts to uri array for chest item
    // @implicit range_check_ptr
    // @param chest_id: id of the chest item, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return weapon_index: new index of the array
    func append_chest_item{range_check_ptr}(chest_id: felt, values_index: felt, values: felt*) -> (
        chest_index: felt
    ) {
        if (chest_id == 0) {
            return (values_index,);
        }
        if (chest_id == ItemIds.DivineRobe) {
            assert values[values_index + 2] = Utils.ChestItems.DivineRobe;
        }
        if (chest_id == ItemIds.SilkRobe) {
            assert values[values_index + 2] = Utils.ChestItems.SilkRobe;
        }
        if (chest_id == ItemIds.LinenRobe) {
            assert values[values_index + 2] = Utils.ChestItems.LinenRobe;
        }
        if (chest_id == ItemIds.Robe) {
            assert values[values_index + 2] = Utils.ChestItems.Robe;
        }
        if (chest_id == ItemIds.Shirt) {
            assert values[values_index + 2] = Utils.ChestItems.Shirt;
        }
        if (chest_id == ItemIds.DemonHusk) {
            assert values[values_index + 2] = Utils.ChestItems.DemonHusk;
        }
        if (chest_id == ItemIds.DragonskinArmor) {
            assert values[values_index + 2] = Utils.ChestItems.DragonskinArmor;
        }
        if (chest_id == ItemIds.StuddedLeatherArmor) {
            assert values[values_index + 2] = Utils.ChestItems.StuddedLeatherArmor;
        }
        if (chest_id == ItemIds.HardLeatherArmor) {
            assert values[values_index + 2] = Utils.ChestItems.HardLeatherArmor;
        }
        if (chest_id == ItemIds.LeatherArmor) {
            assert values[values_index + 2] = Utils.ChestItems.LeatherArmor;
        }
        if (chest_id == ItemIds.HolyChestplate) {
            assert values[values_index + 2] = Utils.ChestItems.HolyChestplate;
        }
        if (chest_id == ItemIds.OrnateChestplate) {
            assert values[values_index + 2] = Utils.ChestItems.OrnateChestplate;
        }
        if (chest_id == ItemIds.PlateMail) {
            assert values[values_index + 2] = Utils.ChestItems.PlateMail;
        }
        if (chest_id == ItemIds.ChainMail) {
            assert values[values_index + 2] = Utils.ChestItems.ChainMail;
        }
        if (chest_id == ItemIds.RingMail) {
            assert values[values_index + 2] = Utils.ChestItems.RingMail;
        }

        let chest_key = Utils.TraitKeys.Chest;
        let value_key = Utils.TraitKeys.ValueKey;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;

        assert values[values_index] = chest_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;

        return (values_index + 5,);
    }

    // @notice append ascii encoding of each number in felt
    // @implicit range_check_ptr
    // @param num: number to encode
    // @param arr: array to append encoding
    // @return added_len: length of encoding
    func append_felt_ascii{range_check_ptr}(num: felt, arr: felt*) -> (added_len: felt) {
        alloc_locals;
        let (q, r) = unsigned_div_rem(num, 10);
        let digit = r + 48;  // ascii

        if (q == 0) {
            assert arr[0] = digit;
            return (1,);
        }

        let (added_len) = append_felt_ascii(q, arr);
        assert arr[added_len] = digit;
        return (added_len + 1,);
    }

    // @notice append ascii encoding of each number in uint256
    // @implicit range_check_ptr
    // @param num: number to encode
    // @param arr: array to append encoding
    // @return added_len: length of encoding
    func append_uint256_ascii{range_check_ptr}(num: Uint256, arr: felt*) -> (added_len: felt) {
        alloc_locals;
        local ten: Uint256 = Uint256(10, 0);
        let (q: Uint256, r: Uint256) = uint256_unsigned_div_rem(num, ten);
        let digit = r.low + 48;  // ascii

        if (q.low == 0 and q.high == 0) {
            assert arr[0] = digit;
            return (1,);
        }

        let (added_len) = append_uint256_ascii(q, arr);
        assert arr[added_len] = digit;
        return (added_len + 1,);
    }
}