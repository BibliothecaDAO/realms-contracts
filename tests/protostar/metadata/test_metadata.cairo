%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem

from contracts.metadata.metadata import Uri

@external
func test_metadata{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (data) = Uri.build(Uint256(7,0));

    %{
        array = []
        for i in range(122):
            path = memory[ids.data+i]
            array.append(path.to_bytes(31, "big").decode())
        print(''.join(array))
    %}

    return ();
}

// {
//   "description": "Adventurers",
//   "image": "https://storage.googleapis.com/opensea-prod.appspot.com/puffs/3.png",
//   "name": "Dave Starbelly",
//   "attributes": [ ... ],
// }