%lang starknet
%builtins pedersen range_check ecdsa bitwise
from starkware.cairo.common.bitwise import bitwise_and

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_zero

from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.pow import pow

from contracts.token.IERC20 import IERC20

from contracts.token.ERC721_base import (
    ERC721_name,
    ERC721_symbol,
    ERC721_balanceOf,
    ERC721_ownerOf,
    ERC721_getApproved,
    ERC721_isApprovedForAll,

    ERC721_initializer,
    ERC721_approve, 
    ERC721_setApprovalForAll, 
    ERC721_transferFrom,
    ERC721_safeTransferFrom,
    ERC721_mint,
    ERC721_burn
)

from contracts.token.ERC721_Metadata_base import (
    ERC721_Metadata_initializer,
    ERC721_Metadata_tokenURI,
    ERC721_Metadata_setTokenURI,
)

from contracts.ERC165_base import (
    ERC165_supports_interface
)

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
        owner: felt,
        currency_address: felt

    ):
    ERC721_initializer(name, symbol)
    ERC721_Metadata_initializer()
    Ownable_initializer(owner)
    currency_token_address.write(currency_address) # Biblio added currency address

    return ()
end

#
# Getters
#

@view
func supportsInterface{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(interfaceId: felt) -> (success: felt):
    let (success) = ERC165_supports_interface(interfaceId)
    return (success)
end

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC721_name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC721_symbol()
    return (symbol)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC721_balanceOf(owner)
    return (balance)
end

@view
func ownerOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (owner: felt):
    let (owner: felt) = ERC721_ownerOf(token_id)
    return (owner)
end

@view
func getApproved{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (approved: felt):
    let (approved: felt) = ERC721_getApproved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, operator: felt) -> (isApproved: felt):
    let (isApproved: felt) = ERC721_isApprovedForAll(owner, operator)
    return (isApproved)
end

@view
func tokenURI{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (tokenURI: felt):
    let (tokenURI: felt) = ERC721_Metadata_tokenURI(tokenId)
    return (tokenURI)
end


#
# Externals
#

@external
func approve{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    ERC721_approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC721_setApprovalForAll(operator, approved)
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
        tokenId: Uint256
    ):
    ERC721_transferFrom(_from, to, tokenId)
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
        tokenId: Uint256,
        data_len: felt, 
        data: felt*
    ):
    ERC721_safeTransferFrom(_from, to, tokenId, data_len, data)
    return ()
end

@external
func setTokenURI{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256, tokenURI: felt):
    Ownable_only_owner()
    ERC721_Metadata_setTokenURI(tokenId, tokenURI)
    return ()
end

@external
func mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    Ownable_only_owner()
    ERC721_mint(to, tokenId)
    return ()
end

@external
func burn{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256):
    Ownable_only_owner()
    ERC721_burn(tokenId)
    return ()
end


#
# Bibliotheca added methods (remove all balance_details functions after events)
#

# # democritus methods for on-chain data
@storage_var
func realm_name(realm_id : Uint256) -> (name : felt):
end

@storage_var
func realm_data(realm_id : Uint256) -> (data : felt):
end

@storage_var
func is_settled(realm_id : Uint256) -> (data : felt):
end

@external
func get_realm_info{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        realm_id : Uint256) -> (realm_data : felt):
    let (data) = realm_data.read(realm_id)
    return (data)
end

struct RealmData:
    member cities : felt  #
    member regions : felt  #
    member rivers : felt  #
    member harbours : felt  # 
    member resource_1 : felt  # 
    member resource_2 : felt  # 
    member resource_3 : felt  # 
    member resource_4 : felt  # 
    member resource_5 : felt  # 
    member resource_6 : felt  # 
    member resource_7 : felt  #            
end

func unpack_realm_data{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(realm_id : Uint256, index : felt) -> (score : felt):
    alloc_locals
    # User data is a binary encoded value with alternating
    # 6-bit id followed by a 4-bit score (see top of file).
    let (local data) = realm_data.read(realm_id)
    local syscall_ptr : felt* = syscall_ptr
    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
    # 1. Create a 4-bit mask at and to the left of the index
    # E.g., 000111100 = 2**2 + 2**3 + 2**4 + 2**5
    # E.g.,  2**(i) + 2**(i+1) + 2**(i+2) + 2**(i+3) = (2**i)(15)
    let (power) = pow(2, index)
    # 1 + 2 + 4 + 8 = 15
    let mask = 15 * power

    # 2. Apply mask using bitwise operation: mask AND data.
    let (masked) = bitwise_and(mask, data)

    # 3. Shift element right by dividing by the order of the mask.
    let (result, _) = unsigned_div_rem(masked, power)

    return (score=result)
end

@external
func fetch_realm_data{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(realm_id : Uint256) -> (realm_stats : RealmData):
    alloc_locals

    # Indicies are defined in the UserRegistry contract.
    # Call the UserRegsitry contract to get scores for given user.
    let (local cities) = unpack_realm_data(realm_id, 0)
    let (local regions) = unpack_realm_data(realm_id, 6)
    let (local rivers) = unpack_realm_data(realm_id, 12)
    let (local harbours) = unpack_realm_data(realm_id, 18)
    let (local resource_1) = unpack_realm_data(realm_id, 24)
    let (local resource_2) = unpack_realm_data(realm_id, 30)
    let (local resource_3) = unpack_realm_data(realm_id, 36)
    let (local resource_4) = unpack_realm_data(realm_id, 42)
    let (local resource_5) = unpack_realm_data(realm_id, 48)
    let (local resource_6) = unpack_realm_data(realm_id, 54)
    let (local resource_7) = unpack_realm_data(realm_id, 60)

    # Populate struct.
    let realm_stats = RealmData(
        cities=cities,
        regions=regions,
        rivers=rivers,
        harbours=harbours,
        resource_1=resource_1,
        resource_2=resource_2,
        resource_3=resource_3,
        resource_4=resource_4,
        resource_5=resource_5,
        resource_6=resource_6,
        resource_7=resource_7                
        )
    return (realm_stats=realm_stats)
end

# Contract Address of ERC20 used to purchase or sell items
@storage_var
func currency_token_address() -> (address : felt):
end

# Change Payable token to ERC20 address
@external
func update_currency_token{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _address : felt):
    Ownable_only_owner()

    currency_token_address.write(_address)

    return ()
end

@view
func get_currency_token{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        currency_token_address : felt):
    return currency_token_address.read()
end

# Temporary functions due to no events TOREMOVE
@storage_var
func balance_details(owner : felt, index : felt) -> (token_id : Uint256):
end

func erase_balance_details{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        owner : felt, token_id : Uint256, index : felt):
    alloc_locals

    let (token_at_index) = balance_details.read(owner, index)

    let (tokens_equal) = uint256_eq(token_at_index, token_id)
    if tokens_equal == 1:
        let (local res : Uint256) = ERC721_balanceOf(owner)
        let (index_zero) = uint256_eq(res, Uint256(0, 0))
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
func publicMint{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        token_id : Uint256):
    alloc_locals

    let (currency) = currency_token_address.read()
    let (caller) = get_caller_address()
    let (contract_address) = get_contract_address()

    IERC20.transferFrom(currency, caller, contract_address, Uint256(10 * (10 ** 18), 0))
    ERC721_mint(caller, token_id)

    let (balance : Uint256) = ERC721_balanceOf(caller)
    balance_details.write(caller, balance.low - 1, token_id)

    return ()
end

func populate_tokens{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        owner : felt, rett : felt*, ret_index : felt, max : Uint256):
    alloc_locals

    # No check for high value uint256
    if ret_index == max.low:
        return ()
    end
    let (local retval0 : Uint256) = balance_details.read(owner=owner, index=ret_index)

    rett[0] = retval0.low
    rett[1] = retval0.high

    # loop until max
    return populate_tokens(owner, rett + 2, ret_index + 1, max)
end

@view
func get_all_tokens_for_owner{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        owner : felt) -> (tokens_len : felt, tokens : felt*):
    alloc_locals

    let (local current_balance : Uint256) = ERC721_balanceOf(owner)
    let (local ret_array : felt*) = alloc()
    local ret_index = 0
    populate_tokens(owner, ret_array, ret_index, current_balance)
    return (current_balance.low * 2, ret_array)
end

@view
func token_at_index{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, index : felt) -> (token : Uint256):
    let (res) = ERC721_balanceOf(owner)
    let (retval) = balance_details.read(owner=owner, index=index)
    return (retval)
end
