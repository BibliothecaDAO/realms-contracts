// amarna: disable=arithmetic-add,arithmetic-div,arithmetic-mul,arithmetic-sub
// -----------------------------------
//   loot.adventurer.Uri Library
//   Builds a JSON array which to represent Adventurer metadata
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import unsigned_div_rem

from contracts.loot.constants.adventurer import AdventurerState, AdventurerStatus
from contracts.loot.constants.beast import BeastIds
from contracts.loot.constants.item import Item, ItemIds
from contracts.loot.loot.metadata import LootUri
from contracts.loot.utils.constants import ModuleIds
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.utils.game_structs import ExternalContractIds

from contracts.loot.beast.interface import IBeast
from contracts.loot.loot.ILoot import ILoot
from contracts.settling_game.interfaces.IRealms import IRealms
from contracts.settling_game.interfaces.imodules import IModuleController

namespace AdventurerUriUtils {
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
        const Name = '{"trait_type":"Name",';
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
        // Stats
        const Weapon = '{"trait_type":"Weapon",';
        const Chest = '{"trait_type":"Chest",';
        const Head = '{"trait_type":"Head",';
        const Waist = '{"trait_type":"Waist",';
        const Feet = '{"trait_type":"Feet",';
        const Hands = '{"trait_type":"Hands",';
        const Neck = '{"trait_type":"Neck",';
        const Ring = '{"trait_type":"Ring",';
        const Status = '{"trait_type":"Status",';
        const Beast = '{"trait_type":"Beast",';
        const ValueKey = '"value":"';
    }

    namespace OrderNames {
        const Power = 'Power';
        const Giants = 'Giants';
        const Titans = 'Titans';
        const Skill = 'Skill';
        const Perfection = 'Perfection';
        const Brilliance = 'Brilliance';
        const Enlightenment = 'Enlightenment';
        const Protection = 'Protection';
        const Twins = 'Twins';
        const Reflection = 'Reflection';
        const Detection = 'Detection';
        const Fox = 'Fox';
        const Vitriol = 'Vitriol';
        const Fury = 'Fury';
        const Rage = 'Rage';
        const Anger = 'Anger';
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

    namespace Status {
        const Idle = 'Idle';
        const Battle = 'Battling';
        const Travel = 'Travelling';
        const Quest = 'Questing';
        const Dead = 'Dead';
    }

    namespace Beast {
        const Phoenix = 'Phoenix';
        const Griffin = 'Griffin';
        const Minotaur = 'Minotaur';
        const Basilisk = 'Basilisk';
        const Gnome = 'Gnome';
        const Giant = 'Giant';
        const Yeti = 'Yeti';
        const Orc = 'Orc';
        const Beserker = 'Beserker';
        const Ogre = 'Ogre';
        const Dragon = 'Dragon';
        const Vampire = 'Vampire';
        const Werewolf = 'Werewolf';
        const Spider = 'Spider';
        const Rat = 'Rat';
    }
}

