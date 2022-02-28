%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, get_block_timestamp
from starkware.cairo.common.math import assert_nn, assert_le, assert_not_zero
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add, uint256_sub, uint256_mul, uint256_unsigned_div_rem,
    uint256_le, uint256_lt, uint256_check, uint256_eq
)

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155
from contracts.token.ERC1155.ERC1155_struct import TokenUri
from contracts.token.ERC1155.ERC1155_base import (
    ERC1155_transfer_from,
    ERC1155_batch_transfer_from,
    ERC1155_mint,
    ERC1155_burn,
    ERC1155_set_approval_for_all,
    ERC1155_assert_is_owner_or_approved,
)

@event
func liquidity_added(
        caller: felt,
        currency_amount: Uint256,
        token_id: felt,
        token_amount: Uint256,
    ):
end

@event
func liquidity_removed(
        caller: felt,
        currency_amount: Uint256,
        token_id: felt,
        token_amount: Uint256,
    ):
end

@event
func tokens_purchased(
        caller: felt,
        currency_sold: Uint256,
        token_id: felt,
        tokens_bought: Uint256,
    ):
end

@event
func currency_purchased(
        caller: felt,
        currency_bought: Uint256,
        token_id: felt,
        tokens_sold: Uint256,
    ):
end

# Contract Address of ERC20 address for this swap contract
@storage_var
func currency_address() -> (address : felt):
end

# Contract Address of ERC1155 address for this swap contract
@storage_var
func token_address() -> (address : felt):
end

# Current reserves of currency
@storage_var
func currency_reserves(token_id : felt) -> (reserves : Uint256):
end

# Total issued LP totals
@storage_var
func lp_reserves(token_id : felt) -> (total : Uint256):
end

# Liquidity pool rewards in thousandths (e.g. 15 = 1.5% fee)
@storage_var
func lp_fee_thousands() -> (lp_fee_thousands : Uint256):
end

# Note: We use ERC1155_balanceOf(contract_address) to record token reserves

@constructor
func constructor {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        currency_address_: felt,
        token_address_: felt,
        lp_fee_thousands_: Uint256,
    ):
    currency_address.write(currency_address_)
    token_address.write(token_address_)
    lp_fee_thousands.write(lp_fee_thousands_)
    return ()
end

#
# Liquidity
#

@external
func initial_liquidity {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        # Amount of currency supplied to LP
        currency_amounts_len: felt,
        currency_amounts: Uint256*,
        # ERC1155 token id
        token_ids_len: felt,
        token_ids: felt*,
        # Amount of token supplied
        token_amounts_len: felt,
        token_amounts: Uint256*,
    ):
    alloc_locals

    if currency_amounts_len == 0:
        return ()
    end

    assert currency_amounts_len = token_ids_len
    assert token_ids_len = token_amounts_len

    let (caller) = get_caller_address()
    let (contract) = get_contract_address()

    let (token_address_) = token_address.read()
    let (currency_address_) = currency_address.read()

    # Only valid for first liquidity add to LP
    let (currency_reserves_) = currency_reserves.read([token_ids])
    with_attr error_message("Only valid for initial liquidity add"):
        assert currency_reserves_ = Uint256(0, 0)
    end

    # Transfer currency and token to exchange
    IERC20.transferFrom(currency_address_, caller, contract, [currency_amounts])
    tempvar syscall_ptr :felt* = syscall_ptr
    IERC1155.safeTransferFrom(token_address_, caller, contract, [token_ids], [token_amounts].low)

    # Assert otherwise rounding error could end up being significant on second deposit
    let (ok) = uint256_le(Uint256(1000, 0), [currency_amounts])
    with_attr error_message("Must supply larger currency for initial deposit"):
        assert_not_zero(ok)
    end

    # Update currency reserve size for token id before transfer
    currency_reserves.write([token_ids], [currency_amounts])

    # Initial liquidity is currency amount deposited
    lp_reserves.write([token_ids], [currency_amounts])

    # Mint LP tokens
    ERC1155_mint(caller, [token_ids], [currency_amounts].low)

    # Emit event
    liquidity_added.emit(caller, [currency_amounts], [token_ids], [token_amounts])

    # Recurse
    return initial_liquidity(
        currency_amounts_len - 1,
        currency_amounts + 2, # uint
        token_ids_len - 1,
        token_ids + 1,
        token_amounts_len - 1,
        token_amounts + 2,
    )
end


