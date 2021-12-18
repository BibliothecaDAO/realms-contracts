%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.token.ERC721_base import (
    ERC721_initializer,
    ERC721_approve, 
    ERC721_set_approval_for_all, 
    ERC721_transferFrom,
    ERC721_safeTransferFrom,
    ERC721_mint,
    ERC721_burn,
    ERC721_balances
)
from contracts.token.IERC20 import IERC20

from contracts.Ownable_base import (
    Ownable_initializer,
    Ownable_only_owner
)

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
        owner: felt
    ):
    ERC721_initializer(name, symbol)
    Ownable_initializer(owner)
    return ()
end

#
# Externals
#

@external
func approve{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, token_id: Uint256):
    ERC721_approve(to, token_id)
    return()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC721_set_approval_for_all(operator, approved)
    return ()
end

@external
func transferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _from: felt, 
        to: felt, 
        token_id: Uint256
    ):
    ERC721_transferFrom(_from, to, token_id)

    let (from_balance: Uint256) = ERC721_balances.read(account=_from)
    erase_balance_details(_from, token_id, from_balance.low - 1)

    let (to_balance: Uint256) = ERC721_balances.read(account=to)
    balance_details.write(to, to_balance.low - 1, token_id)

    return ()
end

@external
func safeTransferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _from: felt, 
        to: felt, 
        token_id: Uint256, 
        data: felt
    ):
    ERC721_safeTransferFrom(_from, to, token_id, data)
    return ()
end

#
# Mintable Methods
#

@external
func mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, token_id: Uint256):
    Ownable_only_owner()
    ERC721_mint(to, token_id)

    let (balance: Uint256) = ERC721_balances.read(to)
    balance_details.write(to, balance.low - 1, token_id)

    return ()
end

@external
func burn{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(token_id: Uint256):
    Ownable_only_owner()
    ERC721_burn(token_id)
    return ()
end

#
# Bibliotheca added methods (remove all balance_details functions after events)
#

# Contract Address of ERC20 used to purchase or sell items
@storage_var
func currency_token_address() -> (address : felt):
end

# Change Payable token to ERC20 address
@external
func update_currency_token{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(_address : felt):
    Ownable_only_owner()

    currency_token_address.write(_address)

    return ()
end

@view
func get_currency_token{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (currency_token_address: felt):
    return currency_token_address.read()
end


from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_zero

# Temporary functions due to no events TOREMOVE
@storage_var
func balance_details(owner: felt, index: felt) -> (token_id: Uint256):
end

func erase_balance_details{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, token_id: Uint256, index: felt):
    alloc_locals

    let (token_at_index) = balance_details.read(owner, index)

    let (tokens_equal) = uint256_eq(token_at_index, token_id)
    if tokens_equal == 1 :
        let (local res: Uint256) = ERC721_balances.read(account=owner)
        let (index_zero) = uint256_eq(res, Uint256(0,0))
        if index_zero == 1:
            return ()
        else:
            # swap and erase. Note that the old end is at 'res + 1' at this point, so we need index 'res'.
            let (last_tok) = balance_details.read(owner, res.low)
            balance_details.write(owner, index, last_tok)
            return ()
        end
    end
    # If index is 0 here, we haven't found the token, which should be impossible.
    assert_not_zero(index)
    return erase_balance_details(owner, token_id, index - 1)
end

# Mint for 10 Currency
@external
func publicMint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(token_id: Uint256):
    alloc_locals

    let (currency) = currency_token_address.read()
    let (caller) = get_caller_address()
    let (contract_address) = get_contract_address()

    IERC20.transferFrom(currency, caller, contract_address, Uint256(10 * (10 ** 18), 0))
    ERC721_mint(caller, token_id)

    let (balance: Uint256) = ERC721_balances.read(caller)
    balance_details.write(caller, balance.low - 1, token_id)

    return ()
end

func populate_tokens{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt, rett: felt*, ret_index: felt,  max: Uint256):
    alloc_locals

    #No check for high value uint256
    if ret_index == max.low:
        return ()
    end
    let(local retval0: Uint256) = balance_details.read(owner=owner, index=ret_index)

    rett[0] = retval0.low
    rett[1] = retval0.high

    #loop until max
    return populate_tokens(owner, rett + 2, ret_index + 1, max)
end

@view
func get_all_tokens_for_owner{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (owner: felt) -> (tokens_len: felt, tokens: felt*):
    alloc_locals
     
    let (local current_balance: Uint256) = ERC721_balances.read(account=owner)
    let (local ret_array : felt*) = alloc()
    local ret_index = 0
    populate_tokens(owner, ret_array, ret_index, current_balance)
    return (current_balance.low * 2, ret_array)
end

@view
func token_at_index{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, index: felt) -> (token: Uint256):
    let (res) = ERC721_balances.read(account=owner)
    let (retval) = balance_details.read(owner=owner, index=index)
    return (retval)
end