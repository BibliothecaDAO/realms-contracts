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

from contracts.settling_game.utils.game_structs import RealmData

namespace Utils {
    namespace RealmType {
        const Realm = 1;
        const S_Realm = 2;
    }

    namespace Symbols {
        const LeftBracket = 123;
        const RightBracket = 125;
        const InvertedCommas = 34;
        const Comma = 44;
    }

    namespace TraitKeys {
        const Regions = '{"trait_type":"Regions",';
        const Cities = '{"trait_type":"Cities",';
        const Harbors = '{"trait_type":"Harbors",';
        const Rivers = '{"trait_type":"Rivers",';
        const Resource = '{"trait_type":"Resource",';
        const Order = '{"trait_type":"Order",';
        const ValueKey = '"value":"';
    }

    namespace ResourceNames {
        const Wood = 1466920804;
        const Stone = 358435745381;
        const Coal = 1131372908;
        const Copper = 74145906845042;
        const Obsidian = 5720261373207339374;
        const Silver = 91712256370034;
        const Ironwood = 5292415032354631524;
        const ColdIron = 4859221700940820334;
        const Gold = 1198484580;
        const Hartwood = 5215575688017309540;
        const Diamonds = 4929578389782553715;
        const Sapphire = 6008207005979341413;
        const Ruby = 1383424633;
        const DeepCrystal = 82685785959151284352475500;
        const Ignium = 80708582864237;
        const EtherealSilica = 1408709038586369043654121097880417;
        const TrueIce = 23769746579743589;
        const TwilightQuartz = 1713183185033713553468714470503546;
        const AlchemicalSilver = 86962604016411212709514121790885356914;
        const Adamantine = 308805516168419061886565;
        const Mithral = 21789521896169836;
        const Dragonhide = 323230868360603032446053;
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

