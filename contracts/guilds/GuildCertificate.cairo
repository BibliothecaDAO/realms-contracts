# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.starknet.common.syscalls import call_contract, get_caller_address
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    uint256_lt,
    uint256_eq
)

from contracts.utils.constants import FALSE, TRUE
from contracts.interfaces.IGuildManager import IGuildManager

from openzeppelin.token.erc721.library import ERC721
from openzeppelin.introspection.ERC165 import ERC165

from openzeppelin.access.ownable import Ownable

from contracts.lib.math_utils import uint256_array_sum, array_product
from contracts.utils.helpers import find_value, find_uint256_value

#
# Structs
#

struct Token:
    member token_standard: felt
    member token: felt
    member token_id: Uint256
    member amount: Uint256
end

#
# Events
#

@event
func mint_certificate(account: felt, guild: felt, id: Uint256):
end

@event
func burn_certificate(account: felt, guild: felt, id: Uint256):
end

#
# Storage variables
#

@storage_var
func _guild_manager() -> (res : felt):
end

@storage_var
func _certificate_id_count() -> (res : Uint256):
end

@storage_var
func _certificate_id(owner : felt, guild : felt) -> (res : Uint256):
end

@storage_var
func _role(certificate_id: Uint256) -> (res: felt):
end

@storage_var
func _guild(certificate_id: Uint256) -> (res: felt):
end

@storage_var
func _certificate_token_amount(
        certificate_id: Uint256, 
        token_standard: felt, 
        token: felt, 
        token_id: Uint256
    ) -> (res: Uint256):
end

@storage_var
func _certificate_tokens_data_len(certificate_id: Uint256) -> (res: felt):
end

@storage_var
func _certificate_tokens_data(certificate_id: Uint256, index: felt) -> (res: Token):
end

#
# Guards
#

func assert_only_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    let (caller) = get_caller_address()
    let (guild_manager) = _guild_manager.read()
    let (check_guild) = IGuildManager.check_valid_contract(guild_manager, caller)
    let check_manager = guild_manager - caller
    let check_product = check_guild * check_manager
    with_attr error_message("Guild Manager: Contract is not valid"):
        assert check_product = 0
    end
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
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC721.name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC721.symbol()
    return (symbol)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC721.balance_of(owner)
    return (balance)
end

@view
func ownerOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (owner: felt):
    let (owner: felt) = ERC721.owner_of(tokenId)
    return (owner)
end

@view
func tokenURI{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (tokenURI: felt):
    let (tokenURI: felt) = ERC721.token_uri(tokenId)
    return (tokenURI)
end

@view
func get_certificate_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner : felt, guild : felt) -> (certificate_id : Uint256):
   let (value) =  _certificate_id.read(owner, guild)
   return (value)
end

