// -----------------------------------
//   module.Uri Library
//   Builds a JSON array which to represent Realm metadata
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.uint256 import Uint256, uint256_unsigned_div_rem
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.settling_game.utils.game_structs import RealmData

namespace Utils {
    namespace Symbols {
        const LeftBracket = 123;
        const RightBracket = 125;
        const InvertedCommas = 34;
        const Comma = 44;
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
        const wonder_1 = 5869685279522133479430859692172194274569849; // Cathedral Of Agony
        const wonder_2 = 7263473853406419820284095938416172357088101; // Sanctum Of Purpose
        const wonder_3 = 481883311566737542474031030182613395919585701751; // The Ancestral Willow
        const wonder_4 = 1711993432598352222063181937205611; // The Crying Oak
        const wonder_5 = 8084660405128776430809061735771005386676438088230202983; // The Immortal Hot Spring
        const wonder_6 = 27352097982951288369672299819244365901683; // Pantheon Of Chaos
        const wonder_7 = 481883311590669021234839932185475614649655059059; // The Solemn Catacombs
        const wonder_8 = 7352955804017735861447528931499248859702642; // The Exalted Geyser
        const wonder_9 = 28722483609359197732707359874549887625588; // The Devout Summit
        const wonder_10 = 112197201601856810914962717658823226981; // The Mother Grove
        const wonder_11 = 121997885348795365830646729210975641714649243612005; // Synagogue Of Collapse
        const wonder_12 = 523388450233863627401720544685566915593149201765828182045811; // Sanctuary Of The Ancients
        const wonder_13 = 7352955804381315141949450746130302195494775; // The Weeping Willow
        const wonder_14 = 28722483609444280708779409888694642961509; // The Exalted Maple
        const wonder_15 = 22262514756277102667967827675149625157988; // Altar Of The Void
        const wonder_16 = 1711993432659797820957803886374501; // The Pure Stone
        const wonder_17 = 481883311569349450335560438843499704155047748984; // The Celestial Vertex
        const wonder_18 = 1882356685828459569654440618960132040441295460; // The Eternal Orchard
        const wonder_19 = 481883311566732310636741426579044478833252066155; // The Amaranthine Rock
        const wonder_20 = 112197201602773087146216251269839677812; // The Pearl Summit
        const wonder_21 = 402067351925604188951510085417460601; // Mosque Of Mercy
        const wonder_22 = 28722483610073484313728020690421595534447; // The Mirror Grotto
        const wonder_23 = 7352955804057354288741202820445783305971058; // The Glowing Geyser
        const wonder_24 = 1458996167067376200447920610668910546826915694; // Altar Of Perfection
        const wonder_25 = 481883311569349573295484094481117318668873786738; // The Cerulean Chamber
        const wonder_26 = 112197201601868900173442872257905255795; // The Mythic Trees
        const wonder_27 = 1882356685885271628290621176910462547826861925; // The Perpetual Ridge
        const wonder_28 = 1711993432612204213653063014638967; // The Fading Yew
        const wonder_29 = 112197201602479355747873300554309658995; // The Origin Oasis
        const wonder_30 = 481883311590596369487344008580053433603419239012; // The Sanctified Fjord
        const wonder_31 = 438270318760813684155072613920301426; // The Pale Pillar
        const wonder_32 = 121860869748951841111587458942179520484707200625765; // Sanctum Of The Oracle
        const wonder_33 = 28722483609443051198127402181533308775525; // The Ethereal Isle
        const wonder_34 = 438270318759661298254552393728812403; // The Omen Graves
        const wonder_35 = 438270318760813684155079193911387512; // The Pale Vertex
        const wonder_36 = 481883311574702770666943468041384486870196644965; // The Glowing Pinnacle
        const wonder_37 = 1711993432589054777342731153927013; // The Azure Lake
        const wonder_38 = 481883311566758392789555771262479592161113105011; // The Argent Catacombs
        const wonder_39 = 28722483609357954936504568885723525114222; // The Dark Mountain
        const wonder_40 = 6011031307300205428; // Sky Mast
        const wonder_41 = 1489362693872759468834836248621669; // Infinity Spire
        const wonder_42 = 28722483609444280708779409888647398517102; // The Exalted Basin
        const wonder_43 = 1882356685807568525289183711650833565076514163; // The Ancestral Trees
        const wonder_44 = 1882356685885271628290621176910462496304755300; // The Perpetual Fjord
        const wonder_45 = 7352955803935814556680353466654377731125102; // The Ancient Lagoon
        const wonder_46 = 438270318760832371664907227027105138; // The Pearl River
        const wonder_47 = 31580704707008893635492845615914781084363527406318201; // The Cerulean Reliquary
        const wonder_48 = 373503018769248307314653188184877340105860803692; // Altar Of Divine Will
        const wonder_49 = 27352061535142984367278971188825042546277; // Pagoda Of Fortune
        const wonder_50 = 438270318759684835528781643805323116; // The Oracle Pool
    }
}

