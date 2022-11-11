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
from contracts.loot.constants.item import Item, ItemIds
from contracts.settling_game.utils.game_structs import ExternalContractIds

from contracts.loot.loot.ILoot import ILoot
from contracts.settling_game.interfaces.IRealms import IRealms
from contracts.settling_game.interfaces.Imodules import IModuleController

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

    namespace OrderNames {
        const Power = 345467479410;
        const Giants = 78517931766899;
        const Titans = 92811900841587;
        const Skill = 358284356716;
        const Perfection = 379660683168662059315054;
        const Brilliance = 313786713259670802162533;
        const Enlightenment = 5500917626309127724772157124212;
        const Protection = 379900278609487843651438;
        const Twins = 362780651123;
        const Reflection = 389104553132122754871150;
        const Detection = 1261689176585207902062;
        const Fox = 4616056;
        const Vitriol = 24322796853751660;
        const Fury = 1182102137;
        const Rage = 1382115173;
        const Anger = 281025144178;
    }

    namespace RaceNames {
        const Elf = 'Elf';
        const Fox = 'Fox';
        const Giant = 'Giant';
        const Human = 'Human';
        const Orc = 'Orc';
        const Demon = 'Demon';
        const Goblin = 'Goblin';
        const Fish = 'Fish';
        const Cat = 'Cat';
        const Frog = 'Frog';
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
        const GoldRing = 'Gold Ring';
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
    func build{syscall_ptr: felt*, range_check_ptr}(
        adventurer_id: Uint256, adventurer_data: AdventurerState, controller: felt, item_address: felt
    ) -> (encoded_len: felt, encoded: felt*) {
        alloc_locals;

        let (realms_address) = IModuleController.get_external_contract_address(
            controller, ExternalContractIds.Realms
        );

        let (weapon_item: Item) = ILoot.getItemByTokenId(
            item_address, Uint256(adventurer_data.WeaponId, 0)
        );
        let (chest_item: Item) = ILoot.getItemByTokenId(
            item_address, Uint256(adventurer_data.ChestId, 0)
        );
        let (head_item: Item) = ILoot.getItemByTokenId(
            item_address, Uint256(adventurer_data.HeadId, 0)
        );
        let (waist_item: Item) = ILoot.getItemByTokenId(
            item_address, Uint256(adventurer_data.WaistId, 0)
        );
        let (feet_item: Item) = ILoot.getItemByTokenId(
            item_address, Uint256(adventurer_data.FeetId, 0)
        );
        let (hands_item: Item) = ILoot.getItemByTokenId(
            item_address, Uint256(adventurer_data.HandsId, 0)
        );
        let (neck_item: Item) = ILoot.getItemByTokenId(
            item_address, Uint256(adventurer_data.NeckId, 0)
        );
        let (ring_item: Item) = ILoot.getItemByTokenId(
            item_address, Uint256(adventurer_data.RingId, 0)
        );

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
        let image_url_2 = '.cloudfront.net/Adventurer/';

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

        let (race_index) = append_race_name(adventurer_data.Race, id_index + 5, values);

        // home realm
        assert values[race_index] = Utils.TraitKeys.HomeRealm;
        assert values[race_index + 1] = Utils.TraitKeys.ValueKey;

        let (realm_name) = IRealms.get_realm_name(realms_address, Uint256(adventurer_data.HomeRealm, 0));

        assert values[race_index + 2] = realm_name;
        assert values[race_index + 3] = inverted_commas;
        assert values[race_index + 4] = right_bracket;
        assert values[race_index + 5] = comma;
        // birth date
        assert values[race_index + 6] = Utils.TraitKeys.Birthdate;
        assert values[race_index + 7] = Utils.TraitKeys.ValueKey;

        let (birthdate_size) = append_felt_ascii(adventurer_data.Birthdate, values + race_index + 8);
        let birthdate_index = race_index + 8 + birthdate_size;

        assert values[birthdate_index] = inverted_commas;
        assert values[birthdate_index + 1] = right_bracket;
        assert values[birthdate_index + 2] = comma;
        // health
        assert values[birthdate_index + 3] = Utils.TraitKeys.Health;
        assert values[birthdate_index + 4] = Utils.TraitKeys.ValueKey;

        let (health_size) = append_felt_ascii(adventurer_data.Health, values + birthdate_index + 5);
        let health_index =  birthdate_index + 5 + health_size;
        
        assert values[health_index] = inverted_commas;
        assert values[health_index + 1] = right_bracket;
        assert values[health_index + 2] = comma;
        // level
        assert values[health_index + 3] = Utils.TraitKeys.Level;
        assert values[health_index + 4] = Utils.TraitKeys.ValueKey;

        let (level_size) = append_felt_ascii(adventurer_data.Level, values + health_index + 5);
        let level_index = health_index + 5 + level_size;

        assert values[level_index] = inverted_commas;
        assert values[level_index + 1] = right_bracket;
        assert values[level_index + 2] = comma;

        let (order_index) = append_order_name(adventurer_data.Order, level_index + 3, values);
        
        // strength
        assert values[order_index] = Utils.TraitKeys.Strength;
        assert values[order_index + 1] = Utils.TraitKeys.ValueKey;

        let (strength_size) = append_felt_ascii(adventurer_data.Strength, values + order_index + 2);
        let strength_index = order_index + 2 + strength_size;
        
        assert values[strength_index] = inverted_commas;
        assert values[strength_index + 1] = right_bracket;
        assert values[strength_index + 2] = comma;
        // dexterity
        assert values[strength_index + 3] = Utils.TraitKeys.Dexterity;
        assert values[strength_index + 4] = Utils.TraitKeys.ValueKey;

        let (dexterity_size) = append_felt_ascii(adventurer_data.Dexterity, values + strength_index + 5);
        let dexterity_index = strength_index + 5 + dexterity_size;
        
        assert values[dexterity_index] = inverted_commas;
        assert values[dexterity_index + 1] = right_bracket;
        assert values[dexterity_index + 2] = comma;
        // vitality
        assert values[dexterity_index + 3] = Utils.TraitKeys.Vitality;
        assert values[dexterity_index + 4] = Utils.TraitKeys.ValueKey;

        let (vitality_size) = append_felt_ascii(adventurer_data.Vitality, values + dexterity_index + 5);
        let vitality_index = dexterity_index + 5 + vitality_size;
        
        assert values[vitality_index] = inverted_commas;
        assert values[vitality_index + 1] = right_bracket;
        assert values[vitality_index + 2] = comma;
        // intelligence
        assert values[vitality_index + 3] = Utils.TraitKeys.Intelligence;
        assert values[vitality_index + 4] = Utils.TraitKeys.ValueKey;

        let (intelligence_size) = append_felt_ascii(adventurer_data.Intelligence, values + vitality_index + 5);
        let intelligence_index = vitality_index + 5 + intelligence_size;
        
        assert values[intelligence_index] = inverted_commas;
        assert values[intelligence_index + 1] = right_bracket;
        assert values[intelligence_index + 2] = comma;
        // wisdom
        assert values[intelligence_index + 3] = Utils.TraitKeys.Wisdom;
        assert values[intelligence_index + 4] = Utils.TraitKeys.ValueKey;

        let (wisdom_size) = append_felt_ascii(adventurer_data.Wisdom, values + intelligence_index + 5);
        let wisdom_index = intelligence_index + 5 + wisdom_size;
        
        assert values[wisdom_index] = inverted_commas;
        assert values[wisdom_index + 1] = right_bracket;
        assert values[wisdom_index + 2] = comma;
        // charisma
        assert values[wisdom_index + 3] = Utils.TraitKeys.Charisma;
        assert values[wisdom_index + 4] = Utils.TraitKeys.ValueKey;

        let (charisma_size) = append_felt_ascii(adventurer_data.Charisma, values + wisdom_index + 5);
        let charisma_index = wisdom_index + 5 + charisma_size;
        
        assert values[charisma_index] = inverted_commas;
        assert values[charisma_index + 1] = right_bracket;
        assert values[charisma_index + 2] = comma;
        // luck
        assert values[charisma_index + 3] = Utils.TraitKeys.Luck;
        assert values[charisma_index + 4] = Utils.TraitKeys.ValueKey;

        let (luck_size) = append_felt_ascii(adventurer_data.Luck, values + charisma_index + 5);
        let luck_index = charisma_index + 5 + luck_size;
        
        assert values[luck_index] = inverted_commas;
        assert values[luck_index + 1] = right_bracket;
        assert values[luck_index + 2] = comma;
        // XP
        assert values[luck_index + 3] = Utils.TraitKeys.XP;
        assert values[luck_index + 4] = Utils.TraitKeys.ValueKey;

        let (xp_size) = append_felt_ascii(adventurer_data.XP, values + luck_index + 5);
        let xp_index = luck_index + 5 + xp_size;
        
        assert values[xp_index] = inverted_commas;
        assert values[xp_index + 1] = right_bracket;
        assert values[xp_index + 2] = comma;

        let (weapon_index) = append_weapon(weapon_item.Id, xp_index + 3, values);
        let (chest_index) = append_chest_item(chest_item.Id, weapon_index, values);
        let (head_index) = append_head_item(head_item.Id, chest_index, values);
        let (waist_index) = append_waist_item(waist_item.Id, head_index, values);
        let (foot_index) = append_foot_item(feet_item.Id, waist_index, values);
        let (hand_index) = append_hand_item(hands_item.Id, foot_index, values);
        let (neck_index) = append_neck_item(neck_item.Id, hand_index, values);
        let (ring_index) = append_ring_item(ring_item.Id, neck_index, values);

        assert values[ring_index] = right_square_bracket;
        assert values[ring_index + 1] = right_bracket;

        return (encoded_len=ring_index + 2, encoded=values);
    }

    // @notice append felts to uri array for race
    // @implicit range_check_ptr
    // @param race: id of the race, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    func append_race_name{range_check_ptr}(race: felt, values_index: felt, values: felt*) -> (
        race_index: felt
    ) {
        if (race == 0) {
            return (values_index,);
        }
        if (race == 1) {
            assert values[values_index + 2] = Utils.RaceNames.Elf;
        }
        if (race == 2) {
            assert values[values_index + 2] = Utils.RaceNames.Fox;
        }
        if (race == 3) {
            assert values[values_index + 2] = Utils.RaceNames.Giant;
        }
        if (race == 4) {
            assert values[values_index + 2] = Utils.RaceNames.Human;
        }
        if (race == 5) {
            assert values[values_index + 2] = Utils.RaceNames.Orc;
        }
        if (race == 6) {
            assert values[values_index + 2] = Utils.RaceNames.Demon;
        }
        if (race == 7) {
            assert values[values_index + 2] = Utils.RaceNames.Goblin;
        }
        if (race == 8) {
            assert values[values_index + 2] = Utils.RaceNames.Fish;
        }
        if (race == 9) {
            assert values[values_index + 2] = Utils.RaceNames.Cat;
        }
        if (race == 10) {
            assert values[values_index + 2] = Utils.RaceNames.Frog;
        }

        let race_key = Utils.TraitKeys.Race;
        let value_key = Utils.TraitKeys.ValueKey;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        assert values[values_index] = race_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;
        assert values[values_index + 5] = comma;

        return (values_index + 6,);
    }
    
    // @notice append felts to uri array for order
    // @implicit range_check_ptr
    // @param order: id of the order, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    func append_order_name{range_check_ptr}(order: felt, values_index: felt, values: felt*) -> (
        order_index: felt
    ) {
        if (order == 0) {
            return (values_index,);
        }
        if (order == 1) {
            assert values[values_index + 2] = Utils.OrderNames.Power;
        }
        if (order == 2) {
            assert values[values_index + 2] = Utils.OrderNames.Giants;
        }
        if (order == 3) {
            assert values[values_index + 2] = Utils.OrderNames.Titans;
        }
        if (order == 4) {
            assert values[values_index + 2] = Utils.OrderNames.Skill;
        }
        if (order == 5) {
            assert values[values_index + 2] = Utils.OrderNames.Perfection;
        }
        if (order == 6) {
            assert values[values_index + 2] = Utils.OrderNames.Brilliance;
        }
        if (order == 7) {
            assert values[values_index + 2] = Utils.OrderNames.Enlightenment;
        }
        if (order == 8) {
            assert values[values_index + 2] = Utils.OrderNames.Protection;
        }
        if (order == 9) {
            assert values[values_index + 2] = Utils.OrderNames.Twins;
        }
        if (order == 10) {
            assert values[values_index + 2] = Utils.OrderNames.Reflection;
        }
        if (order == 11) {
            assert values[values_index + 2] = Utils.OrderNames.Detection;
        }
        if (order == 12) {
            assert values[values_index + 2] = Utils.OrderNames.Fox;
        }
        if (order == 13) {
            assert values[values_index + 2] = Utils.OrderNames.Vitriol;
        }
        if (order == 14) {
            assert values[values_index + 2] = Utils.OrderNames.Fury;
        }
        if (order == 15) {
            assert values[values_index + 2] = Utils.OrderNames.Rage;
        }
        if (order == 16) {
            assert values[values_index + 2] = Utils.OrderNames.Anger;
        }

        let order_key = Utils.TraitKeys.Order;
        let value_key = Utils.TraitKeys.ValueKey;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        assert values[values_index] = order_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;
        assert values[values_index + 5] = comma;

        return (values_index + 6,);
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
        let comma = Utils.Symbols.Comma;

        assert values[values_index] = weapon_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;
        assert values[values_index + 5] = comma;

        return (values_index + 6,);
    }

    // @notice append felts to uri array for chest item
    // @implicit range_check_ptr
    // @param chest_id: id of the chest item, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return chest_index: new index of the array
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
        let comma = Utils.Symbols.Comma;

        assert values[values_index] = chest_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;
        assert values[values_index + 5] = comma;

        return (values_index + 6,);
    }

    // @notice append felts to uri array for head item
    // @implicit range_check_ptr
    // @param head_id: id of the head item, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return head_index: new index of the array
    func append_head_item{range_check_ptr}(head_id: felt, values_index: felt, values: felt*) -> (
        head_index: felt
    ) {
        if (head_id == 0) {
            return (values_index,);
        }
        if (head_id == ItemIds.Crown) {
            assert values[values_index + 2] = Utils.HeadItems.Crown;
        }
        if (head_id == ItemIds.DivineHood) {
            assert values[values_index + 2] = Utils.HeadItems.DivineHood;
        }
        if (head_id == ItemIds.SilkHood) {
            assert values[values_index + 2] = Utils.HeadItems.SilkHood;
        }
        if (head_id == ItemIds.LinenHood) {
            assert values[values_index + 2] = Utils.HeadItems.LinenHood;
        }
        if (head_id == ItemIds.Hood) {
            assert values[values_index + 2] = Utils.HeadItems.Hood;
        }
        if (head_id == ItemIds.DemonCrown) {
            assert values[values_index + 2] = Utils.HeadItems.DemonCrown;
        }
        if (head_id == ItemIds.DragonsCrown) {
            assert values[values_index + 2] = Utils.HeadItems.DragonsCrown;
        }
        if (head_id == ItemIds.WarCap) {
            assert values[values_index + 2] = Utils.HeadItems.WarCap;
        }
        if (head_id == ItemIds.LeatherCap) {
            assert values[values_index + 2] = Utils.HeadItems.LeatherCap;
        }
        if (head_id == ItemIds.Cap) {
            assert values[values_index + 2] = Utils.HeadItems.Cap;
        }
        if (head_id == ItemIds.AncientHelm) {
            assert values[values_index + 2] = Utils.HeadItems.AncientHelm;
        }
        if (head_id == ItemIds.OrnateHelm) {
            assert values[values_index + 2] = Utils.HeadItems.OrnateHelm;
        }
        if (head_id == ItemIds.GreatHelm) {
            assert values[values_index + 2] = Utils.HeadItems.GreatHelm;
        }
        if (head_id == ItemIds.FullHelm) {
            assert values[values_index + 2] = Utils.HeadItems.FullHelm;
        }
        if (head_id == ItemIds.Helm) {
            assert values[values_index + 2] = Utils.HeadItems.Helm;
        }

        let head_key = Utils.TraitKeys.Head;
        let value_key = Utils.TraitKeys.ValueKey;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        assert values[values_index] = head_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;
        assert values[values_index + 5] = comma;

        return (values_index + 6,);
    }

    // @notice append felts to uri array for waist item
    // @implicit range_check_ptr
    // @param waist_id: id of the waist item, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return waist_index: new index of the array
    func append_waist_item{range_check_ptr}(waist_id: felt, values_index: felt, values: felt*) -> (
        waist_index: felt
    ) {
        if (waist_id == 0) {
            return (values_index,);
        }
        if (waist_id == ItemIds.BrightsilkSash) {
            assert values[values_index + 2] = Utils.WaistItems.BrightsilkSash;
        }
        if (waist_id == ItemIds.SilkSash) {
            assert values[values_index + 2] = Utils.WaistItems.SilkSash;
        }
        if (waist_id == ItemIds.WoolSash) {
            assert values[values_index + 2] = Utils.WaistItems.WoolSash;
        }
        if (waist_id == ItemIds.LinenSash) {
            assert values[values_index + 2] = Utils.WaistItems.LinenSash;
        }
        if (waist_id == ItemIds.Sash) {
            assert values[values_index + 2] = Utils.WaistItems.Sash;
        }
        if (waist_id == ItemIds.DemonhideBelt) {
            assert values[values_index + 2] = Utils.WaistItems.DemonhideBelt;
        }
        if (waist_id == ItemIds.DragonskinBelt) {
            assert values[values_index + 2] = Utils.WaistItems.DragonskinBelt;
        }
        if (waist_id == ItemIds.StuddedLeatherBelt) {
            assert values[values_index + 2] = Utils.WaistItems.StuddedLeatherBelt;
        }
        if (waist_id == ItemIds.HardLeatherBelt) {
            assert values[values_index + 2] = Utils.WaistItems.HardLeatherBelt;
        }
        if (waist_id == ItemIds.LeatherBelt) {
            assert values[values_index + 2] = Utils.WaistItems.LeatherBelt;
        }
        if (waist_id == ItemIds.OrnateBelt) {
            assert values[values_index + 2] = Utils.WaistItems.OrnateBelt;
        }
        if (waist_id == ItemIds.WarBelt) {
            assert values[values_index + 2] = Utils.WaistItems.WarBelt;
        }
        if (waist_id == ItemIds.PlatedBelt) {
            assert values[values_index + 2] = Utils.WaistItems.PlatedBelt;
        }
        if (waist_id == ItemIds.MeshBelt) {
            assert values[values_index + 2] = Utils.WaistItems.MeshBelt;
        }
        if (waist_id == ItemIds.HeavyBelt) {
            assert values[values_index + 2] = Utils.WaistItems.HeavyBelt;
        }

        let waist_key = Utils.TraitKeys.Waist;
        let value_key = Utils.TraitKeys.ValueKey;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        assert values[values_index] = waist_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;
        assert values[values_index + 5] = comma;

        return (values_index + 6,);
    }

    // @notice append felts to uri array for foot item
    // @implicit range_check_ptr
    // @param foot_id: id of the foot item, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return foot_index: new index of the array
    func append_foot_item{range_check_ptr}(foot_id: felt, values_index: felt, values: felt*) -> (
        foot_index: felt
    ) {
        if (foot_id == 0) {
            return (values_index,);
        }
        if (foot_id == ItemIds.DivineSlippers) {
            assert values[values_index + 2] = Utils.FootItems.DivineSlippers;
        }
        if (foot_id == ItemIds.SilkSlippers) {
            assert values[values_index + 2] = Utils.FootItems.SilkSlippers;
        }
        if (foot_id == ItemIds.WoolShoes) {
            assert values[values_index + 2] = Utils.FootItems.WoolShoes;
        }
        if (foot_id == ItemIds.LinenShoes) {
            assert values[values_index + 2] = Utils.FootItems.LinenShoes;
        }
        if (foot_id == ItemIds.Shoes) {
            assert values[values_index + 2] = Utils.FootItems.Shoes;
        }
        if (foot_id == ItemIds.DemonhideBoots) {
            assert values[values_index + 2] = Utils.FootItems.DemonhideBoots;
        }
        if (foot_id == ItemIds.DragonskinBoots) {
            assert values[values_index + 2] = Utils.FootItems.DragonskinBoots;
        }
        if (foot_id == ItemIds.StuddedLeatherBoots) {
            assert values[values_index + 2] = Utils.FootItems.StuddedLeatherBoots;
        }
        if (foot_id == ItemIds.HardLeatherBoots) {
            assert values[values_index + 2] = Utils.FootItems.HardLeatherBoots;
        }
        if (foot_id == ItemIds.LeatherBoots) {
            assert values[values_index + 2] = Utils.FootItems.LeatherBoots;
        }
        if (foot_id == ItemIds.ChainBoots) {
            assert values[values_index + 2] = Utils.FootItems.ChainBoots;
        }
        if (foot_id == ItemIds.HeavyBoots) {
            assert values[values_index + 2] = Utils.FootItems.HeavyBoots;
        }
        if (foot_id == ItemIds.HolyGauntlets) {
            assert values[values_index + 2] = Utils.FootItems.HolyGauntlets;
        }
        if (foot_id == ItemIds.OrnateGauntlets) {
            assert values[values_index + 2] = Utils.FootItems.OrnateGauntlets;
        }
        if (foot_id == ItemIds.Gauntlets) {
            assert values[values_index + 2] = Utils.FootItems.Gauntlets;
        }

        let foot_key = Utils.TraitKeys.Feet;
        let value_key = Utils.TraitKeys.ValueKey;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        assert values[values_index] = foot_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;
        assert values[values_index + 5] = comma;

        return (values_index + 6,);
    }

    // @notice append felts to uri array for hand item
    // @implicit range_check_ptr
    // @param hand_id: id of the hand item, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return hand_index: new index of the array
    func append_hand_item{range_check_ptr}(hand_id: felt, values_index: felt, values: felt*) -> (
        hand_index: felt
    ) {
        if (hand_id == 0) {
            return (values_index,);
        }
        if (hand_id == ItemIds.DivineGloves) {
            assert values[values_index + 2] = Utils.HandItems.DivineGloves;
        }
        if (hand_id == ItemIds.SilkGloves) {
            assert values[values_index + 2] = Utils.HandItems.SilkGloves;
        }
        if (hand_id == ItemIds.WoolGloves) {
            assert values[values_index + 2] = Utils.HandItems.WoolGloves;
        }
        if (hand_id == ItemIds.LinenGloves) {
            assert values[values_index + 2] = Utils.HandItems.LinenGloves;
        }
        if (hand_id == ItemIds.Gloves) {
            assert values[values_index + 2] = Utils.HandItems.Gloves;
        }
        if (hand_id == ItemIds.DemonsHands) {
            assert values[values_index + 2] = Utils.HandItems.DemonsHands;
        }
        if (hand_id == ItemIds.DragonskinGloves) {
            assert values[values_index + 2] = Utils.HandItems.DragonskinGloves;
        }
        if (hand_id == ItemIds.StuddedLeatherGloves) {
            assert values[values_index + 2] = Utils.HandItems.StuddedLeatherGloves;
        }
        if (hand_id == ItemIds.HardLeatherGloves) {
            assert values[values_index + 2] = Utils.HandItems.HardLeatherGloves;
        }
        if (hand_id == ItemIds.LeatherGloves) {
            assert values[values_index + 2] = Utils.HandItems.LeatherGloves;
        }
        if (hand_id == ItemIds.HolyGreaves) {
            assert values[values_index + 2] = Utils.HandItems.HolyGreaves;
        }
        if (hand_id == ItemIds.OrnateGreaves) {
            assert values[values_index + 2] = Utils.HandItems.OrnateGreaves;
        }
        if (hand_id == ItemIds.Greaves) {
            assert values[values_index + 2] = Utils.HandItems.Greaves;
        }
        if (hand_id == ItemIds.ChainGloves) {
            assert values[values_index + 2] = Utils.HandItems.ChainGloves;
        }
        if (hand_id == ItemIds.HeavyGloves) {
            assert values[values_index + 2] = Utils.HandItems.HeavyGloves;
        }

        let hand_key = Utils.TraitKeys.Hands;
        let value_key = Utils.TraitKeys.ValueKey;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        assert values[values_index] = hand_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;
        assert values[values_index + 5] = comma;

        return (values_index + 6,);
    }

    // @notice append felts to uri array for neck item
    // @implicit range_check_ptr
    // @param neck_id: id of the neck item, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return neck_index: new index of the array
    func append_neck_item{range_check_ptr}(neck_id: felt, values_index: felt, values: felt*) -> (
        neck_index: felt
    ) {
        if (neck_id == 0) {
            return (values_index,);
        }
        if (neck_id == ItemIds.Pendant) {
            assert values[values_index + 2] = Utils.NeckItems.Pendant;
        }
        if (neck_id == ItemIds.Necklace) {
            assert values[values_index + 2] = Utils.NeckItems.Necklace;
        }
        if (neck_id == ItemIds.Amulet) {
            assert values[values_index + 2] = Utils.NeckItems.Amulet;
        }

        let neck_key = Utils.TraitKeys.Neck;
        let value_key = Utils.TraitKeys.ValueKey;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        assert values[values_index] = neck_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;
        assert values[values_index + 5] = comma;

        return (values_index + 6,);
    }

    // @notice append felts to uri array for ring item
    // @implicit range_check_ptr
    // @param ring_id: id of the ring, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return ring_index: new index of the array
    func append_ring_item{range_check_ptr}(ring_id: felt, values_index: felt, values: felt*) -> (
        ring_index: felt
    ) {
        if (ring_id == 0) {
            return (values_index,);
        }
        if (ring_id == ItemIds.SilverRing) {
            assert values[values_index + 2] = Utils.Rings.SilverRing;
        }
        if (ring_id == ItemIds.BronzeRing) {
            assert values[values_index + 2] = Utils.Rings.BronzeRing;
        }
        if (ring_id == ItemIds.PlatinumRing) {
            assert values[values_index + 2] = Utils.Rings.PlatinumRing;
        }
        if (ring_id == ItemIds.TitaniumRing) {
            assert values[values_index + 2] = Utils.Rings.TitaniumRing;
        }
        if (ring_id == ItemIds.GoldRing) {
            assert values[values_index + 2] = Utils.Rings.GoldRing;
        }

        let ring_key = Utils.TraitKeys.Ring;
        let value_key = Utils.TraitKeys.ValueKey;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        assert values[values_index] = ring_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;
        assert values[values_index + 5] = comma;

        return (values_index + 6,);
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