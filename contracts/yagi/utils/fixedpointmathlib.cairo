%lang starknet

from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_eq, uint256_sub
from openzeppelin.security.safemath.library import SafeUint256

// # @title Fixed point math library
// # @description A fixed point math library
// # @description Adapted from solmate: https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol
// # @author Peteris <github.com/Pet3ris>

func mul_div_down{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    x: Uint256, y: Uint256, denominator: Uint256
) -> (z: Uint256) {
    alloc_locals;

    // set prod = x * y
    let (local prod) = SafeUint256.mul(x, y);

    // compute (x * y) / denominator
    let (q2, _) = SafeUint256.div_rem(prod, denominator);
    return (q2,);
}

func mul_div_up{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    x: Uint256, y: Uint256, denominator: Uint256
) -> (z: Uint256) {
    alloc_locals;
    let ZERO = Uint256(0, 0);
    let ONE = Uint256(1, 0);

    // set prod = x * y
    let (local prod) = SafeUint256.mul(x, y);

    // if prod = 0, just return 0
    let (local prod_iszero) = uint256_eq(prod, ZERO);
    if (prod_iszero == TRUE) {
        return (ZERO,);
    }

    // compute prod - 1
    let (local dec_prod) = uint256_sub(prod, ONE);

    // compute ((x * y - 1) / denominator) + 1
    let (q2, _) = SafeUint256.div_rem(dec_prod, denominator);
    let (local inc_q2, _) = uint256_add(q2, ONE);
    return (inc_q2,);
}
