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

        // pre-encoded for reusability
        let (left_bracket) = base_encoded(Base64Ids.LeftBracket);
        let (right_bracket) = base_encoded(Base64Ids.RightBracket);
        let (inverted_commas) = base_encoded(Base64Ids.InvertedCommas);
        let (comma) = base_encoded(Base64Ids.Comma);
        let (description_key) = base_encoded(Base64Ids.Description);
        let (name_key) = base_encoded(Base64Ids.Image);
        let (image_key) = base_encoded(Base64Ids.Name);
        let (attributes_key) = base_encoded(Base64Ids.Attributes);

        let (left_square_bracket) = Base64URL.encode_single('[');
        let (right_square_bracket) = Base64URL.encode_single(']');
        // get value of description
        let (description_value) = Base64URL.encode_single('realms');

        // get name
        let (name_value) = Base64URL.encode_single('mahala');

        // image - realms-assets.s3.eu-west-3.amazonaws.com/renders/7430.webp
        let (image_url_1) = Base64URL.encode_single('https://');
        let (image_url_2) = Base64URL.encode_single('realms-asse');
        let (image_url_3) = Base64URL.encode_single('ts.s3.eu-west-');
        let (image_url_4) = Base64URL.encode_single('3.amazonaws.com');
        let (image_url_5) = Base64URL.encode_single('/renders/');
        let (image_url_6) = Base64URL.encode_single(7430);  // id
        let (image_url_7) = Base64URL.encode_single('.webp');

        let (trait_key) = Base64URL.encode_single('{"trait_type":"');
        let (value_key) = Base64URL.encode_single('"value": "');

        let (regions_key) = Base64URL.encode_single('Regions",');
        let (regions_value) = Base64URL.encode_single(7);

        let (cities_key) = Base64URL.encode_single('Cities",');
        let (cities_value) = Base64URL.encode_single(7);

        let (harbours_key) = Base64URL.encode_single('Harbours",');
        let (harbours_value) = Base64URL.encode_single(7);

        let (rivers_key) = Base64URL.encode_single('Rivers",');
        let (rivers_value) = Base64URL.encode_single(7);

        tempvar values = new (
            'data:application/json;base64,',
            left_bracket,  // start
            // description key
            description_key,
            inverted_commas,
            description_value,
            inverted_commas,
            comma,
            // name value
            name_key,
            inverted_commas,
            name_value,
            inverted_commas,
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
            right_bracket,
            // regions
            trait_key,
            regions_key,
            value_key,
            regions_value,
            inverted_commas,
            comma,
            // cities
            trait_key,
            cities_key,
            value_key,
            cities_value,
            inverted_commas,
            comma,
            // harbours
            trait_key,
            harbours_key,
            value_key,
            harbours_value,
            inverted_commas,
            comma,
            // rivers
            trait_key,
            rivers_key,
            value_key,
            rivers_value,
            inverted_commas,
            comma,
            // end
            right_square_bracket,
            comma,
            );

        return (encoded=values);
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
