%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

@external
func test_current_relic_holder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let holder_id = Uint256(0, 0);
    let relic_id = Uint256(1, 0);

    let (holder) = Relics._current_relic_holder(relic_id, holder_id);

    let (is_equal) = uint256_eq(relic_id, holder);

    assert is_equal = TRUE;

    return ();
}

@external
func test_current_relic_holder_stolen{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let holder_id = Uint256(3, 0);
    let relic_id = Uint256(1, 0);

    let (holder) = Relics._current_relic_holder(relic_id, holder_id);

    let (is_equal) = uint256_eq(holder_id, holder);

    assert is_equal = TRUE;

    return ();
}

@external
func test_relic_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (relics: Uint256*) = alloc();

    assert relics[0] = Uint256(1, 0);
    assert relics[1] = Uint256(2, 0);
    assert relics[2] = Uint256(3, 0);

    let (index) = find_uint256_value(0, 3, relics, Uint256(2,0));

    assert index = 1;
    return ();
}
