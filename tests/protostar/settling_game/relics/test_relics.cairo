%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.settling_game.modules.relics.library import Relics

@external
func test_current_relic_holder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let holder_id = Uint256(0, 0)
    let relic_id = Uint256(1, 0)

    let (holder) = Relics._current_relic_holder(relic_id, holder_id)

    let (is_equal) = uint256_eq(relic_id, holder)

    assert is_equal = TRUE

    return ()
end

@external
func test_current_relic_holder_stolen{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    let holder_id = Uint256(3, 0)
    let relic_id = Uint256(1, 0)

    let (holder) = Relics._current_relic_holder(relic_id, holder_id)

    let (is_equal) = uint256_eq(holder_id, holder)

    assert is_equal = TRUE

    return ()
end