    namespace WonderNames {
        const wonder_1 = 'Cathedral Of Agony';
        const wonder_2 = 'Sanctum Of Purpose';
        const wonder_3 = 'The Ancestral Willow';
        const wonder_4 = 'The Crying Oak';
        const wonder_5 = 'The Immortal Hot Spring';
        const wonder_6 = 'Pantheon Of Chaos';
        const wonder_7 = 'The Solemn Catacombs';
        const wonder_8 = 'The Exalted Geyser';
        const wonder_9 = 'The Devout Summit';
        const wonder_10 = 'The Mother Grove';
        const wonder_11 = 'Synagogue Of Collapse';
        const wonder_12 = 'Sanctuary Of The Ancients';
        const wonder_13 = 'The Weeping Willow';
        const wonder_14 = 'The Exalted Maple';
        const wonder_15 = 'Altar Of The Void';
        const wonder_16 = 'The Pure Stone';
        const wonder_17 = 'The Celestial Vertex';
        const wonder_18 = 'The Eternal Orchard';
        const wonder_19 = 'The Amaranthine Rock';
        const wonder_20 = 'The Pearl Summit';
        const wonder_21 = 'Mosque Of Mercy';
        const wonder_22 = 'The Mirror Grotto';
        const wonder_23 = 'The Glowing Geyser';
        const wonder_24 = 'Altar Of Perfection';
        const wonder_25 = 'The Cerulean Chamber';
        const wonder_26 = 'The Mythic Trees';
        const wonder_27 = 'The Perpetual Ridge';
        const wonder_28 = 'The Fading Yew';
        const wonder_29 = 'The Origin Oasis';
        const wonder_30 = 'The Sanctified Fjord';
        const wonder_31 = 'The Pale Pillar';
        const wonder_32 = 'Sanctum Of The Oracle';
        const wonder_33 = 'The Ethereal Isle';
        const wonder_34 = 'The Omen Graves';
        const wonder_35 = 'The Pale Vertex';
        const wonder_36 = 'The Glowing Pinnacle';
        const wonder_37 = 'The Azure Lake';
        const wonder_38 = 'The Argent Catacombs';
        const wonder_39 = 'The Dark Mountain';
        const wonder_40 = 'Sky Mast';
        const wonder_41 = 'Infinity Spire';
        const wonder_42 = 'The Exalted Basin';
        const wonder_43 = 'The Ancestral Trees';
        const wonder_44 = 'The Perpetual Fjord';
        const wonder_45 = 'The Ancient Lagoon';
        const wonder_46 = 'The Pearl River';
        const wonder_47 = 'The Cerulean Reliquary';
        const wonder_48 = 'Altar Of Divine Will';
        const wonder_49 = 'Pagoda Of Fortune';
        const wonder_50 = 'The Oracle Pool';
    }
}

namespace Uri {
    // @notice build uri array from stored realm data
    // @implicit bitwise_ptr
    // @implicit range_check_ptr
    // @param realm_id: id of the realm
    // @param realm_name: encoded string of the realm name
    // @param realm_data: unpacked data for realm
    // @param realm_type: type of realm (Realm or S_Realm)
    func build{range_check_ptr}(
        realm_id: Uint256, realm_name: felt, realm_data: RealmData, realm_type: felt
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
        let description_value = '"realms"';

        // realm image url values
        let realm_image_url_1 = 'https://d23fdhqc1jb9no';
        let realm_image_url_2 = '.cloudfront.net/_Realms/';

        // s realm image url values
        let s_realm_image_url_1 = 'https://realms-assets.s3.eu-we';
        let s_realm_image_url_2 = 'st-3.amazonaws.com/renders/';

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
        assert values[7] = realm_name;
        assert values[8] = inverted_commas;
        assert values[9] = comma;
        // image value
        assert values[10] = image_key;
        assert values[11] = inverted_commas;

        if (realm_type == Utils.RealmType.Realm) {
            assert values[12] = realm_image_url_1;
            assert values[13] = realm_image_url_2;
        }

        if (realm_type == Utils.RealmType.S_Realm) {
            assert values[12] = s_realm_image_url_1;
            assert values[13] = s_realm_image_url_2;
        }

        let (id_size) = append_uint256_ascii(realm_id, values + 14);
        let id_index = 14 + id_size;

        if (realm_type == Utils.RealmType.Realm) {
            assert values[id_index] = '.svg';
        }

        if (realm_type == Utils.RealmType.S_Realm) {
            assert values[id_index] = '.webp';
        }

        assert values[id_index + 1] = inverted_commas;
        assert values[id_index + 2] = comma;
        assert values[id_index + 3] = attributes_key;
        assert values[id_index + 4] = left_square_bracket;
        // regions
        assert values[id_index + 5] = Utils.TraitKeys.Regions;
        assert values[id_index + 6] = Utils.TraitKeys.ValueKey;

        let (regions_size) = append_felt_ascii(realm_data.regions, values + id_index + 7);
        let regions_index = id_index + 7 + regions_size;

        assert values[regions_index] = inverted_commas;
        assert values[regions_index + 1] = right_bracket;
        assert values[regions_index + 2] = comma;
        // cities
        assert values[regions_index + 3] = Utils.TraitKeys.Cities;
        assert values[regions_index + 4] = Utils.TraitKeys.ValueKey;

        let (cities_size) = append_felt_ascii(realm_data.cities, values + regions_index + 5);
        let cities_index = regions_index + 5 + cities_size;

        assert values[cities_index] = inverted_commas;
        assert values[cities_index + 1] = right_bracket;
        assert values[cities_index + 2] = comma;
        // harbours
        assert values[cities_index + 3] = Utils.TraitKeys.Harbors;
        assert values[cities_index + 4] = Utils.TraitKeys.ValueKey;

        let (harbors_size) = append_felt_ascii(realm_data.harbours, values + cities_index + 5);
        let harbors_index = cities_index + 5 + harbors_size;

        assert values[harbors_index] = inverted_commas;
        assert values[harbors_index + 1] = right_bracket;
        assert values[harbors_index + 2] = comma;
        // rivers
        assert values[harbors_index + 3] = Utils.TraitKeys.Rivers;
        assert values[harbors_index + 4] = Utils.TraitKeys.ValueKey;

        let (rivers_size) = append_felt_ascii(realm_data.rivers, values + harbors_index + 5);
        let rivers_index = harbors_index + 5 + rivers_size;

        assert values[rivers_index] = inverted_commas;
        assert values[rivers_index + 1] = right_bracket;
        assert values[rivers_index + 2] = comma;

        let (resources: felt*) = alloc();
        assert resources[0] = realm_data.resource_1;
        assert resources[1] = realm_data.resource_2;
        assert resources[2] = realm_data.resource_3;
        assert resources[3] = realm_data.resource_4;
        assert resources[4] = realm_data.resource_5;
        assert resources[5] = realm_data.resource_6;
        assert resources[6] = realm_data.resource_7;

        let (resources_index) = loop_append_resource_names(
            0, 7, resources, rivers_index + 3, values
        );

        let (wonder_index) = append_wonder_name(realm_data.wonder, resources_index, values);

        let (order_index) = append_order_name(realm_data.order, wonder_index, values);

        assert values[order_index] = right_square_bracket;
        assert values[order_index + 1] = right_bracket;

        return (encoded_len=order_index + 2, encoded=values);
    }

