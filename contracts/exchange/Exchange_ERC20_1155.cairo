# Declare this file as a StarkNet contract and set the require builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem
from starkware.cairo.common.uint256 import (Uint256, uint256_le)

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155

# Contract Address of ERC20 address for this swap contract
@storage_var
func currency_address() -> (address : felt):
end

# Contract Address of ERC1155 address for this swap contract
@storage_var
func token_address() -> (address : felt):
end

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