namespace Uri {
    func build{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
        realm_id: Uint256, realm_data: RealmData, realm_type: felt
    ) -> (encoded_len: felt, encoded: felt*) {
        alloc_locals;

        // pre-defined for reusability
        let left_bracket = Utils.Symbols.LeftBracket;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        let data_format = 37556871985679581542840396273993309325169359621942828; // data:application/json,

        let description_key = 697556140257669248036922561798714; // "description":
        let name_key = 9691513934389818; // "name":
        let image_key = 2479633334958105146; // "image":
        let attributes_key = 2723918356737767845177276441146; // "attributes":

        let left_square_bracket = 91;
        let right_square_bracket = 93;
        // get value of description
        let description_value = 2482157813739909922; // "realms"

        // get name
        let name_value = 2480746070689997090; // "mahala"

        let image_url_1 = 7526768903561293615;  // https://
        let image_url_2 = 138296299598040277212951397;  // realms-asse
        let image_url_3 = 2361885128291351757209958612169773;  // ts.s3.eu-west-
        let image_url_4 = 265747849610518128817807013032718189;  // 3.amazonaws.com
        let image_url_5 = 875240087534798271279;  // /renders/

        let trait_key = 639351341392214529084052888304630306;  // {"trait_type":"
        let value_key = 635719516926804900386;  // "value":"

        let regions_key = 1519939938891930477100;  // Regions",
        let regions_value = realm_data.regions + 48;

        let cities_key = 4857541669118222892;  // Cities",
        let cities_value = realm_data.cities + 48;

        let harbours_key = 341807963214582545326636;  // Harbours",
        let harbours_value = realm_data.harbours + 48;

        let rivers_key = 5938407761748632108;  // Rivers",
        let rivers_value = realm_data.rivers + 48;

        let resource_key = 389105490742926503125548;  // Resource",

        let (values: felt*) = alloc();
        assert values[0] = data_format;
        assert values[1] = left_bracket;  // start
        // description key
        assert values[2] = description_key;
        assert values[3] = description_value;
        assert values[4] = comma;
        // name value
        assert values[5] = name_key;
        assert values[6] = name_value;
        assert values[7] = comma;
        // image value
        assert values[8] = image_key;
        assert values[9] = inverted_commas;
        assert values[10] = image_url_1;
        assert values[11] = image_url_2;
        assert values[12] = image_url_3;
        assert values[13] = image_url_4;
        if (realm_type == 1) {
            assert values[14] = 47;
        }
        if (realm_type == 2) {
            assert values[14] = image_url_5;
        }

        let (id_size) = append_number_ascii(realm_id, values + 15);
        let id_index = 15 + id_size;

        if (realm_type == 1) {
            assert values[id_index] = 779318887; // .svg
        }
        if (realm_type == 2) {
            assert values[id_index] = 199571628656; // .webp
        }
        assert values[id_index + 1] = inverted_commas;
        assert values[id_index + 2] = comma;
        assert values[id_index + 3] = attributes_key;
        assert values[id_index + 4] = left_square_bracket;
        // regions
        assert values[id_index + 5] = trait_key;
        assert values[id_index + 6] = regions_key;
        assert values[id_index + 7] = value_key;
        assert values[id_index + 8] = regions_value;
        assert values[id_index + 9] = inverted_commas;
        assert values[id_index + 10] = right_bracket;
        assert values[id_index + 11] = comma;
        // cities
        assert values[id_index + 12] = trait_key;
        assert values[id_index + 13] = cities_key;
        assert values[id_index + 14] = value_key;
        assert values[id_index + 15] = cities_value;
        assert values[id_index + 16] = inverted_commas;
        assert values[id_index + 17] = right_bracket;
        assert values[id_index + 18] = comma;
        // harbours
        assert values[id_index + 19] = trait_key;
        assert values[id_index + 20] = harbours_key;
        assert values[id_index + 21] = value_key;
        assert values[id_index + 22] = harbours_value;
        assert values[id_index + 23] = inverted_commas;
        assert values[id_index + 24] = right_bracket;
        assert values[id_index + 25] = comma;
        // rivers
        assert values[id_index + 26] = trait_key;
        assert values[id_index + 27] = rivers_key;
        assert values[id_index + 28] = value_key;
        assert values[id_index + 29] = rivers_value;
        assert values[id_index + 30] = inverted_commas;
        assert values[id_index + 31] = right_bracket;
        assert values[id_index + 32] = comma;

        let (resources: felt*) = alloc();
        assert resources[0] = realm_data.resource_1;
        assert resources[1] = realm_data.resource_2;
        assert resources[2] = realm_data.resource_3;
        assert resources[3] = realm_data.resource_4;
        assert resources[4] = realm_data.resource_5;
        assert resources[5] = realm_data.resource_6;
        assert resources[6] = realm_data.resource_7;

        let (resources_index) = loop_append_resource_names(0, 7, resources, id_index + 33, values);
        
        let (wonder_index) = append_wonder_name(realm_data.wonder, resources_index, values);

        let (order_index) = append_order_name(realm_data.order, wonder_index, values);

        assert values[order_index] = right_square_bracket;
        assert values[order_index + 1] = right_bracket;

        return (encoded_len=order_index + 2, encoded=values);
    }

