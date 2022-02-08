# Declare this file as a StarkNet contract and set the require builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
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

#FIXME Non-reentrant

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

# Total supplied currency (for LP)
@storage_var
func supplies_total(token_id : felt) -> (total : Uint256):
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
    ):
        currency_address.write(currency_address_)
        token_address.write(token_address_)
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
        currency_amount: Uint256,
        token_id: felt,
        token_amount: Uint256,
    ):
        alloc_locals
        let (caller) = get_caller_address()
        let (contract) = get_contract_address()

        let (token_addr) = token_address.read()
        let (currency_addr) = currency_address.read()

        # Only valid for first liquidity add
        let (currency_res) = currency_reserves.read(token_id)
        assert currency_res = Uint256(0, 0)

        IERC20.transferFrom(currency_addr, caller, contract, currency_amount)
        tempvar syscall_ptr :felt* = syscall_ptr
        IERC1155.safeTransferFrom(token_addr, caller, contract, token_id, token_amount.low)

        # Assert otherwise rounding error could end up being significant on second deposit
        let (ok) = uint256_le(Uint256(1000, 0), currency_amount) #FIXME
        assert_not_zero(ok)

        # Update currency  reserve size for Token id before transfer
        currency_reserves.write(token_id, currency_amount)

        # Initial liquidity is amount deposited
        supplies_total.write(token_id, currency_amount)

        # Mint LP tokens
        ERC1155_mint(caller, token_id, currency_amount.low)

        #TODO emit LP Added Event

    return ()
end


@external
func add_liquidity {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        max_currency_amount: Uint256,
        token_id: felt,
        token_amount: Uint256,
    ):
        #FIXME add deadline
        alloc_locals
        let (caller) = get_caller_address()
        let (contract) = get_contract_address()

        let (token_addr) = token_address.read()
        let (currency_addr) = currency_address.read()

        let (supplies_total_prev) = supplies_total.read(token_id)
        let (token_reserves) = IERC1155.balanceOf(token_addr, contract, token_id)
        let (currency_res) = currency_reserves.read(token_id)

        # Only for subsequent liquidity adds
        let (above_zero) = uint256_lt(Uint256(0, 0), currency_res)
        assert_not_zero(above_zero)

        # Required price calc
        # X/Y = dx/dy
        # dx = X*dy/Y
        let (numerator, mul_overflow) = uint256_mul(currency_res, token_amount)
        assert mul_overflow = Uint256(0, 0)
        let (currency_amount, _) = uint256_unsigned_div_rem(numerator, Uint256(token_reserves, 0))
        # Ignore remainder as this favours existing LP holders

        # Check within bounds
        let (ok) = uint256_le(currency_amount, max_currency_amount)
        assert_not_zero(ok)

        IERC20.transferFrom(currency_addr, caller, contract, currency_amount)
        tempvar syscall_ptr :felt* = syscall_ptr
        IERC1155.safeTransferFrom(token_addr, caller, contract, token_id, token_amount.low)

        # Stored values
        let (new_reserves, add_overflow) = uint256_add(currency_res, currency_amount)
        assert (add_overflow) = 0
        currency_reserves.write(token_id, new_reserves)
        let (new_supplies, add_overflow) = uint256_add(supplies_total_prev, currency_amount)
        assert (add_overflow) = 0
        supplies_total.write(token_id, new_supplies)

        # Mint LP tokens
        ERC1155_mint(caller, token_id, currency_amount.low)

        #TODO emit LP Added Event

    return ()
end