@view
func get_role{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(certificate_id: Uint256) -> (role: felt):
    let (value) = _role.read(certificate_id)
    return (value)
end

@view 
func get_guild{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(certificate_id : Uint256) -> (guild : felt):
    let (guild) = _guild.read(certificate_id)
    return (guild)
end

@view
func get_tokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(certificate_id: Uint256) -> (
        tokens_len: felt,
        tokens: Token*
    ):
    alloc_locals
    let (tokens: Token*) = alloc()

    let (tokens_len) = _certificate_tokens_data_len.read(certificate_id)

    _get_tokens(
        tokens_index=0,
        tokens_len=tokens_len,
        tokens=tokens,
        certificate_id=certificate_id
    )
    
    return (tokens_len=tokens_len, tokens=tokens)
end

@view
func get_token_amount{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        certificate_id: Uint256, 
        token_standard: felt, 
        token: felt, 
        token_id: Uint256
    ) -> (amount: Uint256):
    let (amount) = _certificate_token_amount.read(
        certificate_id,
        token_standard,
        token,
        token_id
    )
    return (amount)
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
        guild_manager: felt
    ):
    ERC721.initializer(name, symbol)
    _guild_manager.write(guild_manager)
    
    return ()
end

#
# External
#

@external
func setTokenURI{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256, tokenURI: felt):
    assert_only_owner()
    ERC721._set_token_uri(tokenId, tokenURI)
    return ()
end

@external
func transfer_ownership{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(new_owner: felt):
    Ownable.transfer_ownership(new_owner)
    return ()
end

@external
func mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, guild: felt, role: felt):
    assert_only_owner()

    let (certificate_count) = _certificate_id_count.read()
    let (new_certificate_id, _) = uint256_add(certificate_count, Uint256(1,0))
    _certificate_id_count.write(new_certificate_id)

    _certificate_id.write(to, guild, new_certificate_id)
    _role.write(new_certificate_id, role)
    _guild.write(new_certificate_id, guild)

    ERC721._mint(to, new_certificate_id)

    mint_certificate.emit(to, guild, new_certificate_id)

    return ()
end

@external
func update_role{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(certificate_id: Uint256, role: felt):
    assert_only_owner()

    _role.write(certificate_id, role)
    return()
end


@external
func burn{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(account: felt, guild: felt):
    alloc_locals
    let (certificate_id: Uint256) = _certificate_id.read(account, guild)
    ERC721.assert_only_token_owner(certificate_id)
    ERC721._burn(certificate_id)
    burn_certificate.emit(account, guild, certificate_id)
    return ()
end

@external
func guild_burn{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(account: felt, guild: felt):
    alloc_locals
    assert_only_owner()
    let (certificate_id: Uint256) = _certificate_id.read(account, guild)
    ERC721._burn(certificate_id)
    burn_certificate.emit(account, guild, certificate_id)
    return ()
end

@external
func add_token_data{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        certificate_id: Uint256,
        token_standard: felt,
        token: felt,
        token_id: Uint256,
        amount: Uint256
    ):
    assert_only_owner()

    _certificate_token_amount.write(
        certificate_id, 
        token_standard, 
        token, 
        token_id, 
        amount
    )

    let (tokens_len) = _certificate_tokens_data_len.read(certificate_id)

    let data = Token(
        token_standard,
        token,
        token_id,
        amount
    )
    _certificate_tokens_data.write(certificate_id, tokens_len, data)

    _certificate_tokens_data_len.write(certificate_id, tokens_len + 1)

    return ()
end

@external
func change_token_data{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        certificate_id: Uint256,
        token_standard: felt,
        token: felt,
        token_id: Uint256,
        new_amount: Uint256
    ):
    assert_only_owner()

    _certificate_token_amount.write(
        certificate_id, 
        token_standard,
        token, 
        token_id, 
        new_amount
    )

    let (tokens_data_len) = _certificate_tokens_data_len.read(certificate_id)

    let (tokens_data_index) = get_tokens_data_index(
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id
    )

    let data = Token(
        token_standard,
        token,
        token_id,
        new_amount
    )

    _certificate_tokens_data.write(certificate_id, tokens_data_index, data)

    return ()
end

@view
func check_token_exists{        
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        certificate_id: Uint256,
        token_standard: felt,
        token: felt,
        token_id: Uint256
    ) -> (
        bool: felt
    ):
    alloc_locals
    assert_only_owner()
    let (amount) = _certificate_token_amount.read(
        certificate_id,
        token_standard,
        token, 
        token_id
    )
    let (check_amount) = uint256_lt(Uint256(0,0),amount)
    return(check_amount)
end

@view
func check_tokens_exist{        
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        certificate_id: Uint256
    ) -> (bool: felt):
    alloc_locals
    assert_only_owner()
    let (checks: Uint256*) = alloc()

    let (tokens_data_len) = _certificate_tokens_data_len.read(certificate_id)

    _check_tokens_exist(
        tokens_data_index=0,
        tokens_data_len=tokens_data_len,
        certificate_id=certificate_id,
        checks=checks
    )

    let (sum) = uint256_array_sum(tokens_data_len, checks)

    let (bool) = uint256_lt(Uint256(0,0),sum)

    return (bool)
end

func _get_tokens{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tokens_index: felt,
        tokens_len: felt,
        tokens: Token*,
        certificate_id: Uint256
    ):
    if tokens_index == tokens_len:
        return ()
    end

    let (token) = _certificate_tokens_data.read(certificate_id, tokens_index)

    assert tokens[tokens_index] = token

    _get_tokens(
        tokens_index=tokens_index + 1,
        tokens_len=tokens_len,
        tokens=tokens,
        certificate_id=certificate_id
    )

    return ()
end

func _check_tokens_exist{        
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        tokens_data_index: felt,
        tokens_data_len: felt,
        certificate_id: Uint256,
        checks: Uint256*
    ):

    let (token_data) = _certificate_tokens_data.read(
        certificate_id,
        tokens_data_index
    )

    let amount = token_data.amount

    assert checks[tokens_data_index] = amount

    return ()
end


func get_tokens_data_index{        
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        certificate_id: Uint256,
        token_standard: felt,
        token: felt,
        token_id: Uint256
    ) -> (index: felt):
    alloc_locals
    let (checks: felt*) = alloc()
    let (tokens_data_len) = _certificate_tokens_data_len.read(certificate_id)

    _get_tokens_data_index(
        tokens_data_index=0,
        tokens_data_len=tokens_data_len,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id,
        checks=checks
    )

    # let (index) = find_uint256_value(
    #     arr_index=0,
    #     arr_len=tokens_data_len,
    #     arr=checks,
    #     value=Uint256(0,0)
    # )

    let (index) = find_value(
        arr_index=0,
        arr_len=tokens_data_len,
        arr=checks,
        value=0
    )

    return (index=index)
end

func _get_tokens_data_index{        
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        tokens_data_index: felt,
        tokens_data_len: felt,
        certificate_id: Uint256,
        token_standard: felt,
        token: felt,
        token_id: Uint256,
        checks: felt*
    ):
    if tokens_data_index == tokens_data_len:
        return ()
    end

    let (token_data) = _certificate_tokens_data.read(
        certificate_id,
        tokens_data_index
    )

    let check_token_standard = token_data.token_standard - token_standard
    let check_token = token_data.token - token
    let (check_token_id) = uint256_sub(token_data.token_id, token_id)

    let add_1 = check_token_standard + check_token
    let check_token_data = add_1 + check_token_id.low
    # let (check_token_data, _) = uint256_add(Uint256(add_1,0), check_token_id)

    assert checks[tokens_data_index] = check_token_data

    _get_tokens_data_index(
        tokens_data_index=tokens_data_index + 1,
        tokens_data_len=tokens_data_len,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id,
        checks=checks
    )

    return ()
end