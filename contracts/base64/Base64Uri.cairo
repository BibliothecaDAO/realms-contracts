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

from base64.base64 import Base64
from base64.base64url import Base64URL

namespace Base64Ids {
    const LeftBracket = 0;
    const RightBracket = 1;
    const InvertedCommas = 2;
    const Comma = 3;

    const Description = 4;
    const Image = 5;
    const Name = 6;
    const Attributes = 7;
}

namespace Base64Utils {
    namespace Symbols {
        const LeftBracket = 1702313277;
        const RightBracket = 1716600125;
        const InvertedCommas = 1231502653;
        const Comma = 1279343933;
    }

    // Like this - "description":
    namespace MetaKeys {
        const Description = 419194287586576933063342879423811684114688012093;
        const Image = 22724690793136371677543427901;
        const Name = 22724430842267386803424542013;
        const Attributes = 419193221823647113365606927716498270605726399805;
    }
}

namespace Base64Uri {
    func build{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }() -> (encoded: felt*) {
        alloc_locals;

        let (built_json: felt*) = alloc();

        // pre-encoded for reusability
        let (left_bracket) = base_encoded(Base64Ids.LeftBracket);
        let (right_bracket) = base_encoded(Base64Ids.RightBracket);
        let (inverted_commas) = base_encoded(Base64Ids.InvertedCommas);
        let (comma) = base_encoded(Base64Ids.Comma);
        let (description) = base_encoded(Base64Ids.Description);

        // open
        assert built_json[0] = left_bracket;

        // description
        assert built_json[1] = description;
        assert built_json[2] = inverted_commas;

        // get value of description
        let (name) = Base64URL.encode_single('mahala');

        assert built_json[3] = name;
        assert built_json[4] = comma;

        // close
        assert built_json[5] = right_bracket;

        return (encoded=built_json);
    }

    func base_encoded{range_check_ptr}(index: felt) -> (value: felt) {
        let (table) = get_label_location(BASE64);
        return ([table + index],);

        BASE64:
        dw Base64Utils.Symbols.LeftBracket;
        dw Base64Utils.Symbols.RightBracket;
        dw Base64Utils.Symbols.InvertedCommas;
        dw Base64Utils.Symbols.Comma;

        dw Base64Utils.MetaKeys.Description;
        dw Base64Utils.MetaKeys.Image;
        dw Base64Utils.MetaKeys.Name;
        dw Base64Utils.MetaKeys.Attributes;
    }
}