@external
func remove_liquidity {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        min_currency_amount: Uint256,
        token_id: felt,
        min_token_amount: Uint256,
        lp_amount: Uint256,
    ):
        #FIXME add deadline
        alloc_locals
        let (caller) = get_caller_address()
        let (contract) = get_contract_address()

        let (token_addr) = token_address.read()
        let (currency_addr) = currency_address.read()

        let (lp_total) = supplies_total.read(token_id)
        let (currency_res) = currency_reserves.read(token_id)

        let (new_supplies) = uint256_sub(lp_total, lp_amount)
        # It should not be possible to go below zero as LP reflects supply
        let (above_zero) = uint256_le(Uint256(0, 0), new_supplies)
        assert_not_zero(above_zero)

        # Calculate percentage of reserves this LP amount is worth
        # Ignore remainder as it favours holders
        let (numerator, mul_overflow) = uint256_mul(currency_res, lp_amount)
        assert mul_overflow = Uint256(0, 0)
        let (currency_owed, _) = uint256_unsigned_div_rem(numerator, lp_total)
        let (token_reserves) = IERC1155.balanceOf(token_addr, contract, token_id)
        let (numerator, mul_overflow) = uint256_mul(Uint256(token_reserves, 0), lp_amount)
        assert mul_overflow = Uint256(0, 0)
        let (tokens_owed, _) = uint256_unsigned_div_rem(numerator, lp_total)

        # New totals
        let (new_currency) = uint256_sub(currency_res, currency_owed)

        # Update storage
        supplies_total.write(token_id, new_supplies)
        currency_reserves.write(token_id, new_currency)

        # Take LP tokens
        ERC1155_burn(caller, token_id, lp_amount.low)
        # Send currency and tokens
        IERC20.transfer(currency_addr, caller, currency_owed)
        tempvar syscall_ptr :felt* = syscall_ptr
        IERC1155.safeTransferFrom(token_addr, contract, caller, token_id, tokens_owed.low)

        #TODO emit LP Removed Event

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
        max_currency_amount: Uint256,
        token_id: felt,
        token_amount: Uint256,
    ) -> (
        sold: Uint256
    ):
    #FIXME Add deadline
    #FIXME Recipient as a param
    alloc_locals
    let (caller) = get_caller_address()
    let (contract) = get_contract_address()

    let (token_addr) = token_address.read()
    let (currency_addr) = currency_address.read()
    
    let (currency_res) = currency_reserves.read(token_id)
    let (token_reserves) = IERC1155.balanceOf(token_addr, contract, token_id)

    # Transfer max currency
    IERC20.transferFrom(currency_addr, caller, contract, max_currency_amount)
    tempvar syscall_ptr :felt* = syscall_ptr

    #FIXME Fees / royalties

    # Calculate prices
    let (currency_amount) = get_buy_price(token_amount, currency_res, Uint256(token_reserves, 0))

    #TODO Fees

    # Calculate refund
    let (refund_amount) = uint256_sub(max_currency_amount, currency_amount)

    # Update reserves
    let (new_reserves, add_overflow) = uint256_add(currency_res, currency_amount)
    assert add_overflow = 0
    currency_reserves.write(token_id, new_reserves)

    # Transfer refunded currency and purchased tokens
    IERC20.transfer(currency_addr, caller, refund_amount)
    tempvar syscall_ptr :felt* = syscall_ptr
    IERC1155.safeTransferFrom(token_addr, contract, caller, token_id, token_amount.low)

    return (currency_amount)
end


#FIXME IERC1155 doesn't have a call back when using ERC1155.safeTransfer.
# User will need to `setApprovalForAll` to this contract, which poses a security risk for repeat transactions.
@external
func sell_tokens {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        min_currency_amount: Uint256,
        token_id: felt,
        token_amount: Uint256,
    ) -> (
        sold: Uint256
    ):
    #FIXME Add deadline
    #FIXME Recipient as a param
    alloc_locals
    let (caller) = get_caller_address()
    let (contract) = get_contract_address()

    let (token_addr) = token_address.read()
    let (currency_addr) = currency_address.read()
    
    let (currency_res) = currency_reserves.read(token_id)
    let (token_reserves) = IERC1155.balanceOf(token_addr, contract, token_id)

    # Take the token amount
    IERC1155.safeTransferFrom(token_addr, caller, contract, token_id, token_amount.low)

    # Calculate prices
    let (currency_amount) = get_sell_price(token_amount, currency_res, Uint256(token_reserves, 0))

    # Check min_currency_amount
    let (above_min_curr) = uint256_le(min_currency_amount, currency_amount)
    assert_not_zero(above_min_curr)

    # Transfer currency
    IERC20.transfer(currency_addr, caller, currency_amount)
    tempvar syscall_ptr :felt* = syscall_ptr

    # Update reserves
    let (new_reserves) = uint256_sub(currency_res, currency_amount)
    currency_reserves.write(token_id, new_reserves)

    return (currency_amount)
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
        token_amount: Uint256,
        currency_reserves: Uint256,
        token_reserves: Uint256,
    ) -> (
        price: Uint256
    ):
    alloc_locals

    # Calculate price
    #FIXME Add fee
    let (numerator, is_overflow) = uint256_mul(currency_reserves, token_amount)
    assert is_overflow = Uint256(0, 0)
    let (token_res_left) = uint256_sub(token_reserves, token_amount)
    let (price, remainder) = uint256_unsigned_div_rem(numerator, token_res_left)
    #FIXME If remainder then add 1
    # let (is_not_z) = uint256_eq(remainder, Uint256(0, 0))
    # if is_not_z == (1):
    #     let (price, _) = uint256_add(price, Uint256(1, 0))
    # end

    return (price)

end


@view
func get_sell_price {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token_amount: Uint256,
        currency_reserves: Uint256,
        token_reserves: Uint256,
    ) -> (
        price: Uint256
    ):
    alloc_locals

    # Calculate price
    #FIXME Add fee
    let (numerator, mul_overflow) = uint256_mul(token_amount, currency_reserves)
    assert mul_overflow = Uint256(0, 0)
    let (local denominator: Uint256, is_overflow) = uint256_add(token_reserves, token_amount)
    assert is_overflow = 0
    let (price, _) = uint256_unsigned_div_rem(numerator, denominator)

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
