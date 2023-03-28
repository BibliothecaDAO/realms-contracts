%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from tests.protostar.loot.setup.interfaces import IXoroshiro
from starkware.cairo.common.math import (
    unsigned_div_rem,
)


@external
func setup_random_number{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;
    local xoroshiro;
    %{
        ids.xoroshiro = deploy_contract("./contracts/utils/xoroshiro128_starstar.cairo", 
            [123]
        ).contract_address
        context.xoroshiro = ids.xoroshiro
    %}
    return ();
}

@external
func test_random_number{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local xoroshiro_address;

    %{
        ids.xoroshiro_address = context.xoroshiro
    %}
    _loop_xoroshiro_generator(0, 100, xoroshiro_address);
    return ();
}

func _loop_xoroshiro_generator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: felt, outputs_len: felt, xoroshiro_address: felt
) {
    alloc_locals;
    if (index == outputs_len) {
        return ();
    }

    let (xoroshiro_random_number) = IXoroshiro.next(xoroshiro_address);
    let (_, local random_number) = unsigned_div_rem(xoroshiro_random_number, 10);
    %{
        print(ids.random_number)
    %}

    return _loop_xoroshiro_generator(index + 1, outputs_len, xoroshiro_address);
}