    func loop_append_resource_names{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
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
            assert values[values_index + 3] = Utils.ResourceNames.Wood;
        }
        if (resource == 2) {
            assert values[values_index + 3] = Utils.ResourceNames.Stone;
        }
        if (resource == 3) {
            assert values[values_index + 3] = Utils.ResourceNames.Coal;
        }
        if (resource == 4) {
            assert values[values_index + 3] = Utils.ResourceNames.Copper;
        }
        if (resource == 5) {
            assert values[values_index + 3] = Utils.ResourceNames.Obsidian;
        }
        if (resource == 6) {
            assert values[values_index + 3] = Utils.ResourceNames.Silver;
        }
        if (resource == 7) {
            assert values[values_index + 3] = Utils.ResourceNames.Ironwood;
        }
        if (resource == 8) {
            assert values[values_index + 3] = Utils.ResourceNames.ColdIron;
        }
        if (resource == 9) {
            assert values[values_index + 3] = Utils.ResourceNames.Gold;
        }
        if (resource == 10) {
            assert values[values_index + 3] = Utils.ResourceNames.Hartwood;
        }
        if (resource == 11) {
            assert values[values_index + 3] = Utils.ResourceNames.Diamonds;
        }
        if (resource == 12) {
            assert values[values_index + 3] = Utils.ResourceNames.Sapphire;
        }
        if (resource == 13) {
            assert values[values_index + 3] = Utils.ResourceNames.Ruby;
        }
        if (resource == 14) {
            assert values[values_index + 3] = Utils.ResourceNames.DeepCrystal;
        }
        if (resource == 15) {
            assert values[values_index + 3] = Utils.ResourceNames.Ignium;
        }
        if (resource == 16) {
            assert values[values_index + 3] = Utils.ResourceNames.EtherealSilica;
        }
        if (resource == 17) {
            assert values[values_index + 3] = Utils.ResourceNames.TrueIce;
        }
        if (resource == 18) {
            assert values[values_index + 3] = Utils.ResourceNames.TwilightQuartz;
        }
        if (resource == 19) {
            assert values[values_index + 3] = Utils.ResourceNames.AlchemicalSilver;
        }
        if (resource == 20) {
            assert values[values_index + 3] = Utils.ResourceNames.Adamantine;
        }
        if (resource == 21) {
            assert values[values_index + 3] = Utils.ResourceNames.Mithral;
        }
        if (resource == 22) {
            assert values[values_index + 3] = Utils.ResourceNames.Dragonhide;
        }

