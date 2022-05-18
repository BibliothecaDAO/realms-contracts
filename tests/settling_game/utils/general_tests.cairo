%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.utils.game_structs import Cost

from contracts.settling_game.utils.general import (
    unpack_data,
    transform_costs_to_token_ids_values,
    load_resource_ids_and_values_from_costs,
    sum_values_by_key,
)

@view
func test_unpack_data{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr
}(data : felt, index : felt, mask_size : felt) -> (score : felt):
    let (score) = unpack_data(data, index, mask_size)
    return (score)
end

@view
func test_transform_costs_to_token_ids_values{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*
}(costs_len : felt, costs : Cost*) -> (
    ids_len : felt, ids : Uint256*, values_len : felt, values : Uint256*
):
    alloc_locals

    let (ids : Uint256*) = alloc()
    let (values : Uint256*) = alloc()
    let (len : felt) = transform_costs_to_token_ids_values(costs_len, costs, ids, values)

    return (len, ids, len, values)
end

@view
func test_sum_values_by_key{range_check_ptr}(
    keys_len : felt, keys : felt*, values_len : felt, values : felt*
) -> (d_len : felt, d : DictAccess*):
    let (d_len, d) = sum_values_by_key(keys_len, keys, values)
    return (d_len, d)
end
