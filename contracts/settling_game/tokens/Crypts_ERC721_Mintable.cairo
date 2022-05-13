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

from contracts.settling_game.utils.game_structs import CryptData
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
func crypt_name(token_id : Uint256) -> (name : felt):
end

@storage_var
func crypt_data(token_id : Uint256) -> (data : felt):
end

@storage_var
func is_unlocked(token_id : Uint256) -> (data : felt):
end

@external
func set_crypt_data{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        tokenId : Uint256, _crypt_data : felt):
        ## ONLY OWNER TODO
    crypt_data.write(tokenId, _crypt_data)
    return ()
end

@view
func get_is_unlocked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (is_unlocked : felt):
    let (data) = is_unlocked.read(token_id)
    return (data)
end

@external
func get_crypts_info{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (crypts_data : felt):
    let (data) = crypt_data.read(token_id)
    return (data)
end

@external
func fetch_crypt_data{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(crypt_id : Uint256) -> (crypt_stats : CryptData):
    alloc_locals

    let (data) = crypt_data.read(crypt_id)

    ## TODO: Update with bitmap for Crypts data
    let (environment) = unpack_data(data, 0, 255)   # [0-3] uint256 - environment of the dungeon (0-6)
    let (legendary) = unpack_data(data, 4, 255)     # [4] uint256 - flag if dungeon is legendary (0/1)
    let (size) = unpack_data(data, 9, 255)          # [9-13] uint256 - size (e.g. 6x6) of dungeon. (6-25)
    let (num_doors) = unpack_data(data, 14, 255)    # [14-17] uint256 - number of doors (0-12)
    let (num_points) = unpack_data(data, 18, 255)   # [18-21] uint256 - number of points (0-12)
    let (name) = unpack_data(data, 22, 255)         # [22-254] string - name of the dungeon (TBD if we can do this). We might want to bring over milan's name/seed generator

    let crypt_stats = CryptData(
        environment = environment,
        legendary = legendary,
        size = size,
        num_doors = num_doors,
        num_points = num_points,
        name = name)
    return (crypt_stats=crypt_stats)
end