        let trait_key = 639351341392214529084052888304630306;  // {"trait_type":"
        let resource_key = 389105490742926503125548;  // Resource",
        let value_key = 635719516926804900386;  // "value":"
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        assert values[values_index] = trait_key;
        assert values[values_index + 1] = resource_key;
        assert values[values_index + 2] = value_key;
        assert values[values_index + 4] = inverted_commas;
        assert values[values_index + 5] = right_bracket;
        assert values[values_index + 6] = comma;

        return loop_append_resource_names(index + 1, resources_len, resources, values_index + 7, values);
    }

    func append_order_name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        order: felt, values_index: felt, values: felt*
    ) -> (order_index: felt) {
        if (order == 0) {
            return (values_index,);
        }
        if (order == 1) {
            assert values[values_index + 3] = Utils.OrderNames.Power;
        }
        if (order == 2) {
            assert values[values_index + 3] = Utils.OrderNames.Giants;
        }
        if (order == 3) {
            assert values[values_index + 3] = Utils.OrderNames.Titans;
        }
        if (order == 4) {
            assert values[values_index + 3] = Utils.OrderNames.Skill;
        }
        if (order == 5) {
            assert values[values_index + 3] = Utils.OrderNames.Perfection;
        }
        if (order == 6) {
            assert values[values_index + 3] = Utils.OrderNames.Brilliance;
        }
        if (order == 7) {
            assert values[values_index + 3] = Utils.OrderNames.Enlightenment;
        }
        if (order == 8) {
            assert values[values_index + 3] = Utils.OrderNames.Protection;
        }
        if (order == 9) {
            assert values[values_index + 3] = Utils.OrderNames.Twins;
        }
        if (order == 10) {
            assert values[values_index + 3] = Utils.OrderNames.Reflection;
        }
        if (order == 11) {
            assert values[values_index + 3] = Utils.OrderNames.Detection;
        }
        if (order == 12) {
            assert values[values_index + 3] = Utils.OrderNames.Fox;
        }
        if (order == 13) {
            assert values[values_index + 3] = Utils.OrderNames.Vitriol;
        }
        if (order == 14) {
            assert values[values_index + 3] = Utils.OrderNames.Fury;
        }
        if (order == 15) {
            assert values[values_index + 3] = Utils.OrderNames.Rage;
        }
        if (order == 16) {
            assert values[values_index + 3] = Utils.OrderNames.Anger;
        }

        let trait_key = 639351341392214529084052888304630306;  // {"trait_type":"
        let order_key = 22362298684416556;  // Order",
        let value_key = 635719516926804900386;  // "value":"
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;

        assert values[values_index] = trait_key;
        assert values[values_index + 1] = order_key;
        assert values[values_index + 2] = value_key;
        assert values[values_index + 4] = inverted_commas;
        assert values[values_index + 5] = right_bracket;

        return (values_index + 6,);
    }

    func append_wonder_name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        wonder: felt, values_index: felt, values: felt*
    ) -> (wonder_index: felt) {
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

        let trait_key = 639351341392214529084052888304630306;  // {"trait_type":"
        let wonder_key = 127786802251070649640036681418183236865965976789548;  // Wonder (translated)",
        let value_key = 635719516926804900386;  // "value":"
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
    func append_number_ascii{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        num: Uint256, arr: felt*
    ) -> (added_len: felt) {
        alloc_locals;
        local ten: Uint256 = Uint256(10, 0);
        let (q: Uint256, r: Uint256) = uint256_unsigned_div_rem(num, ten);
        let digit = r.low + 48;  // ascii

        if (q.low == 0 and q.high == 0) {
            assert arr[0] = digit;
            return (1,);
        }

        let (added_len) = append_number_ascii(q, arr);
        assert arr[added_len] = digit;
        return (added_len + 1,);
    }
}
