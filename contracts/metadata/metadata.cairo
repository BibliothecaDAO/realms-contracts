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

from contracts.settling_game.library.library_module import Module
from contracts.settling_game.interfaces.IRealms import IRealms
from contracts.settling_game.interfaces.imodules import IModuleController
from contracts.settling_game.utils.game_structs import ModuleIds, RealmData, ExternalContractIds

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
}

namespace Uri {
    func build{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        realm_id: Uint256
    ) -> (encoded: felt*) {
        alloc_locals;

        let (controller) = Module.controller_address();

        let (realms_address) = IModuleController.get_external_contract_address(
            controller, ExternalContractIds.Realms
        );

        let (realm_data: RealmData) = IRealms.fetch_realm_data(realms_address, realm_id);

        let (resources: felt*) = alloc();
        assert resources[0] = realm_data.resource_1;
        assert resources[1] = realm_data.resource_2;
        assert resources[3] = realm_data.resource_3;
        assert resources[4] = realm_data.resource_4;
        assert resources[5] = realm_data.resource_5;
        assert resources[6] = realm_data.resource_6;

        let (resource_names: felt*) = alloc();

        loop_get_resource_names(0, 7, resources, resource_names);

        let (order_name) = get_order_name(realm_data.order);

        // pre-defined for reusability
        let left_bracket = Utils.Symbols.LeftBracket;
        let right_bracket = Utils.Symbols.RightBracket;
        let inverted_commas = Utils.Symbols.InvertedCommas;
        let comma = Utils.Symbols.Comma;

        let data_format = 37556871985679581542840396273993309325169359621942843;

        let description_key = 178574371905963327497452175820470816;
        let name_key = 2481027567203793440;
        let image_key = 634786133749274917408;
        let attributes_key = 697323099324868568365382768933408;

        let left_square_bracket = 91;
        let right_square_bracket = 93;
        // get value of description
        let description_value = 2482157813739909922;

        // get name
        let name_value = 2480746070689997090;

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

        let harbours_key = 341807963214582545326636;  // Harbours"
        let harbours_value = realm_data.harbours + 48;

        let rivers_key = 5938407761748632108;  // Rivers"
        let rivers_value = realm_data.rivers + 48;

        let resource_number_key = 109523458944853611266298309365832446498;  // Resource Number"
        let resource_number_value = realm_data.resource_number + 48;

        let resource_1_key = 99611005630189184800010530;  // Resource 1"
        let resource_1_value = resource_names[0];

        let resource_2_key = 99611005630189184800010786;  // Resource 2"
        let resource_2_value = resource_names[1];

        let resource_3_key = 99611005630189184800011042;  // Resource 3"
        let resource_3_value = resource_names[2];

        let resource_4_key = 99611005630189184800011298;  // Resource 4"
        let resource_4_value = resource_names[3];

        let resource_5_key = 99611005630189184800011554;  // Resource 5"
        let resource_5_value = resource_names[4];

        let resource_6_key = 99611005630189184800011810;  // Resource 6"
        let resource_6_value = resource_names[5];

        let resource_7_key = 99611005630189184800012066;  // Resource 7"
        let resource_7_value = resource_names[6];

        let wonder_key = 24610842895282722;  // Wonder"
        let wonder_value = realm_data.wonder + 48;

        let order_key = 24610842895282722;  // Wonder"
        let order_value = order_name;

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
            comma,
            // resource number
            trait_key,
            resource_number_key,
            value_key,
            resource_number_value,
            inverted_commas,
            right_bracket,
            comma,
            // resource 1
            trait_key,
            resource_1_key,
            value_key,
            resource_1_value,
            inverted_commas,
            right_bracket,
            comma,
            // resource 2
            trait_key,
            resource_2_key,
            value_key,
            resource_2_value,
            inverted_commas,
            right_bracket,
            comma,
            // resource 3
            trait_key,
            resource_3_key,
            value_key,
            resource_3_value,
            inverted_commas,
            right_bracket,
            comma,
            // resource 4
            trait_key,
            resource_4_key,
            value_key,
            resource_4_value,
            inverted_commas,
            right_bracket,
            comma,
            // resource 5
            trait_key,
            resource_5_key,
            value_key,
            resource_5_value,
            inverted_commas,
            right_bracket,
            comma,
            // resource 6
            trait_key,
            resource_6_key,
            value_key,
            resource_6_value,
            inverted_commas,
            right_bracket,
            comma,
            // resource 7
            trait_key,
            resource_7_key,
            value_key,
            resource_7_value,
            inverted_commas,
            right_bracket,
            comma,
            // wonder
            trait_key,
            wonder_key,
            value_key,
            wonder_value,
            inverted_commas,
            right_bracket,
            comma,
            // order
            trait_key,
            order_key,
            value_key,
            order_value,
            inverted_commas,
            right_bracket,
            comma,
            // end
            right_square_bracket,
            comma,
            );

