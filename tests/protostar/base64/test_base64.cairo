%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem

from contracts.base64.Base64Uri import Base64Uri
from base64.base64url import Base64URL

@external
func test_base64{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    // let (app) = Base64URL.encode_single('application');
    // let (json) = Base64URL.encode_single('/json;');
    // let (base) = Base64URL.encode_single('base64');

    let (bracket) = Base64Uri.build();

    // %{ print(ids.bracket) %}
    %{
        for i in range(9):
            path = memory[ids.bracket+i]
            print(path.to_bytes(31, "big").decode())
    %}

    // %{ print(ids.bracket.to_bytes(31, "big").decode()) %}

    // let (data_) = Base64URL.encode_single('"attributes":');
    // %{ print(ids.data_) %}

    return ();
}

// {
//   "description": "Adventurers",
//   "image": "https://storage.googleapis.com/opensea-prod.appspot.com/puffs/3.png",
//   "name": "Dave Starbelly",
//   "attributes": [ ... ],
// }
