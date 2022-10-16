// -----------------------------------
//   module.BASE64Uri Library
//   Builds a Base64 array which from a client can be decoded into a JSON
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.uint256 import Uint256
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
        const wonder_1 = 5869685279522133479430859692172194274569849;
        const wonder_2 = 7263473853406419820284095938416172357088101;
        const wonder_3 = 481883311566737542474031030182613395919585701751;
        const wonder_4 = 1711993432598352222063181937205611;
        const wonder_5 = 8084660405128776430809061735771005386676438088230202983;
        const wonder_6 = 27352097982951288369672299819244365901683;
        const wonder_7 = 481883311590669021234839932185475614649655059059;
        const wonder_8 = 7352955804017735861447528931499248859702642;
        const wonder_9 = 28722483609359197732707359874549887625588;
        const wonder_10 = 112197201601856810914962717658823226981;
        const wonder_11 = 121997885348795365830646729210975641714649243612005;
        const wonder_12 = 523388450233863627401720544685566915593149201765828182045811;
        const wonder_13 = 7352955804381315141949450746130302195494775;
        const wonder_14 = 28722483609444280708779409888694642961509;
        const wonder_15 = 22262514756277102667967827675149625157988;
        const wonder_16 = 1711993432659797820957803886374501;
        const wonder_17 = 481883311569349450335560438843499704155047748984;
        const wonder_18 = 1882356685828459569654440618960132040441295460;
        const wonder_19 = 481883311566732310636741426579044478833252066155;
        const wonder_20 = 112197201602773087146216251269839677812;
        const wonder_21 = 402067351925604188951510085417460601;
        const wonder_22 = 28722483610073484313728020690421595534447;
        const wonder_23 = 7352955804057354288741202820445783305971058;
        const wonder_24 = 1458996167067376200447920610668910546826915694;
        const wonder_25 = 481883311569349573295484094481117318668873786738;
        const wonder_26 = 112197201601868900173442872257905255795;
        const wonder_27 = 1882356685885271628290621176910462547826861925;
        const wonder_28 = 1711993432612204213653063014638967;
        const wonder_29 = 112197201602479355747873300554309658995;
        const wonder_30 = 481883311590596369487344008580053433603419239012;
        const wonder_31 = 438270318760813684155072613920301426;
        const wonder_32 = 121860869748951841111587458942179520484707200625765;
        const wonder_33 = 28722483609443051198127402181533308775525;
        const wonder_34 = 438270318759661298254552393728812403;
        const wonder_35 = 438270318760813684155079193911387512;
        const wonder_36 = 481883311574702770666943468041384486870196644965;
        const wonder_37 = 1711993432589054777342731153927013;
        const wonder_38 = 481883311566758392789555771262479592161113105011;
        const wonder_39 = 28722483609357954936504568885723525114222;
        const wonder_40 = 6011031307300205428;
        const wonder_41 = 1489362693872759468834836248621669;
        const wonder_42 = 28722483609444280708779409888647398517102;
        const wonder_43 = 1882356685807568525289183711650833565076514163;
        const wonder_44 = 1882356685885271628290621176910462496304755300;
        const wonder_45 = 7352955803935814556680353466654377731125102;
        const wonder_46 = 438270318760832371664907227027105138;
        const wonder_47 = 31580704707008893635492845615914781084363527406318201;
        const wonder_48 = 373503018769248307314653188184877340105860803692;
        const wonder_49 = 27352061535142984367278971188825042546277;
        const wonder_50 = 438270318759684835528781643805323116;
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
        let image_url_6 = realm_id.low + 48;  // id
        let image_url_7 = 199571628656;  // .webp
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

        tempvar values = new (
            data_format,
            left_bracket,  // start
            // description key
            description_key,
            description_value,
            comma,
            // name value
            name_key,
            name_value,
            comma,
            // image value
            image_key,
            inverted_commas,
            image_url_1,
            image_url_2,
            image_url_3,
            image_url_4,
            image_url_5,
            image_url_6,
            image_url_7,
            inverted_commas,
            comma,
            attributes_key,
            left_square_bracket,
            // regions
            trait_key,
            regions_key,
            value_key,
            regions_value,
            inverted_commas,
            right_bracket,
            comma,
            // cities
            trait_key,
            cities_key,
            value_key,
            cities_value,
            inverted_commas,
            right_bracket,
            comma,
            // harbours
            trait_key,
            harbours_key,
            value_key,
            harbours_value,
            inverted_commas,
            right_bracket,
            comma,
            // rivers
            trait_key,
            rivers_key,
            value_key,
            rivers_value,
            inverted_commas,
            right_bracket,
            comma
        );

        let (resources: felt*) = alloc();
        assert resources[0] = realm_data.resource_1;
        assert resources[1] = realm_data.resource_2;
        assert resources[2] = realm_data.resource_3;
        assert resources[3] = realm_data.resource_4;
        assert resources[4] = realm_data.resource_5;
        assert resources[5] = realm_data.resource_6;
        assert resources[6] = realm_data.resource_7;

        let (resources_index) = loop_append_resource_names(0, 7, resources, 49, values);
        
        let (wonder_index) = append_wonder_name(realm_data.wonder, resources_index, values);

        let (order_index) = append_order_name(realm_data.wonder, wonder_index, values);

        return (encoded_len=order_index + 1, encoded=values);
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
            let resource_name = Utils.ResourceNames.Wood;
            tempvar resource_name = resource_name;
        }
        if (resource == 2) {
            let resource_name = Utils.ResourceNames.Stone;
            tempvar resource_name = resource_name;
        }
        if (resource == 3) {
            let resource_name = Utils.ResourceNames.Coal;
            tempvar resource_name = resource_name;
        }
        if (resource == 4) {
            let resource_name = Utils.ResourceNames.Copper;
            tempvar resource_name = resource_name;
        }
        if (resource == 5) {
            let resource_name = Utils.ResourceNames.Obsidian;
            tempvar resource_name = resource_name;
        }
        if (resource == 6) {
            let resource_name = Utils.ResourceNames.Silver;
            tempvar resource_name = resource_name;
        }
        if (resource == 7) {
            let resource_name = Utils.ResourceNames.Ironwood;
            tempvar resource_name = resource_name;
        }
        if (resource == 8) {
            let resource_name = Utils.ResourceNames.ColdIron;
            tempvar resource_name = resource_name;
        }
        if (resource == 9) {
            let resource_name = Utils.ResourceNames.Gold;
            tempvar resource_name = resource_name;
        }
        if (resource == 10) {
            let resource_name = Utils.ResourceNames.Hartwood;
            tempvar resource_name = resource_name;
        }
        if (resource == 11) {
            let resource_name = Utils.ResourceNames.Diamonds;
            tempvar resource_name = resource_name;
        }
        if (resource == 12) {
            let resource_name = Utils.ResourceNames.Sapphire;
            tempvar resource_name = resource_name;
        }
        if (resource == 13) {
            let resource_name = Utils.ResourceNames.Ruby;
            tempvar resource_name = resource_name;
        }
        if (resource == 14) {
            let resource_name = Utils.ResourceNames.DeepCrystal;
            tempvar resource_name = resource_name;
        }
        if (resource == 15) {
            let resource_name = Utils.ResourceNames.Ignium;
            tempvar resource_name = resource_name;
        }
        if (resource == 16) {
            let resource_name = Utils.ResourceNames.EtherealSilica;
            tempvar resource_name = resource_name;
        }
        if (resource == 17) {
            let resource_name = Utils.ResourceNames.TrueIce;
            tempvar resource_name = resource_name;
        }
        if (resource == 18) {
            let resource_name = Utils.ResourceNames.TwilightQuartz;
            tempvar resource_name = resource_name;
        }
        if (resource == 19) {
            let resource_name = Utils.ResourceNames.AlchemicalSilver;
            tempvar resource_name = resource_name;
        }
        if (resource == 20) {
            let resource_name = Utils.ResourceNames.Adamantine;
            tempvar resource_name = resource_name;
        }
        if (resource == 21) {
            let resource_name = Utils.ResourceNames.Mithral;
            tempvar resource_name = resource_name;
        }
        if (resource == 22) {
            let resource_name = Utils.ResourceNames.Dragonhide;
            tempvar resource_name = resource_name;
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
        assert values[values_index + 3] = resource_name;
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
            let order_name = Utils.OrderNames.Power;
        }
        if (order == 2) {
            let order_name = Utils.OrderNames.Giants;
        }
        if (order == 3) {
            let order_name = Utils.OrderNames.Titans;
        }
        if (order == 4) {
            let order_name = Utils.OrderNames.Skill;
        }
        if (order == 5) {
            let order_name = Utils.OrderNames.Perfection;
        }
        if (order == 6) {
            let order_name = Utils.OrderNames.Brilliance;
        }
        if (order == 7) {
            let order_name = Utils.OrderNames.Enlightenment;
        }
        if (order == 8) {
            let order_name = Utils.OrderNames.Protection;
        }
        if (order == 9) {
            let order_name = Utils.OrderNames.Twins;
        }
        if (order == 10) {
            let order_name = Utils.OrderNames.Reflection;
        }
        if (order == 11) {
            let order_name = Utils.OrderNames.Detection;
        }
        if (order == 12) {
            let order_name = Utils.OrderNames.Fox;
        }
        if (order == 13) {
            let order_name = Utils.OrderNames.Vitriol;
        }
        if (order == 14) {
            let order_name = Utils.OrderNames.Fury;
        }
        if (order == 15) {
            let order_name = Utils.OrderNames.Rage;
        }
        if (order == 16) {
            let order_name = Utils.OrderNames.Anger;
        }

        let order_key = 22362298684416556;  // Order",

        assert values[values_index] = order_key;
        assert values[values_index + 1] = order_name;

        return (values_index + 2,);
    }

    func append_wonder_name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        wonder: felt, values_index: felt, values: felt*
    ) -> (wonder_index: felt) {
        if (wonder == 0) {
            return (values_index,);
        }
        if (wonder == 1) {
            let wonder_name = Utils.WonderNames.wonder_1;
        }
        if (wonder == 2) {
            let wonder_name = Utils.WonderNames.wonder_2;
        }
        if (wonder == 3) {
            let wonder_name = Utils.WonderNames.wonder_3;
        }
        if (wonder == 4) {
            let wonder_name = Utils.WonderNames.wonder_4;
        }
        if (wonder == 5) {
            let wonder_name = Utils.WonderNames.wonder_5;
        }
        if (wonder == 6) {
            let wonder_name = Utils.WonderNames.wonder_6;
        }
        if (wonder == 7) {
            let wonder_name = Utils.WonderNames.wonder_7;
        }
        if (wonder == 8) {
            let wonder_name = Utils.WonderNames.wonder_8;
        }
        if (wonder == 9) {
            let wonder_name = Utils.WonderNames.wonder_9;
        }
        if (wonder == 10) {
            let wonder_name = Utils.WonderNames.wonder_10;
        }
        if (wonder == 11) {
            let wonder_name = Utils.WonderNames.wonder_11;
        }
        if (wonder == 12) {
            let wonder_name = Utils.WonderNames.wonder_12;
        }
        if (wonder == 13) {
            let wonder_name = Utils.WonderNames.wonder_13;
        }
        if (wonder == 14) {
            let wonder_name = Utils.WonderNames.wonder_14;
        }
        if (wonder == 15) {
            let wonder_name = Utils.WonderNames.wonder_15;
        }
        if (wonder == 16) {
            let wonder_name = Utils.WonderNames.wonder_16;
        }
        if (wonder == 17) {
            let wonder_name = Utils.WonderNames.wonder_17;
        }
        if (wonder == 18) {
            let wonder_name = Utils.WonderNames.wonder_18;
        }
        if (wonder == 19) {
            let wonder_name = Utils.WonderNames.wonder_19;
        }
        if (wonder == 20) {
            let wonder_name = Utils.WonderNames.wonder_20;
        }
        if (wonder == 21) {
            let wonder_name = Utils.WonderNames.wonder_21;
        }
        if (wonder == 22) {
            let wonder_name = Utils.WonderNames.wonder_22;
        }
        if (wonder == 23) {
            let wonder_name = Utils.WonderNames.wonder_23;
        }
        if (wonder == 24) {
            let wonder_name = Utils.WonderNames.wonder_24;
        }
        if (wonder == 25) {
            let wonder_name = Utils.WonderNames.wonder_25;
        }
        if (wonder == 26) {
            let wonder_name = Utils.WonderNames.wonder_26;
        }
        if (wonder == 27) {
            let wonder_name = Utils.WonderNames.wonder_27;
        }
        if (wonder == 28) {
            let wonder_name = Utils.WonderNames.wonder_28;
        }
        if (wonder == 29) {
            let wonder_name = Utils.WonderNames.wonder_29;
        }
        if (wonder == 30) {
            let wonder_name = Utils.WonderNames.wonder_30;
        }
        if (wonder == 31) {
            let wonder_name = Utils.WonderNames.wonder_31;
        }
        if (wonder == 32) {
            let wonder_name = Utils.WonderNames.wonder_32;
        }
        if (wonder == 33) {
            let wonder_name = Utils.WonderNames.wonder_33;
        }
        if (wonder == 34) {
            let wonder_name = Utils.WonderNames.wonder_34;
        }
        if (wonder == 35) {
            let wonder_name = Utils.WonderNames.wonder_35;
        }
        if (wonder == 36) {
            let wonder_name = Utils.WonderNames.wonder_36;
        }
        if (wonder == 37) {
            let wonder_name = Utils.WonderNames.wonder_37;
        }
        if (wonder == 38) {
            let wonder_name = Utils.WonderNames.wonder_38;
        }
        if (wonder == 39) {
            let wonder_name = Utils.WonderNames.wonder_39;
        }
        if (wonder == 40) {
            let wonder_name = Utils.WonderNames.wonder_40;
        }
        if (wonder == 41) {
            let wonder_name = Utils.WonderNames.wonder_41;
        }
        if (wonder == 42) {
            let wonder_name = Utils.WonderNames.wonder_42;
        }
        if (wonder == 43) {
            let wonder_name = Utils.WonderNames.wonder_43;
        }
        if (wonder == 44) {
            let wonder_name = Utils.WonderNames.wonder_44;
        }
        if (wonder == 45) {
            let wonder_name = Utils.WonderNames.wonder_45;
        }
        if (wonder == 46) {
            let wonder_name = Utils.WonderNames.wonder_46;
        }
        if (wonder == 47) {
            let wonder_name = Utils.WonderNames.wonder_47;
        }
        if (wonder == 48) {
            let wonder_name = Utils.WonderNames.wonder_48;
        }
        if (wonder == 49) {
            let wonder_name = Utils.WonderNames.wonder_49;
        }
        if (wonder == 50) {
            let wonder_name = Utils.WonderNames.wonder_50;
        }

        let wonder_key = 499167196293244725156393286789778269007679596834;  // Wonder (translated)",

        assert values[values_index] = wonder_key;
        assert values[values_index + 1] = wonder_name;

        return (values_index + 2,);
    }
}