@external
func add_liquidity {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        # Maximum amount of currency supplied to LP
        max_currency_amount: Uint256,
        # ERC1155 token id
        token_id: felt,
        # Fixed amount of token supplied
        token_amount: Uint256,
        # Maximum time which this transaction can be accepted
        deadline: felt,
    ):
    alloc_locals

    # Check deadline within bounds
    let (block_timestamp) = get_block_timestamp()
    with_attr error_message("Deadline exceeded"):
        assert_le(block_timestamp, deadline)
    end

    let (caller) = get_caller_address()
    let (contract) = get_contract_address()

    let (token_address_) = token_address.read()
    let (currency_address_) = currency_address.read()

    # Read current reserve levels
    let (lp_reserves_) = lp_reserves.read(token_id)
    let (token_reserves ) = IERC1155.balanceOf(token_address_, contract, token_id)
    let (currency_reserves_) = currency_reserves.read(token_id)

    # Ensure this method is only called for subsequent liquidity adds
    let (above_zero) = uint256_lt(Uint256(0, 0), currency_reserves_)
    with_attr error_message("This method is only for subsequent liquidity additions"):
        assert_not_zero(above_zero)
    end

    # Required price calc
    # X/Y = dx/dy
    # dx = X*dy/Y
    let (numerator, mul_overflow) = uint256_mul(currency_reserves_, token_amount)
    with_attr error_message("Values too large"):
        assert mul_overflow = Uint256(0, 0)
    end
    let (currency_amount, _) = uint256_unsigned_div_rem(numerator, Uint256(token_reserves, 0))
    # Ignore remainder as this favours existing LP holders

    # Check within bounds of the maximum allowed currency spend
    let (ok) = uint256_le(currency_amount, max_currency_amount)
    with_attr error_message("Price exceeds max currency amount"):
        assert_not_zero(ok)
    end

    # Transfer tokens to exchange contract
    IERC20.transferFrom(currency_address_, caller, contract, currency_amount)
    tempvar syscall_ptr :felt* = syscall_ptr
    IERC1155.safeTransferFrom(token_address_, caller, contract, token_id, token_amount.low)

    # Update the new currency and LP reserves
    let (new_reserves, add_overflow) = uint256_add(currency_reserves_, currency_amount)
    with_attr error_message("Currency value overflow"):
        assert (add_overflow) = 0
    end
    currency_reserves.write(token_id, new_reserves)
    let (new_supplies, add_overflow) = uint256_add(lp_reserves_, currency_amount)
    with_attr error_message("LP value overflow"):
        assert (add_overflow) = 0
    end
    lp_reserves.write(token_id, new_supplies)

    # Mint LP tokens
    ERC1155_mint(caller, token_id, currency_amount.low)

    # Emit event
    liquidity_added.emit(caller, currency_amount, token_id, token_amount)

    return ()
end


@external
func remove_liquidity {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        # Minimum amount of currency received from LP
        min_currency_amount: Uint256,
        # ERC1155 token id
        token_id: felt,
        # Minimum amount of tokens received from LP
        min_token_amount: Uint256,
        # Exact amount of LP tokens to spend
        lp_amount: Uint256,
        # Maximum time which this transaction can be accepted
        deadline: felt,
    ):
    alloc_locals

    # Check deadline within bounds
    let (block_timestamp) = get_block_timestamp()
    with_attr error_message("Deadline exceeded"):
        assert_le(block_timestamp, deadline)
    end

    let (caller) = get_caller_address()
    let (contract) = get_contract_address()

    let (token_address_) = token_address.read()
    let (currency_address_) = currency_address.read()

    # Read current reserve levels
    let (lp_reserves_) = lp_reserves.read(token_id)
    let (currency_reserves_) = currency_reserves.read(token_id)
    let (token_reserves) = IERC1155.balanceOf(token_address_, contract, token_id)

    let (new_supplies) = uint256_sub(lp_reserves_, lp_amount)
    # It should not be possible to go below zero as LP reflects supply
    let (above_zero) = uint256_le(Uint256(0, 0), new_supplies)
    with_attr error_message("LP total exceeded"):
        assert_not_zero(above_zero)
    end

    # Calculate percentage of reserves this LP amount is worth
    let (numerator, mul_overflow) = uint256_mul(currency_reserves_, lp_amount)
    with_attr error_message("Values too large"):
        assert mul_overflow = Uint256(0, 0)
    end
    let (currency_owed, _) = uint256_unsigned_div_rem(numerator, lp_reserves_)
    let (numerator, mul_overflow) = uint256_mul(Uint256(token_reserves, 0), lp_amount)
    with_attr error_message("Values too large"):
        assert mul_overflow = Uint256(0, 0)
    end
    # Ignore remainder as it favours LP holders
    let (tokens_owed, _) = uint256_unsigned_div_rem(numerator, lp_reserves_)

    # Check actual values to receive are above minimum values requested
    let (above_min) = uint256_le(min_currency_amount, currency_owed)
    with_attr error_message("Minimum currency amount exceeded"):
        assert_not_zero(above_min)
    end
    let (above_min) = uint256_le(min_token_amount, tokens_owed)
    with_attr error_message("Minimum token amount exceeded"):
        assert_not_zero(above_min)
    end

    # New totals
    let (new_currency) = uint256_sub(currency_reserves_, currency_owed)

    # Update storage
    lp_reserves.write(token_id, new_supplies)
    currency_reserves.write(token_id, new_currency)

    # Take LP tokens
    ERC1155_burn(caller, token_id, lp_amount.low)
    # Send currency and tokens
    IERC20.transfer(currency_address_, caller, currency_owed)
    tempvar syscall_ptr :felt* = syscall_ptr
    IERC1155.safeTransferFrom(token_address_, contract, caller, token_id, tokens_owed.low)

    # Emit event
    liquidity_removed.emit(caller, currency_owed, token_id, tokens_owed)

    return ()
