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
        const Origin = '{"trait_type":"Origin",';
        const Design = '{"trait_type":"Design",';
        const ValueKey = '"value":"';
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
    func build{range_check_ptr}(id: Uint256, crown_name: felt) -> (
        encoded_len: felt, encoded: felt*
    ) {
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
        let image_key = '"animation_url":';
        let attributes_key = '"attributes":';

        let left_square_bracket = 91;
        let right_square_bracket = 93;

        // get value of description
        let description_value = '"The Lost Caravan"';

        // https://realms-assets.s3.eu-west-3.amazonaws.com/lost-caravan/ouroboros_crown.glb
        // realm image url values
        let image_url_1 = 'https://realms-assets.s3.eu-wes';
        let image_url_2 = 't-3.amazonaws.com/lost-caravan/';
        let image_url_3 = 'ouroboros_crown.glb';

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
        assert values[7] = crown_name;
        assert values[8] = inverted_commas;
        assert values[9] = comma;
        // image value
        assert values[10] = image_key;
        assert values[11] = inverted_commas;

        assert values[12] = image_url_1;
        assert values[13] = image_url_2;
        assert values[14] = image_url_3;

        assert values[15] = inverted_commas;
        assert values[16] = comma;
        assert values[17] = attributes_key;
        assert values[18] = left_square_bracket;

        // regions
        assert values[19] = Utils.TraitKeys.Origin;
        assert values[20] = Utils.TraitKeys.ValueKey;

        assert values[21] = 'Lisboa';

        assert values[22] = inverted_commas;
        assert values[23] = right_bracket;
        assert values[24] = comma;

        // cities
        assert values[25] = Utils.TraitKeys.Design;
        assert values[26] = Utils.TraitKeys.ValueKey;

        assert values[27] = 'Golden Ouroboros';

        assert values[28] = inverted_commas;
        assert values[29] = right_bracket;

        assert values[30] = right_square_bracket;
        assert values[31] = right_bracket;

        return (encoded_len=32, encoded=values);
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
