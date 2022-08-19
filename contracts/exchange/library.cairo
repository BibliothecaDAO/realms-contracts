# AMM LIBRARY
# The purpose of the library is to hold any abstracted logic from the AMM. This allows cleaner test suites.

# MIT LICENCE

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    uint256_mul,
    uint256_unsigned_div_rem,
    uint256_le,
    uint256_eq,
)

namespace AMM:
    # input arguments are:
    # 1) exact amount of token to sell
    # 2) currency reserve amount
    # 3) token reserve amount
    func get_sell_price{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_amount : Uint256,
        currency_reserves : Uint256,
        token_reserves : Uint256,
        lp_fee_thousands_ : Uint256,
    ) -> (price : Uint256):
        alloc_locals

        # LP fee is used to withold currency as reward to LP providers
        let (lp_fee) = uint256_sub(Uint256(1000, 0), lp_fee_thousands_)

        # Apply LP fee to token amount
        let (token_amount_w_fee, mul_overflow) = uint256_mul(token_amount, lp_fee)
        with_attr error_message("LP fee overflow"):
            assert mul_overflow = Uint256(0, 0)
        end

        # Calculate price
        let (numerator, mul_overflow) = uint256_mul(token_amount_w_fee, currency_reserves)
        with_attr error_message("Price numerator overflow"):
            assert mul_overflow = Uint256(0, 0)
        end
        let (denominator, mul_overflow) = uint256_mul(token_reserves, Uint256(1000, 0))
        with_attr error_message("LP fee buffer denominator overflow"):
            assert mul_overflow = Uint256(0, 0)
        end
        let (denominator_fee, is_overflow) = uint256_add(denominator, token_amount_w_fee)
        with_attr error_message("Price denominator overflow"):
            assert is_overflow = 0
        end

        let (price, _) = uint256_unsigned_div_rem(numerator, denominator_fee)

        # Sanity fallback check to see if price is 0
        with_attr error_message("Price cannot be 0"):
            let (is_zero) = uint256_le(price, Uint256(0, 0))
            assert_not_equal(is_zero, 1)
        end

        # Rounding errors favour the contract
        return (price)
    end

    # input arguments are:
    # 1) exact amount of token to buy
    # 2) currency reserve amount
    # 3) token reserve amount
    func get_buy_price{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_amount : Uint256,
        currency_reserves : Uint256,
        token_reserves : Uint256,
        lp_fee_thousands_ : Uint256,
    ) -> (price : Uint256):
        alloc_locals

        # LP fee is used to withold currency as reward to LP providers
        let (lp_fee) = uint256_sub(Uint256(1000, 0), lp_fee_thousands_)

        # Calculate price
        let (numerator, mul_overflow) = uint256_mul(currency_reserves, token_amount)
        with_attr error_message("Values too large"):
            assert mul_overflow = Uint256(0, 0)
        end

        let (denominator) = uint256_sub(token_reserves, token_amount)
        with_attr error_message("Can't buy 100% of the AMM"):
            let (is_z) = uint256_eq(denominator, Uint256(0, 0))
            assert is_z = 0
        end
        # Add LP fee
        let (numerator, mul_overflow) = uint256_mul(numerator, Uint256(1000, 0))
        with_attr error_message("Numerator overflow"):
            assert mul_overflow = Uint256(0, 0)
        end
        let (denominator, mul_overflow) = uint256_mul(denominator, lp_fee)
        with_attr error_message("Denominator overflow"):
            assert mul_overflow = Uint256(0, 0)
        end

        # Calculate price
        let (price, remainder) = uint256_unsigned_div_rem(numerator, denominator)

        # Return value if no remainder
        let (is_z) = uint256_eq(remainder, Uint256(0, 0))
        if is_z == (1):
            return (price)
        end

        # Round up when there is a remainder, to favour LP providers
        let (price, _) = uint256_add(price, Uint256(1, 0))
        return (price)
    end
end