end


#
# Swaps
#


@external
func buy_tokens {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        # Maximum amount of currency to sell
        max_currency_amount: Uint256,
        # Amount of following arg
        token_ids_len: felt,
        # ERC1155 token ids
        token_ids: felt*,
        # Amount of following arg
        token_amounts_len: felt,
        # Exact amount of tokens to buy
        token_amounts: Uint256*,
        # Maximum time which this transaction can be accepted
        deadline: felt,
    ) -> (
        sold: Uint256
    ):
    alloc_locals

    assert token_ids_len = token_amounts_len

    # Check deadline within bounds
    let (block_timestamp) = get_block_timestamp()
    with_attr error_message("Deadline exceeded"):
        assert_le(block_timestamp, deadline)
    end

    # Loop
    let (currency_amount) = buy_tokens_loop(
        token_ids_len,
        token_ids,
        token_amounts_len,
        token_amounts
    )

    let (above_max_curr) = uint256_le(currency_amount, max_currency_amount)
    with_attr error_message("Maximum currency amount exceeded"):
        assert_not_zero(above_max_curr)
    end

    return (currency_amount)

end


func buy_tokens_loop {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        # Amount of following arg
        token_ids_len: felt,
        # ERC1155 token ids
        token_ids: felt*,
        # Amount of following arg
        token_amounts_len: felt,
        # Exact amount of tokens to buy
        token_amounts: Uint256*,
    ) -> (
        sold: Uint256
    ):
    alloc_locals

    # Recursive break
    if token_ids_len == 0:
        return (Uint256(0, 0))
    end

    let (caller) = get_caller_address()
    let (contract) = get_contract_address()

    let (token_address_) = token_address.read()
    let (currency_address_) = currency_address.read()

    # Read current reserve levels
    let (currency_reserves_) = currency_reserves.read([token_ids])
    let (token_reserves) = IERC1155.balanceOf(token_address_, contract, [token_ids])

    # Calculate prices
    let (currency_amount) = get_buy_price([token_amounts], currency_reserves_, Uint256(token_reserves, 0))

    # Update reserves
    let (new_reserves, add_overflow) = uint256_add(currency_reserves_, currency_amount)
    with_attr error_message("Currency value overflow"):
        assert add_overflow = 0
    end
    currency_reserves.write([token_ids], new_reserves)

    # Transfer currency and purchased tokens
    IERC20.transferFrom(currency_address_, caller, contract, currency_amount)
    tempvar syscall_ptr :felt* = syscall_ptr
    IERC1155.safeTransferFrom(token_address_, contract, caller, [token_ids], [token_amounts].low)

    # Emit event
    tokens_purchased.emit(caller, currency_amount, [token_ids], [token_amounts])

    # Recurse
    let (currency_total) = buy_tokens_loop(
        token_ids_len - 1,
        token_ids + 1,
        token_amounts_len - 1,
        token_amounts + 2 # Uint
    )
    let (currency_sold, add_overflow) = uint256_add(currency_total, currency_amount)
    with_attr error_message("Total currency overflow"):
        assert add_overflow = 0
    end

    return (currency_sold)
end


#FIXME IERC1155 doesn't have a call back when using ERC1155.safeTransfer.
# User will need to `setApprovalForAll` to this contract, which poses a security risk for repeat transactions.
@external
func sell_tokens {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        # Maximum amount of currency to buy
        min_currency_amount: Uint256,
        # Amount of following arg
        token_ids_len: felt,
        # ERC1155 token id
        token_ids: felt*,
        # Amount of following arg
        token_amounts_len: felt,
        # Exact amount of token to sell
        token_amounts: Uint256*,
        # Maximum time which this transaction can be accepted
        deadline: felt,
    ) -> (
        sold: Uint256
    ):
    alloc_locals

    assert token_ids_len = token_amounts_len

    # Check deadline within bounds
    let (block_timestamp) = get_block_timestamp()
    with_attr error_message("Deadline exceeded"):
        assert_le(block_timestamp, deadline)
    end

    # Loop
    let (currency_amount) = sell_tokens_loop(
        token_ids_len,
        token_ids,
        token_amounts_len,
        token_amounts
    )

    # Check min_currency_amount
    let (above_min) = uint256_le(min_currency_amount, currency_amount)
    with_attr error_message("Below minimum currency amount"):
        assert_not_zero(above_min)
    end

    return (currency_amount)