    // @notice append felts to uri array for order
    // @implicit range_check_ptr
    // @param order: id of the order, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    func loop_append_resource_names{range_check_ptr}(
        index: felt, resources_len: felt, resources: felt*, values_index: felt, values: felt*
    ) -> (resources_index: felt) {
        alloc_locals;
        if (index == resources_len) {
            return (values_index,);
        }
        let resource = resources[index];
        if (resource == 0) {
            return (values_index,);
        }
        if (resource == 1) {
            assert values[values_index + 2] = Utils.ResourceNames.Wood;
        }
        if (resource == 2) {
            assert values[values_index + 2] = Utils.ResourceNames.Stone;
        }
        if (resource == 3) {
            assert values[values_index + 2] = Utils.ResourceNames.Coal;
        }
        if (resource == 4) {
            assert values[values_index + 2] = Utils.ResourceNames.Copper;
        }
        if (resource == 5) {
            assert values[values_index + 2] = Utils.ResourceNames.Obsidian;
        }
        if (resource == 6) {
            assert values[values_index + 2] = Utils.ResourceNames.Silver;
        }
        if (resource == 7) {
            assert values[values_index + 2] = Utils.ResourceNames.Ironwood;
        }
        if (resource == 8) {
            assert values[values_index + 2] = Utils.ResourceNames.ColdIron;
        }
        if (resource == 9) {
            assert values[values_index + 2] = Utils.ResourceNames.Gold;
        }
        if (resource == 10) {
            assert values[values_index + 2] = Utils.ResourceNames.Hartwood;
        }
        if (resource == 11) {
            assert values[values_index + 2] = Utils.ResourceNames.Diamonds;
        }
        if (resource == 12) {
            assert values[values_index + 2] = Utils.ResourceNames.Sapphire;
        }
        if (resource == 13) {
            assert values[values_index + 2] = Utils.ResourceNames.Ruby;
        }
        if (resource == 14) {
            assert values[values_index + 2] = Utils.ResourceNames.DeepCrystal;
        }
        if (resource == 15) {
            assert values[values_index + 2] = Utils.ResourceNames.Ignium;
        }
        if (resource == 16) {
            assert values[values_index + 2] = Utils.ResourceNames.EtherealSilica;
        }
        if (resource == 17) {
            assert values[values_index + 2] = Utils.ResourceNames.TrueIce;
        }
        if (resource == 18) {
            assert values[values_index + 2] = Utils.ResourceNames.TwilightQuartz;
        }
        if (resource == 19) {
            assert values[values_index + 2] = Utils.ResourceNames.AlchemicalSilver;
        }
        if (resource == 20) {
            assert values[values_index + 2] = Utils.ResourceNames.Adamantine;
        }
        if (resource == 21) {
            assert values[values_index + 2] = Utils.ResourceNames.Mithral;
        }
        if (resource == 22) {
            assert values[values_index + 2] = Utils.ResourceNames.Dragonhide;
        }

        let resource_key = Utils.TraitKeys.Resource;
        let value_key = Utils.TraitKeys.ValueKey;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        assert values[values_index] = resource_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;
        assert values[values_index + 5] = comma;

        return loop_append_resource_names(
            index + 1, resources_len, resources, values_index + 6, values
        );
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

        assert values[values_index] = order_key;
        assert values[values_index + 1] = value_key;
        assert values[values_index + 3] = inverted_commas;
        assert values[values_index + 4] = right_bracket;

        return (values_index + 5,);
    }

