%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem

from contracts.metadata.metadata import Uri
from contracts.settling_game.utils.game_structs import RealmData

@external
func test_metadata{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    let realm_data_1 = RealmData(4, 5, 2, 1, 4, 2, 8, 13, 6, 0, 0, 0, 1, 4);
    let realm_data_2 = RealmData(2, 3, 6, 14, 6, 1, 5, 2, 9, 14, 10, 0, 0, 10);
    let (data_1_len, data_1) = Uri.build(Uint256(7,0), realm_data_1, 1);

    %{
        array = []
        for i in range(ids.data_1_len):
            path = memory[ids.data_1+i]
            array.append(path.to_bytes(31, "big").decode())
        print(''.join(array))
    %}

    let (data_2_len, data_2) = Uri.build(Uint256(30,0), realm_data_2, 2);

    %{
        array = []
        for i in range(ids.data_2_len):
            path = memory[ids.data_2+i]
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