end

# Internal
func sell_tokens_loop {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        # Amount of following arg
        token_ids_len: felt,
        # ERC1155 token id
        token_ids: felt*,
        # Amount of following arg
        token_amounts_len: felt,
        # Exact amount of token to sell
        token_amounts: Uint256*,
    ) -> (
        sold: Uint256
    ):
    alloc_locals

    # Recursive break
    if token_ids_len == 0:
        return (Uint256(0, 0))
    end

    let (caller) = get_caller_address()
    let (contract) = get_contract_address()

    let (token_address_) = token_address.read()
    let (currency_address_) = currency_address.read()

    # Read current reserve levels
    let (currency_reserves_) = currency_reserves.read([token_ids])
    let (token_reserves) = IERC1155.balanceOf(token_address_, contract, [token_ids])

    # Take the token amount
    IERC1155.safeTransferFrom(token_address_, caller, contract, [token_ids], [token_amounts].low)

    # Calculate prices
    let (currency_amount) = get_sell_price([token_amounts], currency_reserves_, Uint256(token_reserves, 0))

    # Transfer currency
    IERC20.transfer(currency_address_, caller, currency_amount)
    tempvar syscall_ptr :felt* = syscall_ptr

    # Update reserves
    let (new_reserves) = uint256_sub(currency_reserves_, currency_amount)
    currency_reserves.write([token_ids], new_reserves)

    # Emit event
    currency_purchased.emit(caller, currency_amount, [token_ids], [token_amounts])

    # Recurse
    let (currency_total) = sell_tokens_loop(
        token_ids_len - 1,
        token_ids + 1,
        token_amounts_len - 1,
        token_amounts + 2 # Uint
    )
    let (currency_owed, add_overflow) = uint256_add(currency_total, currency_amount)
    with_attr error_message("Total currency overflow"):
        assert add_overflow = 0
    end

    return (currency_owed)
end


#
# Pricing
#


@view
func get_buy_price {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        # Exact amount of token to buy
        token_amount: Uint256,
        # Currency reserve amount
        currency_reserves: Uint256,
        # Token reserve amount
        token_reserves: Uint256,
    ) -> (
        price: Uint256
    ):
    alloc_locals

    # LP fee is used to withold currency as reward to LP providers
    let (lp_fee_thousands_) = lp_fee_thousands.read()
    let (lp_fee) = uint256_sub(Uint256(1000, 0), lp_fee_thousands_)

    # Calculate price
    let (numerator, mul_overflow) = uint256_mul(currency_reserves, token_amount)
    with_attr error_message("Values too large"):
        assert mul_overflow = Uint256(0, 0)
    end
    let (denominator) = uint256_sub(token_reserves, token_amount)

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


@view
func get_sell_price {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        # Exact amount of token to sell
        token_amount: Uint256,
        # Currency reserve amount
        currency_reserves: Uint256,
        # Token reserve amount
        token_reserves: Uint256,
    ) -> (
        price: Uint256
    ):
    alloc_locals

    # LP fee is used to withold currency as reward to LP providers
    let (lp_fee_thousands_) = lp_fee_thousands.read()
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
    # Rounding errors favour the contract
    return (price)

end

#
# Getters
#

@view
func get_currency_address {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (currency_address: felt):
    return currency_address.read()
end

@view
func get_token_address {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (token_address: felt):
    return token_address.read()
end

@view
func get_currency_reserves {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token_id: felt
    ) -> (
        currency_reserves: Uint256
    ):
    return currency_reserves.read(token_id)
end

@view
func get_lp_fee_thousands {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
    ) -> (
        lp_fee_thousands: Uint256
    ):
    return lp_fee_thousands.read()
end

#
# ERC 1155
#

@external
func setApprovalForAll{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        operator : felt, approved : felt):
    let (account) = get_caller_address()
    ERC1155_set_approval_for_all(operator, approved)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        sender : felt, recipient : felt, token_id : felt, amount : felt):
    ERC1155_assert_is_owner_or_approved(sender)
    ERC1155_transfer_from(sender, recipient, token_id, amount)
    return ()
end

@external
func safeBatchTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        sender : felt, recipient : felt, tokens_id_len : felt, tokens_id : felt*,
        amounts_len : felt, amounts : felt*):
    ERC1155_assert_is_owner_or_approved(sender)
    ERC1155_batch_transfer_from(sender, recipient, tokens_id_len, tokens_id, amounts_len, amounts)
    return ()
end