        return (encoded=values);
    }

    func loop_get_resource_names{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: felt, resources_len: felt, resources: felt*, resource_names: felt*
    ) {
        if (index == 7) {
            return ();
        }
        let resource = resources[index];
        if (resource == 1) {
            assert resource_names[index] = Utils.ResourceNames.Wood;
        }
        if (resource == 2) {
            assert resource_names[index] = Utils.ResourceNames.Stone;
        }
        if (resource == 3) {
            assert resource_names[index] = Utils.ResourceNames.Coal;
        }
        if (resource == 4) {
            assert resource_names[index] = Utils.ResourceNames.Copper;
        }
        if (resource == 5) {
            assert resource_names[index] = Utils.ResourceNames.Obsidian;
        }
        if (resource == 6) {
            assert resource_names[index] = Utils.ResourceNames.Silver;
        }
        if (resource == 7) {
            assert resource_names[index] = Utils.ResourceNames.Ironwood;
        }
        if (resource == 8) {
            assert resource_names[index] = Utils.ResourceNames.ColdIron;
        }
        if (resource == 9) {
            assert resource_names[index] = Utils.ResourceNames.Gold;
        }
        if (resource == 10) {
            assert resource_names[index] = Utils.ResourceNames.Hartwood;
        }
        if (resource == 11) {
            assert resource_names[index] = Utils.ResourceNames.Diamonds;
        }
        if (resource == 12) {
            assert resource_names[index] = Utils.ResourceNames.Sapphire;
        }
        if (resource == 13) {
            assert resource_names[index] = Utils.ResourceNames.Ruby;
        }
        if (resource == 14) {
            assert resource_names[index] = Utils.ResourceNames.DeepCrystal;
        }
        if (resource == 15) {
            assert resource_names[index] = Utils.ResourceNames.Ignium;
        }
        if (resource == 16) {
            assert resource_names[index] = Utils.ResourceNames.EtherealSilica;
        }
        if (resource == 17) {
            assert resource_names[index] = Utils.ResourceNames.TrueIce;
        }
        if (resource == 18) {
            assert resource_names[index] = Utils.ResourceNames.TwilightQuartz;
        }
        if (resource == 19) {
            assert resource_names[index] = Utils.ResourceNames.AlchemicalSilver;
        }
        if (resource == 20) {
            assert resource_names[index] = Utils.ResourceNames.Adamantine;
        }
        if (resource == 21) {
            assert resource_names[index] = Utils.ResourceNames.Mithral;
        }
        if (resource == 22) {
            assert resource_names[index] = Utils.ResourceNames.Dragonhide;
        }

        return loop_get_resource_names(index + 1, resources_len, resources, resource_names);
    }

    func get_order_name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        order: felt
    ) -> (order_name: felt) {
        if (order == 1) {
            return (Utils.OrderNames.Power,);
        }
        if (order == 2) {
            return (Utils.OrderNames.Giants,);
        }
        if (order == 3) {
            return (Utils.OrderNames.Titans,);
        }
        if (order == 4) {
            return (Utils.OrderNames.Skill,);
        }
        if (order == 5) {
            return (Utils.OrderNames.Perfection,);
        }
        if (order == 6) {
            return (Utils.OrderNames.Brilliance,);
        }
        if (order == 7) {
            return (Utils.OrderNames.Enlightenment,);
        }
        if (order == 8) {
            return (Utils.OrderNames.Protection,);
        }
        if (order == 9) {
            return (Utils.OrderNames.Twins,);
        }
        if (order == 10) {
            return (Utils.OrderNames.Reflection,);
        }
        if (order == 11) {
            return (Utils.OrderNames.Detection,);
        }
        if (order == 12) {
            return (Utils.OrderNames.Fox,);
        }
        if (order == 13) {
            return (Utils.OrderNames.Vitriol,);
        }
        if (order == 14) {
            return (Utils.OrderNames.Fury,);
        }
        if (order == 15) {
            return (Utils.OrderNames.Rage,);
        }
        if (order == 16) {
            return (Utils.OrderNames.Anger,);
        }
    }
}