namespace AdventurerUri {
    // @notice build uri array from stored adventurer data
    // @implicit range_check_ptr
    // @param adventurer_id: id of the adventurer
    // @param adventurer_data: unpacked data for adventurer
    func build{syscall_ptr: felt*, range_check_ptr}(
        adventurer_id: Uint256,
        adventurer_data: AdventurerState,
        item_address: felt,
        beast_address,
        realms_address: felt,
    ) -> (encoded_len: felt, encoded: felt*) {
        alloc_locals;

        let (weapon_item: Item) = ILoot.get_item_by_token_id(
            item_address, Uint256(adventurer_data.WeaponId, 0)
        );
        let (chest_item: Item) = ILoot.get_item_by_token_id(
            item_address, Uint256(adventurer_data.ChestId, 0)
        );
        let (head_item: Item) = ILoot.get_item_by_token_id(
            item_address, Uint256(adventurer_data.HeadId, 0)
        );
        let (waist_item: Item) = ILoot.get_item_by_token_id(
            item_address, Uint256(adventurer_data.WaistId, 0)
        );
        let (feet_item: Item) = ILoot.get_item_by_token_id(
            item_address, Uint256(adventurer_data.FeetId, 0)
        );
        let (hands_item: Item) = ILoot.get_item_by_token_id(
            item_address, Uint256(adventurer_data.HandsId, 0)
        );
        let (neck_item: Item) = ILoot.get_item_by_token_id(
            item_address, Uint256(adventurer_data.NeckId, 0)
        );
        let (ring_item: Item) = ILoot.get_item_by_token_id(
            item_address, Uint256(adventurer_data.RingId, 0)
        );

        // pre-defined for reusability
        let left_bracket = AdventurerUriUtils.Symbols.LeftBracket;
        let right_bracket = AdventurerUriUtils.Symbols.RightBracket;
        let inverted_commas = AdventurerUriUtils.Symbols.InvertedCommas;
        let comma = AdventurerUriUtils.Symbols.Comma;

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
        let image_url_1 = 'https://ipfs.io/ipfs/';
        let image_url_2 = adventurer_data.ImageHash1;
        let image_url_3 = adventurer_data.ImageHash2;

        let (values: felt*) = alloc();
        assert values[0] = data_format;
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
        assert values[14] = image_url_3;
        assert values[15] = '.webp';
        assert values[16] = inverted_commas;
        assert values[17] = comma;
        assert values[18] = attributes_key;
        assert values[19] = left_square_bracket;
        // race

        let (race_index) = append_race_name(adventurer_data.Race, 20, values);

        // home realm
        assert values[race_index] = AdventurerUriUtils.TraitKeys.HomeRealm;
        assert values[race_index + 1] = AdventurerUriUtils.TraitKeys.ValueKey;

        let (realm_name) = IRealms.get_realm_name(
            realms_address, Uint256(adventurer_data.HomeRealm, 0)
        );

        assert values[race_index + 2] = realm_name;
        assert values[race_index + 3] = inverted_commas;
        assert values[race_index + 4] = right_bracket;
        assert values[race_index + 5] = comma;

        let (order_index) = append_order_name(adventurer_data.Order, race_index + 6, values);

        // birth date
        assert values[order_index] = AdventurerUriUtils.TraitKeys.Birthdate;
        assert values[order_index + 1] = AdventurerUriUtils.TraitKeys.ValueKey;

        let (birthdate_size) = append_felt_ascii(
            adventurer_data.Birthdate, values + order_index + 2
        );
        let birthdate_index = order_index + 2 + birthdate_size;

        assert values[birthdate_index] = inverted_commas;
        assert values[birthdate_index + 1] = right_bracket;
        assert values[birthdate_index + 2] = comma;
        // health
        assert values[birthdate_index + 3] = AdventurerUriUtils.TraitKeys.Health;
        assert values[birthdate_index + 4] = AdventurerUriUtils.TraitKeys.ValueKey;

        let (health_size) = append_felt_ascii(adventurer_data.Health, values + birthdate_index + 5);
        let health_index = birthdate_index + 5 + health_size;

        assert values[health_index] = inverted_commas;
        assert values[health_index + 1] = right_bracket;
        assert values[health_index + 2] = comma;
        // level
        assert values[health_index + 3] = AdventurerUriUtils.TraitKeys.Level;
        assert values[health_index + 4] = AdventurerUriUtils.TraitKeys.ValueKey;

        let (level_size) = append_felt_ascii(adventurer_data.Level, values + health_index + 5);
        let level_index = health_index + 5 + level_size;

        assert values[level_index] = inverted_commas;
        assert values[level_index + 1] = right_bracket;
        assert values[level_index + 2] = comma;

        // strength
        assert values[level_index + 3] = AdventurerUriUtils.TraitKeys.Strength;
        assert values[level_index + 4] = AdventurerUriUtils.TraitKeys.ValueKey;

        let (strength_size) = append_felt_ascii(adventurer_data.Strength, values + level_index + 5);
        let strength_index = level_index + 5 + strength_size;

        assert values[strength_index] = inverted_commas;
        assert values[strength_index + 1] = right_bracket;
        assert values[strength_index + 2] = comma;
        // dexterity
        assert values[strength_index + 3] = AdventurerUriUtils.TraitKeys.Dexterity;
        assert values[strength_index + 4] = AdventurerUriUtils.TraitKeys.ValueKey;

        let (dexterity_size) = append_felt_ascii(
            adventurer_data.Dexterity, values + strength_index + 5
        );
        let dexterity_index = strength_index + 5 + dexterity_size;

        assert values[dexterity_index] = inverted_commas;
        assert values[dexterity_index + 1] = right_bracket;
        assert values[dexterity_index + 2] = comma;
        // vitality
        assert values[dexterity_index + 3] = AdventurerUriUtils.TraitKeys.Vitality;
        assert values[dexterity_index + 4] = AdventurerUriUtils.TraitKeys.ValueKey;

        let (vitality_size) = append_felt_ascii(
            adventurer_data.Vitality, values + dexterity_index + 5
        );
        let vitality_index = dexterity_index + 5 + vitality_size;

        assert values[vitality_index] = inverted_commas;
        assert values[vitality_index + 1] = right_bracket;
        assert values[vitality_index + 2] = comma;
        // intelligence
        assert values[vitality_index + 3] = AdventurerUriUtils.TraitKeys.Intelligence;
        assert values[vitality_index + 4] = AdventurerUriUtils.TraitKeys.ValueKey;

        let (intelligence_size) = append_felt_ascii(
            adventurer_data.Intelligence, values + vitality_index + 5
        );
        let intelligence_index = vitality_index + 5 + intelligence_size;

        assert values[intelligence_index] = inverted_commas;
        assert values[intelligence_index + 1] = right_bracket;
        assert values[intelligence_index + 2] = comma;
        // wisdom
        assert values[intelligence_index + 3] = AdventurerUriUtils.TraitKeys.Wisdom;
        assert values[intelligence_index + 4] = AdventurerUriUtils.TraitKeys.ValueKey;

        let (wisdom_size) = append_felt_ascii(
            adventurer_data.Wisdom, values + intelligence_index + 5
        );
        let wisdom_index = intelligence_index + 5 + wisdom_size;

        assert values[wisdom_index] = inverted_commas;
        assert values[wisdom_index + 1] = right_bracket;
        assert values[wisdom_index + 2] = comma;
        // charisma
        assert values[wisdom_index + 3] = AdventurerUriUtils.TraitKeys.Charisma;
        assert values[wisdom_index + 4] = AdventurerUriUtils.TraitKeys.ValueKey;

        let (charisma_size) = append_felt_ascii(
            adventurer_data.Charisma, values + wisdom_index + 5
        );
        let charisma_index = wisdom_index + 5 + charisma_size;

        assert values[charisma_index] = inverted_commas;
        assert values[charisma_index + 1] = right_bracket;
        assert values[charisma_index + 2] = comma;
        // luck
        assert values[charisma_index + 3] = AdventurerUriUtils.TraitKeys.Luck;
        assert values[charisma_index + 4] = AdventurerUriUtils.TraitKeys.ValueKey;

        let (luck_size) = append_felt_ascii(adventurer_data.Luck, values + charisma_index + 5);
        let luck_index = charisma_index + 5 + luck_size;

        assert values[luck_index] = inverted_commas;
        assert values[luck_index + 1] = right_bracket;
        assert values[luck_index + 2] = comma;
        // XP
        assert values[luck_index + 3] = AdventurerUriUtils.TraitKeys.XP;
        assert values[luck_index + 4] = AdventurerUriUtils.TraitKeys.ValueKey;

        let (xp_size) = append_felt_ascii(adventurer_data.XP, values + luck_index + 5);
        let xp_index = luck_index + 5 + xp_size;

        assert values[xp_index] = inverted_commas;
        assert values[xp_index + 1] = right_bracket;
        assert values[xp_index + 2] = comma;

        let (weapon_index) = append_weapon(weapon_item, xp_index + 3, values);

        let (chest_index) = append_chest_item(chest_item, weapon_index, values);

        let (head_index) = append_head_item(head_item, chest_index, values);

        let (waist_index) = append_waist_item(waist_item, head_index, values);

        let (foot_index) = append_feet_item(feet_item, waist_index, values);

        let (hand_index) = append_hands_item(hands_item, foot_index, values);

        let (neck_index) = append_neck_item(neck_item, hand_index, values);

        let (ring_index) = append_ring_item(ring_item, neck_index, values);

        let (status_index) = append_status(adventurer_data.Status, ring_index, values);
        let (beast_id) = IBeast.get_beast_by_id(beast_address, Uint256(adventurer_data.Beast, 0));
        let (beast_index) = append_beast(beast_id.Id, status_index, values);

        assert values[beast_index] = right_square_bracket;
        assert values[beast_index + 1] = right_bracket;

        return (encoded_len=beast_index + 2, encoded=values);
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
            assert values[values_index + 2] = AdventurerUriUtils.RaceNames.Elf;
        }
        if (race == 2) {
            assert values[values_index + 2] = AdventurerUriUtils.RaceNames.Fox;
        }
        if (race == 3) {
            assert values[values_index + 2] = AdventurerUriUtils.RaceNames.Giant;
        }
        if (race == 4) {
            assert values[values_index + 2] = AdventurerUriUtils.RaceNames.Human;
        }
        if (race == 5) {
            assert values[values_index + 2] = AdventurerUriUtils.RaceNames.Orc;
        }
        if (race == 6) {
            assert values[values_index + 2] = AdventurerUriUtils.RaceNames.Demon;
        }
        if (race == 7) {
            assert values[values_index + 2] = AdventurerUriUtils.RaceNames.Goblin;
        }
        if (race == 8) {
            assert values[values_index + 2] = AdventurerUriUtils.RaceNames.Fish;
        }
        if (race == 9) {
            assert values[values_index + 2] = AdventurerUriUtils.RaceNames.Cat;
        }
        if (race == 10) {
            assert values[values_index + 2] = AdventurerUriUtils.RaceNames.Frog;
        }

