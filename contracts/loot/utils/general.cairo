from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_lt_felt
from starkware.cairo.common.uint256 import Uint256

func _uint_to_felt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value: Uint256
) -> (value: felt) {
    assert_lt_felt(value.high, 2 ** 123);
    return (value.high * (2 ** 128) + value.low,);
}

func rare_number_generator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    arguments
) {
    return ();
}
