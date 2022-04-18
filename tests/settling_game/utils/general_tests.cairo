%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.dict_access import DictAccess

from contracts.settling_game.utils.game_structs import Cost

from contracts.settling_game.utils.general import (
    unpack_data,
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
func test_load_resource_ids_and_values_from_costs{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*
}(costs_len : felt, costs : Cost*) -> (
    ids_len : felt, ids : felt*, values_len : felt, values : felt*
):
    alloc_locals

    let (resource_ids) = alloc()
    let (resource_values) = alloc()
    let (resource_len) = load_resource_ids_and_values_from_costs(
        resource_ids, resource_values, costs_len, costs, 0
    )

    return (resource_len, resource_ids, resource_len, resource_values)
end

@view
func test_sum_values_by_key{range_check_ptr}(
    keys_len : felt, keys : felt*, values_len : felt, values : felt*
) -> (d_len : felt, d : DictAccess*):
    let (d_len, d) = sum_values_by_key(keys_len, keys, values)
    return (d_len, d)
end