        let race_key = AdventurerUriUtils.TraitKeys.Race;
        let value_key = AdventurerUriUtils.TraitKeys.ValueKey;
        let right_bracket = AdventurerUriUtils.Symbols.RightBracket;
        let inverted_commas = AdventurerUriUtils.Symbols.InvertedCommas;
        let comma = AdventurerUriUtils.Symbols.Comma;

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
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Power;
        }
        if (order == 2) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Giants;
        }
        if (order == 3) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Titans;
        }
        if (order == 4) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Skill;
        }
        if (order == 5) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Perfection;
        }
        if (order == 6) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Brilliance;
        }
        if (order == 7) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Enlightenment;
        }
        if (order == 8) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Protection;
        }
        if (order == 9) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Twins;
        }
        if (order == 10) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Reflection;
        }
        if (order == 11) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Detection;
        }
        if (order == 12) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Fox;
        }
        if (order == 13) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Vitriol;
        }
        if (order == 14) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Fury;
        }
        if (order == 15) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Rage;
        }
        if (order == 16) {
            assert values[values_index + 2] = AdventurerUriUtils.OrderNames.Anger;
        }

        let order_key = AdventurerUriUtils.TraitKeys.Order;
        let value_key = AdventurerUriUtils.TraitKeys.ValueKey;
        let right_bracket = AdventurerUriUtils.Symbols.RightBracket;
        let inverted_commas = AdventurerUriUtils.Symbols.InvertedCommas;
        let comma = AdventurerUriUtils.Symbols.Comma;

        assert values[values_index] = order_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;
        assert values[values_index + 5] = comma;

        return (values_index + 6,);
    }

    // @notice append felts to uri array for weapon
    // @implicit range_check_ptr
    // @param weapon_data: item struct of the weapon, if id 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return weapon_index: new index of the array
    func append_weapon{range_check_ptr}(weapon_data: Item, values_index: felt, values: felt*) -> (
        weapon_index: felt
    ) {
        if (weapon_data.Id == 0) {
            return (values_index,);
        }

        let weapon_key = AdventurerUriUtils.TraitKeys.Weapon;
        let value_key = AdventurerUriUtils.TraitKeys.ValueKey;
        let right_bracket = AdventurerUriUtils.Symbols.RightBracket;
        let inverted_commas = AdventurerUriUtils.Symbols.InvertedCommas;
        let comma = AdventurerUriUtils.Symbols.Comma;

        assert values[values_index] = weapon_key;
        assert values[values_index + 1] = value_key;

        if (weapon_data.Prefix_1 == 0) {
            LootUri.append_item_name(weapon_data.Id, values_index + 2, values);
            assert values[values_index + 3] = inverted_commas;
            assert values[values_index + 4] = right_bracket;
            assert values[values_index + 5] = comma;
            return (values_index + 6,);
        } else {
            LootUri.append_item_name_prefix(weapon_data.Prefix_1, values_index + 2, values);
            LootUri.append_item_name_suffix(weapon_data.Prefix_2, values_index + 3, values);
            LootUri.append_item_name(weapon_data.Id, values_index + 4, values);
            LootUri.append_item_suffix(weapon_data.Suffix, values_index + 5, values);
            let check_ge_20 = is_le(20, weapon_data.Greatness);
            if (check_ge_20 == TRUE) {
                assert values[values_index + 6] = ' +1';
                assert values[values_index + 7] = inverted_commas;
                assert values[values_index + 8] = right_bracket;
                assert values[values_index + 9] = comma;
                return (values_index + 10,);
            } else {
                assert values[values_index + 6] = inverted_commas;
                assert values[values_index + 7] = right_bracket;
                assert values[values_index + 8] = comma;
                return (values_index + 9,);
            }
        }
    }

    // @notice append felts to uri array for chest item
    // @implicit range_check_ptr
    // @param chest_data: item struct of the chest, if id 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return chest_index: new index of the array
    func append_chest_item{range_check_ptr}(
        chest_data: Item, values_index: felt, values: felt*
    ) -> (chest_index: felt) {
        if (chest_data.Id == 0) {
            return (values_index,);
        }

        let chest_key = AdventurerUriUtils.TraitKeys.Chest;
        let value_key = AdventurerUriUtils.TraitKeys.ValueKey;
        let right_bracket = AdventurerUriUtils.Symbols.RightBracket;
        let inverted_commas = AdventurerUriUtils.Symbols.InvertedCommas;
        let comma = AdventurerUriUtils.Symbols.Comma;

        assert values[values_index] = chest_key;
        assert values[values_index + 1] = value_key;

        if (chest_data.Prefix_1 == 0) {
            LootUri.append_item_name(chest_data.Id, values_index + 2, values);
            assert values[values_index + 3] = inverted_commas;
            assert values[values_index + 4] = right_bracket;
            assert values[values_index + 5] = comma;
            return (values_index + 6,);
        } else {
            LootUri.append_item_name_prefix(chest_data.Prefix_1, values_index + 2, values);
            LootUri.append_item_name_suffix(chest_data.Prefix_2, values_index + 3, values);
            LootUri.append_item_name(chest_data.Id, values_index + 4, values);
            LootUri.append_item_suffix(chest_data.Suffix, values_index + 5, values);
            let check_ge_20 = is_le(20, chest_data.Greatness);
            if (check_ge_20 == TRUE) {
                assert values[values_index + 6] = ' +1';
                assert values[values_index + 7] = inverted_commas;
                assert values[values_index + 8] = right_bracket;
                assert values[values_index + 9] = comma;
                return (values_index + 10,);
            } else {
                assert values[values_index + 6] = inverted_commas;
                assert values[values_index + 7] = right_bracket;
                assert values[values_index + 8] = comma;
                return (values_index + 9,);
            }
        }
    }

    // @notice append felts to uri array for head item
    // @implicit range_check_ptr
    // @param head_data: item struct of the head, if id 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return head_index: new index of the array
    func append_head_item{range_check_ptr}(head_data: Item, values_index: felt, values: felt*) -> (
        head_index: felt
    ) {
        if (head_data.Id == 0) {
            return (values_index,);
        }

        let head_key = AdventurerUriUtils.TraitKeys.Head;
        let value_key = AdventurerUriUtils.TraitKeys.ValueKey;
        let right_bracket = AdventurerUriUtils.Symbols.RightBracket;
        let inverted_commas = AdventurerUriUtils.Symbols.InvertedCommas;
        let comma = AdventurerUriUtils.Symbols.Comma;

        assert values[values_index] = head_key;
        assert values[values_index + 1] = value_key;

        if (head_data.Prefix_1 == 0) {
            LootUri.append_item_name(head_data.Id, values_index + 2, values);
            assert values[values_index + 3] = inverted_commas;
            assert values[values_index + 4] = right_bracket;
            assert values[values_index + 5] = comma;
            return (values_index + 6,);
        } else {
            LootUri.append_item_name_prefix(head_data.Prefix_1, values_index + 2, values);
            LootUri.append_item_name_suffix(head_data.Prefix_2, values_index + 3, values);
            LootUri.append_item_name(head_data.Id, values_index + 4, values);
            LootUri.append_item_suffix(head_data.Suffix, values_index + 5, values);
            let check_ge_20 = is_le(20, head_data.Greatness);
            if (check_ge_20 == TRUE) {
                assert values[values_index + 6] = ' +1';
                assert values[values_index + 7] = inverted_commas;
                assert values[values_index + 8] = right_bracket;
                assert values[values_index + 9] = comma;
                return (values_index + 10,);
            } else {
                assert values[values_index + 6] = inverted_commas;
                assert values[values_index + 7] = right_bracket;
                assert values[values_index + 8] = comma;
                return (values_index + 9,);
            }
        }
    }

    // @notice append felts to uri array for waist item
    // @implicit range_check_ptr
    // @param waist_data: item struct of the waist, if id 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return waist_index: new index of the array
    func append_waist_item{range_check_ptr}(
        waist_data: Item, values_index: felt, values: felt*
    ) -> (waist_index: felt) {
        if (waist_data.Id == 0) {
            return (values_index,);
        }

        let waist_key = AdventurerUriUtils.TraitKeys.Waist;
        let value_key = AdventurerUriUtils.TraitKeys.ValueKey;
        let right_bracket = AdventurerUriUtils.Symbols.RightBracket;
        let inverted_commas = AdventurerUriUtils.Symbols.InvertedCommas;
        let comma = AdventurerUriUtils.Symbols.Comma;

        assert values[values_index] = waist_key;
        assert values[values_index + 1] = value_key;

        if (waist_data.Prefix_1 == 0) {
            LootUri.append_item_name(waist_data.Id, values_index + 2, values);
            assert values[values_index + 3] = inverted_commas;
            assert values[values_index + 4] = right_bracket;
            assert values[values_index + 5] = comma;
            return (values_index + 6,);
        } else {
            LootUri.append_item_name_prefix(waist_data.Prefix_1, values_index + 2, values);
            LootUri.append_item_name_suffix(waist_data.Prefix_2, values_index + 3, values);
            LootUri.append_item_name(waist_data.Id, values_index + 4, values);
            LootUri.append_item_suffix(waist_data.Suffix, values_index + 5, values);
            let check_ge_20 = is_le(20, waist_data.Greatness);
            if (check_ge_20 == TRUE) {
                assert values[values_index + 6] = ' +1';
                assert values[values_index + 7] = inverted_commas;
                assert values[values_index + 8] = right_bracket;
                assert values[values_index + 9] = comma;
                return (values_index + 10,);
            } else {
                assert values[values_index + 6] = inverted_commas;
                assert values[values_index + 7] = right_bracket;
                assert values[values_index + 8] = comma;
                return (values_index + 9,);
            }
        }
    }

    // @notice append felts to uri array for foot item
    // @implicit range_check_ptr
    // @param feet_data: item struct of the feet, if id 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return feet_index: new index of the array
    func append_feet_item{range_check_ptr}(feet_data: Item, values_index: felt, values: felt*) -> (
        feet_index: felt
    ) {
        if (feet_data.Id == 0) {
            return (values_index,);
        }

        let feet_key = AdventurerUriUtils.TraitKeys.Feet;
        let value_key = AdventurerUriUtils.TraitKeys.ValueKey;
        let right_bracket = AdventurerUriUtils.Symbols.RightBracket;
        let inverted_commas = AdventurerUriUtils.Symbols.InvertedCommas;
        let comma = AdventurerUriUtils.Symbols.Comma;

        assert values[values_index] = feet_key;
        assert values[values_index + 1] = value_key;

        if (feet_data.Prefix_1 == 0) {
            LootUri.append_item_name(feet_data.Id, values_index + 2, values);
            assert values[values_index + 3] = inverted_commas;
            assert values[values_index + 4] = right_bracket;
            assert values[values_index + 5] = comma;
            return (values_index + 6,);
        } else {
            LootUri.append_item_name_prefix(feet_data.Prefix_1, values_index + 2, values);
            LootUri.append_item_name_suffix(feet_data.Prefix_2, values_index + 3, values);
            LootUri.append_item_name(feet_data.Id, values_index + 4, values);
            LootUri.append_item_suffix(feet_data.Suffix, values_index + 5, values);
            let check_ge_20 = is_le(20, feet_data.Greatness);
            if (check_ge_20 == TRUE) {
                assert values[values_index + 6] = ' +1';
                assert values[values_index + 7] = inverted_commas;
                assert values[values_index + 8] = right_bracket;
                assert values[values_index + 9] = comma;
                return (values_index + 10,);
            } else {
                assert values[values_index + 6] = inverted_commas;
                assert values[values_index + 7] = right_bracket;
                assert values[values_index + 8] = comma;
                return (values_index + 9,);
            }
        }
    }

    // @notice append felts to uri array for hand item
    // @implicit range_check_ptr
    // @param hands_data: item struct of the hands, if id 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return hands_index: new index of the array
    func append_hands_item{range_check_ptr}(
        hands_data: Item, values_index: felt, values: felt*
    ) -> (hands_index: felt) {
        if (hands_data.Id == 0) {
            return (values_index,);
        }

        let hands_key = AdventurerUriUtils.TraitKeys.Hands;
        let value_key = AdventurerUriUtils.TraitKeys.ValueKey;
        let right_bracket = AdventurerUriUtils.Symbols.RightBracket;
        let inverted_commas = AdventurerUriUtils.Symbols.InvertedCommas;
        let comma = AdventurerUriUtils.Symbols.Comma;

        assert values[values_index] = hands_key;
        assert values[values_index + 1] = value_key;

        if (hands_data.Prefix_1 == 0) {
            LootUri.append_item_name(hands_data.Id, values_index + 2, values);
            assert values[values_index + 3] = inverted_commas;
            assert values[values_index + 4] = right_bracket;
            assert values[values_index + 5] = comma;
            return (values_index + 6,);
        } else {
            LootUri.append_item_name_prefix(hands_data.Prefix_1, values_index + 2, values);
            LootUri.append_item_name_suffix(hands_data.Prefix_2, values_index + 3, values);
            LootUri.append_item_name(hands_data.Id, values_index + 4, values);
            LootUri.append_item_suffix(hands_data.Suffix, values_index + 5, values);
            let check_ge_20 = is_le(20, hands_data.Greatness);
            if (check_ge_20 == TRUE) {
                assert values[values_index + 6] = ' +1';
                assert values[values_index + 7] = inverted_commas;
                assert values[values_index + 8] = right_bracket;
                assert values[values_index + 9] = comma;
                return (values_index + 10,);
            } else {
                assert values[values_index + 6] = inverted_commas;
                assert values[values_index + 7] = right_bracket;
                assert values[values_index + 8] = comma;
                return (values_index + 9,);
            }
        }
    }

    // @notice append felts to uri array for neck item
    // @implicit range_check_ptr
    // @param neck_data: item struct of the neck, if id 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return neck_index: new index of the array
    func append_neck_item{range_check_ptr}(neck_data: Item, values_index: felt, values: felt*) -> (
        neck_index: felt
    ) {
        if (neck_data.Id == 0) {
            return (values_index,);
        }

        let neck_key = AdventurerUriUtils.TraitKeys.Neck;
        let value_key = AdventurerUriUtils.TraitKeys.ValueKey;
        let right_bracket = AdventurerUriUtils.Symbols.RightBracket;
        let inverted_commas = AdventurerUriUtils.Symbols.InvertedCommas;
        let comma = AdventurerUriUtils.Symbols.Comma;

        assert values[values_index] = neck_key;
        assert values[values_index + 1] = value_key;

        if (neck_data.Prefix_1 == 0) {
            LootUri.append_item_name(neck_data.Id, values_index + 2, values);
            assert values[values_index + 3] = inverted_commas;
            assert values[values_index + 4] = right_bracket;
            assert values[values_index + 5] = comma;
            return (values_index + 6,);
        } else {
            LootUri.append_item_name_prefix(neck_data.Prefix_1, values_index + 2, values);
            LootUri.append_item_name_suffix(neck_data.Prefix_2, values_index + 3, values);
            LootUri.append_item_name(neck_data.Id, values_index + 4, values);
            LootUri.append_item_suffix(neck_data.Suffix, values_index + 5, values);
            let check_ge_20 = is_le(20, neck_data.Greatness);
            if (check_ge_20 == TRUE) {
                assert values[values_index + 6] = ' +1';
                assert values[values_index + 7] = inverted_commas;
                assert values[values_index + 8] = right_bracket;
                assert values[values_index + 9] = comma;
                return (values_index + 10,);
            } else {
                assert values[values_index + 6] = inverted_commas;
                assert values[values_index + 7] = right_bracket;
                assert values[values_index + 8] = comma;
                return (values_index + 9,);
            }
        }
    }

    // @notice append felts to uri array for ring item
    // @implicit range_check_ptr
    // @param ring_data: item struct of the ring, if id 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    // @return ring_index: new index of the array
    func append_ring_item{range_check_ptr}(ring_data: Item, values_index: felt, values: felt*) -> (
        ring_index: felt
    ) {
        if (ring_data.Id == 0) {
            return (values_index,);
        }

        let ring_key = AdventurerUriUtils.TraitKeys.Ring;
        let value_key = AdventurerUriUtils.TraitKeys.ValueKey;
        let right_bracket = AdventurerUriUtils.Symbols.RightBracket;
        let inverted_commas = AdventurerUriUtils.Symbols.InvertedCommas;
        let comma = AdventurerUriUtils.Symbols.Comma;

        assert values[values_index] = ring_key;
        assert values[values_index + 1] = value_key;

        if (ring_data.Prefix_1 == 0) {
            LootUri.append_item_name(ring_data.Id, values_index + 2, values);
            assert values[values_index + 3] = inverted_commas;
            assert values[values_index + 4] = right_bracket;
            assert values[values_index + 5] = comma;
            return (values_index + 6,);
        } else {
            LootUri.append_item_name_prefix(ring_data.Prefix_1, values_index + 2, values);
            LootUri.append_item_name_suffix(ring_data.Prefix_2, values_index + 3, values);
            LootUri.append_item_name(ring_data.Id, values_index + 4, values);
            LootUri.append_item_suffix(ring_data.Suffix, values_index + 5, values);
            let check_ge_20 = is_le(20, ring_data.Greatness);
            if (check_ge_20 == TRUE) {
                assert values[values_index + 6] = ' +1';
                assert values[values_index + 7] = inverted_commas;
                assert values[values_index + 8] = right_bracket;
                assert values[values_index + 9] = comma;
                return (values_index + 10,);
            } else {
                assert values[values_index + 6] = inverted_commas;
                assert values[values_index + 7] = right_bracket;
                assert values[values_index + 8] = comma;
                return (values_index + 9,);
            }
        }
    }

    // @notice append felts to uri array for status
    // @implicit range_check_ptr
    // @param status: id of the status, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    func append_status{range_check_ptr}(status: felt, values_index: felt, values: felt*) -> (
        status_index: felt
    ) {
        if (status == AdventurerStatus.Idle) {
            assert values[values_index + 2] = AdventurerUriUtils.Status.Idle;
        }
        if (status == AdventurerStatus.Battle) {
            assert values[values_index + 2] = AdventurerUriUtils.Status.Battle;
        }
        if (status == AdventurerStatus.Travel) {
            assert values[values_index + 2] = AdventurerUriUtils.Status.Travel;
        }
        if (status == AdventurerStatus.Quest) {
            assert values[values_index + 2] = AdventurerUriUtils.Status.Quest;
        }
        if (status == AdventurerStatus.Dead) {
            assert values[values_index + 2] = AdventurerUriUtils.Status.Dead;
        }

        let status_key = AdventurerUriUtils.TraitKeys.Status;
        let value_key = AdventurerUriUtils.TraitKeys.ValueKey;
        let right_bracket = AdventurerUriUtils.Symbols.RightBracket;
        let inverted_commas = AdventurerUriUtils.Symbols.InvertedCommas;
        let comma = AdventurerUriUtils.Symbols.Comma;

        assert values[values_index] = status_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;
        assert values[values_index + 5] = comma;

        return (values_index + 6,);
    }

    // @notice append felts to uri array for beast
    // @implicit range_check_ptr
    // @param beast: id of the beast, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    func append_beast{range_check_ptr}(beast: felt, values_index: felt, values: felt*) -> (
        beast_index: felt
    ) {
        if (beast == 0) {
            return (values_index,);
        }
        if (beast == BeastIds.Phoenix) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Phoenix;
        }
        if (beast == BeastIds.Griffin) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Griffin;
        }
        if (beast == BeastIds.Minotaur) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Minotaur;
        }
        if (beast == BeastIds.Basilisk) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Basilisk;
        }
        if (beast == BeastIds.Gnome) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Gnome;
        }
        if (beast == BeastIds.Giant) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Giant;
        }
        if (beast == BeastIds.Yeti) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Yeti;
        }
        if (beast == BeastIds.Orc) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Orc;
        }
        if (beast == BeastIds.Beserker) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Beserker;
        }
        if (beast == BeastIds.Ogre) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Ogre;
        }
        if (beast == BeastIds.Dragon) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Dragon;
        }
        if (beast == BeastIds.Vampire) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Vampire;
        }
        if (beast == BeastIds.Werewolf) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Werewolf;
        }
        if (beast == BeastIds.Spider) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Spider;
        }
        if (beast == BeastIds.Rat) {
            assert values[values_index + 2] = AdventurerUriUtils.Beast.Rat;
        }

        let beast_key = AdventurerUriUtils.TraitKeys.Beast;
        let value_key = AdventurerUriUtils.TraitKeys.ValueKey;
        let right_bracket = AdventurerUriUtils.Symbols.RightBracket;
        let inverted_commas = AdventurerUriUtils.Symbols.InvertedCommas;
        let comma = AdventurerUriUtils.Symbols.Comma;

        assert values[values_index] = beast_key;
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
