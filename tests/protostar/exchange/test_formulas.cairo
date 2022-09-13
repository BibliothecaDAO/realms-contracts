%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from starkware.cairo.common.alloc import alloc

from contracts.exchange.library import AMM

@external
func test_full_sell_price{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let token_amount = Uint256(1000 * 10 ** 18, 0);
    let currency_reserves = Uint256(10 * 10 ** 18, 0);
    let token_reserves = Uint256(100 * 10 ** 18, 0);

    let lp_fee = Uint256(100, 0);

    let (price) = AMM.get_sell_price(token_amount, currency_reserves, token_reserves, lp_fee);

    // %{ print(ids.price.low / 1 * 10 ** 18) %}

    // TODO: missing assert

    return ();
}

@external
func test_full_buy_price{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let token_amount = Uint256(100 * 10 ** 18, 0);
    let currency_reserves = Uint256(100 * 10 ** 18, 0);
    let token_reserves = Uint256(1000 * 10 ** 18, 0);

    let lp_fee = Uint256(100, 0);

    let (price) = AMM.get_buy_price(token_amount, currency_reserves, token_reserves, lp_fee);

    // %{ print(ids.price.low / 1 * 10 ** 18) %}

    // TODO: missing assert

    return ();
}
