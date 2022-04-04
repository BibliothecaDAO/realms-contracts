# SPDX-License-Identifier: MIT
# OpenZeppelin Cairo Contracts v0.1.0 (token/erc721/ERC721_Mintable_Burnable.cairo)

%lang starknet

from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_zero, unsigned_div_rem
from starkware.cairo.common.pow import pow

from contracts.settling_game.utils.general import unpack_data

from openzeppelin.token.erc721.library import (
    ERC721_name, ERC721_symbol, ERC721_balanceOf, ERC721_ownerOf, ERC721_getApproved,
    ERC721_isApprovedForAll, ERC721_tokenURI, ERC721_initializer, ERC721_approve,
    ERC721_setApprovalForAll, ERC721_transferFrom, ERC721_safeTransferFrom, ERC721_mint,
    ERC721_burn, ERC721_only_token_owner, ERC721_setTokenURI)

from openzeppelin.introspection.ERC165 import ERC165_supports_interface

from openzeppelin.access.ownable import Ownable_initializer, Ownable_only_owner

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
        tokenId : Uint256) -> (owner : felt):
    let (owner : felt) = ERC721_ownerOf(tokenId)
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
        from_ : felt, to : felt, tokenId : Uint256):
    ERC721_transferFrom(from_, to, tokenId)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        from_ : felt, to : felt, tokenId : Uint256, data_len : felt, data : felt*):
    ERC721_safeTransferFrom(from_, to, tokenId, data_len, data)
    return ()
end

@external
func setTokenURI{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        tokenId : Uint256, tokenURI : felt):
    Ownable_only_owner()
    ERC721_setTokenURI(tokenId, tokenURI)
    return ()
end

@external
func mint{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        to : felt, tokenId : Uint256):
    Ownable_only_owner()
    ERC721_mint(to, tokenId)
    return ()
end

@external
func burn{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(tokenId : Uint256):
    ERC721_only_token_owner(tokenId)
    ERC721_burn(tokenId)
    return ()
end

#
# Bibliotheca added methods
#

@storage_var
func realm_name(token_id : Uint256) -> (name : felt):
end

@storage_var
func realm_data(token_id : Uint256) -> (data : felt):
end

@storage_var
func is_settled(token_id : Uint256) -> (data : felt):
end

@external
func set_realm_data{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        tokenId : Uint256, _realm_data : felt):
    # # ONLY OWNER TODO
    realm_data.write(tokenId, _realm_data)
    return ()
end

@view
func get_is_settled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (is_settled : felt):
    let (data) = is_settled.read(token_id)
    return (data)
end

@external
func get_realm_info{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (realm_data : felt):
    let (data) = realm_data.read(token_id)
    return (data)
end

@external
func fetch_realm_data{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(realm_id : Uint256) -> (realm_stats : RealmData):
    alloc_locals

    let (data) = realm_data.read(realm_id)
    # add name
    let (regions) = unpack_data(data, 0, 255)
    let (cities) = unpack_data(data, 8, 255)
    let (harbours) = unpack_data(data, 16, 255)
    let (rivers) = unpack_data(data, 24, 255)
    let (resource_number) = unpack_data(data, 32, 255)
    let (resource_1) = unpack_data(data, 40, 255)
    let (resource_2) = unpack_data(data, 48, 255)
    let (resource_3) = unpack_data(data, 56, 255)
    let (resource_4) = unpack_data(data, 64, 255)
    let (resource_5) = unpack_data(data, 72, 255)
    let (resource_6) = unpack_data(data, 80, 255)
    let (resource_7) = unpack_data(data, 88, 255)
    let (wonder) = unpack_data(data, 96, 255)
    let (order) = unpack_data(data, 104, 255)

    let realm_stats = RealmData(
        regions=regions,
        cities=cities,
        harbours=harbours,
        rivers=rivers,
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