    // @notice append felts to uri array for wonder

    // @implicit range_check_ptr
    // @param wonder: id of the wonder, if 0 nothing is appended
    // @param values_index: index in the uri array
    // @param values: uri array
    func append_wonder_name{range_check_ptr}(wonder: felt, values_index: felt, values: felt*) -> (
        wonder_index: felt
    ) {
        if (wonder == 0) {
            return (values_index,);
        }
        if (wonder == 1) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_1;
        }
        if (wonder == 2) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_2;
        }
        if (wonder == 3) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_3;
        }
        if (wonder == 4) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_4;
        }
        if (wonder == 5) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_5;
        }
        if (wonder == 6) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_6;
        }
        if (wonder == 7) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_7;
        }
        if (wonder == 8) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_8;
        }
        if (wonder == 9) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_9;
        }
        if (wonder == 10) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_10;
        }
        if (wonder == 11) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_11;
        }
        if (wonder == 12) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_12;
        }
        if (wonder == 13) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_13;
        }
        if (wonder == 14) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_14;
        }
        if (wonder == 15) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_15;
        }
        if (wonder == 16) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_16;
        }
        if (wonder == 17) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_17;
        }
        if (wonder == 18) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_18;
        }
        if (wonder == 19) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_19;
        }
        if (wonder == 20) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_20;
        }
        if (wonder == 21) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_21;
        }
        if (wonder == 22) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_22;
        }
        if (wonder == 23) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_23;
        }
        if (wonder == 24) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_24;
        }
        if (wonder == 25) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_25;
        }
        if (wonder == 26) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_26;
        }
        if (wonder == 27) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_27;
        }
        if (wonder == 28) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_28;
        }
        if (wonder == 29) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_29;
        }
        if (wonder == 30) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_30;
        }
        if (wonder == 31) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_31;
        }
        if (wonder == 32) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_32;
        }
        if (wonder == 33) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_33;
        }
        if (wonder == 34) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_34;
        }
        if (wonder == 35) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_35;
        }
        if (wonder == 36) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_36;
        }
        if (wonder == 37) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_37;
        }
        if (wonder == 38) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_38;
        }
        if (wonder == 39) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_39;
        }
        if (wonder == 40) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_40;
        }
        if (wonder == 41) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_41;
        }
        if (wonder == 42) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_42;
        }
        if (wonder == 43) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_43;
        }
        if (wonder == 44) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_44;
        }
        if (wonder == 45) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_45;
        }
        if (wonder == 46) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_46;
        }
        if (wonder == 47) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_47;
        }
        if (wonder == 48) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_48;
        }
        if (wonder == 49) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_49;
        }
        if (wonder == 50) {
            assert values[values_index + 3] = Utils.WonderNames.wonder_50;
        }

        let trait_key = '{"trait_type":';
        let wonder_key = '"Wonder (translated)",';
        let value_key = Utils.TraitKeys.ValueKey;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        assert values[values_index] = trait_key;
        assert values[values_index + 1] = wonder_key;
        assert values[values_index + 2] = value_key;
        assert values[values_index + 4] = inverted_commas;
        assert values[values_index + 5] = right_bracket;
        assert values[values_index + 6] = comma;

        return (values_index + 7,);
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
