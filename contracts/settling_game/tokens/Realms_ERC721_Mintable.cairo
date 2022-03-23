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
    ERC721_name, ERC721_symbol, ERC721_balanceOf, ERC721_ownerOf, ERC721_getApproved,
    ERC721_isApprovedForAll, ERC721_initializer, ERC721_approve, ERC721_setApprovalForAll,
    ERC721_transferFrom, ERC721_safeTransferFrom, ERC721_mint, ERC721_burn,
    ERC721_tokenURI, ERC721_setTokenURI)

from contracts.openzeppelin.introspection.ERC165 import ERC165_supports_interface
from contracts.openzeppelin.introspection.IERC165 import IERC165

from contracts.Ownable_base import Ownable_initializer, Ownable_only_owner
from contracts.settling_game.utils.game_structs import RealmData
#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        name : felt, symbol : felt, owner : felt):
    ERC721_initializer(name, symbol)
    Ownable_initializer(owner)

    return ()
end

#
# Getters
#

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        interfaceId : felt) -> (success : felt):
    let (success) = ERC165_supports_interface(interfaceId)
    return (success)
end

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = ERC721_name()
    return (name)
end

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = ERC721_symbol()
    return (symbol)
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
        balance : Uint256):
    let (balance : Uint256) = ERC721_balanceOf(owner)
    return (balance)
end

@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (owner : felt):
    let (owner : felt) = ERC721_ownerOf(token_id)
    return (owner)
end

@view
func getApproved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (approved : felt):
    let (approved : felt) = ERC721_getApproved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, operator : felt) -> (isApproved : felt):
    let (isApproved : felt) = ERC721_isApprovedForAll(owner, operator)
    return (isApproved)
end

@view
func tokenURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (tokenURI : felt):
    let (tokenURI : felt) = ERC721_tokenURI(tokenId)
    return (tokenURI)
end

#
# Externals
#

@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        to : felt, tokenId : Uint256):
    ERC721_approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt, approved : felt):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, tokenId : Uint256):
    ERC721_transferFrom(_from, to, tokenId)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, tokenId : Uint256, data_len : felt, data : felt*):
    ERC721_safeTransferFrom(_from, to, tokenId, data_len, data)
    return ()
end

@external
func setTokenURI{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        tokenId : Uint256, tokenURI : felt):
    Ownable_only_owner()
    ERC721_setTokenURI(tokenId, tokenURI)
    return ()
end
# Mintable Methods
#

@external
func mint{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        to : felt, tokenId : Uint256, _realm_name : felt, _realm_data : felt):
    Ownable_only_owner()
    ERC721_mint(to, tokenId)
    realm_name.write(tokenId, _realm_name)
    realm_data.write(tokenId, _realm_data)
    return ()
end

@external
func burn{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(tokenId : Uint256):
    Ownable_only_owner()
    ERC721_burn(tokenId)
    return ()
end
#
# Bibliotheca added methods (remove all balance_details functions after events)
#

# # democritus methods for on-chain data
@storage_var
func realm_name(token_id : Uint256) -> (name : felt):
end

@storage_var
func realm_data(token_id : Uint256) -> (data : felt):
end

@storage_var
func is_settled(token_id : Uint256) -> (data : felt):
end

@view
func get_is_settled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (is_settled : felt):
    let (data) = is_settled.read(token_id)
    return (data)
end

@view
func settleState{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, settle_state : felt) -> ():
    is_settled.write(token_id, settle_state)
    return ()
end

@external
func get_realm_info{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (realm_data : felt):
    let (data) = realm_data.read(token_id)
    return (data)
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
    # 1. Create a 8-bit mask at and to the left of the index
    # E.g., 000111100 = 2**2 + 2**3 + 2**4 + 2**5
    # E.g.,  2**(i) + 2**(i+1) + 2**(i+2) + 2**(i+3) = (2**i)(15)
    let (power) = pow(2, index)
    # 1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 = 15
    let mask = 255 * power

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

    let (local cities) = unpack_realm_data(realm_id, 0)
    let (local regions) = unpack_realm_data(realm_id, 8)
    let (local rivers) = unpack_realm_data(realm_id, 16)
    let (local harbours) = unpack_realm_data(realm_id, 24)
    let (local resource_number) = unpack_realm_data(realm_id, 32)
    let (local resource_1) = unpack_realm_data(realm_id, 40)
    let (local resource_2) = unpack_realm_data(realm_id, 48)
    let (local resource_3) = unpack_realm_data(realm_id, 56)
    let (local resource_4) = unpack_realm_data(realm_id, 64)
    let (local resource_5) = unpack_realm_data(realm_id, 72)
    let (local resource_6) = unpack_realm_data(realm_id, 80)
    let (local resource_7) = unpack_realm_data(realm_id, 88)
    let (local wonder) = unpack_realm_data(realm_id, 96)
    let (local order) = unpack_realm_data(realm_id, 104)

    let realm_stats = RealmData(
        cities=cities,
        regions=regions,
        rivers=rivers,
        harbours=harbours,
        resource_number=resource_number,
        resource_1=resource_1,
        resource_2=resource_2,
        resource_3=resource_3,
        resource_4=resource_4,
        resource_5=resource_5,
        resource_6=resource_6,
        resource_7=resource_7,
        wonder=wonder,
        order=order)
    return (realm_stats=realm_stats)
end
