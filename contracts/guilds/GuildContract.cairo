# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.cairo_keccak.keccak import keccak_felts
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.cairo.common.memcpy import memcpy

from starkware.starknet.common.syscalls import (
    call_contract, 
    get_caller_address, 
    get_contract_address,
    get_tx_info
)

from contracts.utils.constants import FALSE, TRUE

from openzeppelin.introspection.ERC165 import ERC165
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721
from contracts.guilds.interfaces.IERC1155 import IERC1155
from contracts.guilds.interfaces.IGuildCertificate import IGuildCertificate

from contracts.guilds.lib.role import Role
from contracts.guilds.lib.token_standard import TokenStandard
from contracts.guilds.lib.math_utils import array_sum, array_product

from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_lt,
    uint256_add,
    uint256_eq,
    uint256_sub
)

#
# Structs
#

struct Call:
    member to: felt
    member selector: felt
    member calldata_len: felt
    member calldata: felt*
end

# Tmp struct introduced while we wait for Cairo
# to support passing '[Call]' to __execute__
struct CallArray:
    member to: felt
    member selector: felt
    member data_offset: felt
    member data_len: felt
end

struct Permission:
    member to: felt
    member selector: felt
end

struct Member:
    member account: felt
    member role: felt
end

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
func member_whitelisted(
        account: felt,
        role: felt
    ):
end

@event
func member_removed(
        account: felt
    ):
end

@event
func permissions_set(
        account: felt, 
        permissions_len: felt, 
        permissions: Permission*
    ):
end

@event
func transaction_executed(
        account: felt,
        hash: felt, 
        response_len: felt, 
        response: felt*
    ):
end

@event
func deposited(
        account: felt, 
        certificate_id: Uint256,
        token_standard: felt, 
        token: felt, 
        token_id: Uint256
    ):
end

@event
func withdrawn(
        account: felt, 
        certificate_id: Uint256,
        token_standard: felt,
        token: felt, 
        token_id: Uint256,
        amount: Uint256
    ):
end

#
# Storage variables
#

@storage_var
func _name() -> (res: felt):
end

@storage_var
func _guild_master() -> (res: felt):
end

@storage_var
func _is_permissions_initialized() -> (res: felt):
end

@storage_var
func _whitelisted_members_count() -> (res: felt):
end

@storage_var
func _whitelisted_members(index: felt) -> (res: Member):
end

@storage_var
func _whitelisted_role(account: felt) -> (res: felt):
end

@storage_var
func _is_whitelisted(account: felt) -> (res: felt):
end

@storage_var
func _is_blacklisted(account: felt) -> (res: felt):
end

@storage_var
func _permissions_len() -> (res: felt):
end

@storage_var
func _permissions(index: felt) -> (res: Permission):
end

@storage_var
func _guild_certificate() -> (res: felt):
end

@storage_var
func _current_nonce() -> (res: felt):
end

#
# Guards
#

func require_master{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (caller) = get_caller_address()
    let (master) = _guild_master.read()

    with_attr error_message("Caller is not guild master"):
        assert caller = master
    end
    return ()
end

func require_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (guild_certificate) = _guild_certificate.read()

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate,
        owner=caller_address,
        guild=contract_address
    )

    let (_role) = IGuildCertificate.get_role(contract_address=guild_certificate, certificate_id=certificate_id)

    with_attr error_message("Caller is not owner"):
        assert _role = Role.OWNER
    end
    return ()
end

func require_admin{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (guild_certificate) = _guild_certificate.read()

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate,
        owner=caller_address,
        guild=contract_address
    )

    let (_role) = IGuildCertificate.get_role(
        contract_address=guild_certificate, 
        certificate_id=certificate_id
    )

    with_attr error_message("Caller is not owner"):
        assert _role = Role.ADMIN
    end
    return ()
end

func require_owner_or_member{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (guild_certificate) = _guild_certificate.read()

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate,
        owner=caller_address,
        guild=contract_address
    )

    let (check) = uint256_lt(Uint256(0,0),certificate_id)

    with_attr error_mesage("Caller must have access"):
        assert check = TRUE
    end
    return ()
end

func require_not_whitelisted{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        account: felt
    ):

    let (bool) = _is_whitelisted.read(account)

    with_attr error_mesage("Guild Contract: Account is already whitelisted"):
        assert bool = FALSE
    end

    return ()
end

func require_not_blacklisted{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        account: felt
    ):

    let (is_blacklisted) = _is_blacklisted.read(account)

    with_attr error_message("Guild Contract: Account is blacklisted"):
        assert is_blacklisted = FALSE
    end

    return ()
end

#
# Initialize
#

@external
func initialize{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        master: felt,
        guild_certificate: felt
    ):
    _name.write(name)
    _guild_master.write(master)
    _guild_certificate.write(guild_certificate)

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
    let (name) = _name.read()
    return (name)
end

@view
func master{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (master : felt):
    let (master) = _guild_master.read()
    return (master)
end

@view
func guild_certificate{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (guild_certificate : felt):
    let (guild_certificate) = _guild_certificate.read()
    return (guild_certificate)
end

@view
func is_permissions_initialized{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (initialized) = _is_permissions_initialized.read()
    return (res=initialized)
end

@view
func get_nonce{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res) = _current_nonce.read()
    return (res=res)
end

@view
func get_whitelisted_role{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (res: felt):

    let (role) = _whitelisted_role.read(account)

    return (res=role)
end

@view
func get_whitelisted_members{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (
        members_len: felt,
        members: Member*
    ):
    alloc_locals
    let (members: Member*) = alloc()

    let (members_len) = _whitelisted_members_count.read()

    _get_whitelisted_members(
        members_index=0,
        members_len=members_len,
        members=members
    )

    return (
        members_len=members_len,
        members=members
    )
end

func _get_whitelisted_members{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        members_index: felt,
        members_len: felt,
        members: Member*
    ):
    if members_index == members_len:
        return ()
    end

    let (whitelisted_member) = _whitelisted_members.read(members_index)

    assert members[members_index] = whitelisted_member

    _get_whitelisted_members(
        members_index=members_index + 1,
        members_len=members_len,
        members=members
    )
    return ()
end

@view
func get_permissions{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (
        permissions_len: felt,
        permissions: Permission*
    ):
    alloc_locals
    let (permissions: Permission*) = alloc()

    let (permissions_len) = _permissions_len.read()

    _get_permissions(
        permissions_index=0,
        permissions_len=permissions_len,
        permissions=permissions
    )

    return (
        permissions_len=permissions_len,
        permissions=permissions
    )
end

func _get_permissions{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        permissions_index: felt,
        permissions_len: felt,
        permissions: Permission*
    ):
    if permissions_index == permissions_len:
        return ()
    end

    let (permission) = _permissions.read(permissions_index)

    assert permissions[permissions_index] = permission

    _get_permissions(
        permissions_index=permissions_index + 1,
        permissions_len=permissions_len,
        permissions=permissions
    )
    return ()
end

#
# Externals
#

@external
func whitelist_member{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        memb: Member
    ):

    require_master()

    require_not_whitelisted(memb.account)

    let account = memb.account
    let role = memb.role

    _is_whitelisted.write(account, TRUE)
    _whitelisted_role.write(account, role)

    let (count) = _whitelisted_members_count.read()

    _whitelisted_members.write(count, memb)

    _whitelisted_members_count.write(count+1)

    member_whitelisted.emit(
        account=memb.account,
        role=memb.role
    )
    
    return ()
end

@external
func join{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    let (guild_certificate) = _guild_certificate.read()
    let (contract_address) = get_contract_address()
    let (caller_address) = get_caller_address()

    let (whitelisted_role) = _whitelisted_role.read(caller_address)
    with_attr error_mesage("Caller is not whitelisted"):
       assert_lt(0, whitelisted_role)
    end

    require_not_blacklisted(caller_address)

    IGuildCertificate.mint(
        contract_address=guild_certificate,
        to=caller_address, 
        guild=contract_address,
        role=whitelisted_role
    )

    return ()
end

@external
func leave{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    let (guild_certificate) = _guild_certificate.read()
    let (contract_address) = get_contract_address()
    let (caller_address) = get_caller_address()

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate,
        owner=caller_address,
        guild=contract_address
    )

    let (check) = IGuildCertificate.check_tokens_exist(
        contract_address=guild_certificate,
        certificate_id=certificate_id
    )

    with_attr error_message(
            "Guild Contract: Cannot leave, account has items in guild"
        ):
            assert check = FALSE
    end

    IGuildCertificate.guild_burn(
        contract_address=guild_certificate,
        account=caller_address,
        guild=contract_address
    )

    return ()
end

@external
func remove_member{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        account: felt
    ):
    alloc_locals

    require_admin()

    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    let (guild_certificate) = _guild_certificate.read()

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate,
        owner=account,
        guild=contract_address
    )

    let (check) = IGuildCertificate.check_tokens_exist(
        contract_address=guild_certificate,
        certificate_id=certificate_id
    )
    # tempvar guild_certificate = guild_certificate

    if check == TRUE:
        force_transfer_items(certificate_id, account)
        IGuildCertificate.guild_burn(
            contract_address=guild_certificate,
            account=account,
            guild=contract_address
        )
        _is_blacklisted.write(account, TRUE)
        tempvar syscall_ptr: felt* = syscall_ptr
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        IGuildCertificate.guild_burn(
            contract_address=guild_certificate,
            account=account,
            guild=contract_address
        )
        _is_blacklisted.write(account, TRUE)
        tempvar syscall_ptr: felt* = syscall_ptr
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    member_removed.emit(
        account=account
    )
    return ()
end

@external
func update_role{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(address: felt, new_role: felt):
    let (contract_address) = get_contract_address()
    let (guild_certificate) = _guild_certificate.read()

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate,
        owner=address,
        guild=contract_address
    )

    IGuildCertificate.update_role(
        contract_address=guild_certificate,
        certificate_id=certificate_id,
        role=new_role
    )

    return ()
end

@external
func deposit{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token_standard: felt,
        token: felt,
        token_id: Uint256,
        amount: Uint256
    ):
    alloc_locals

    local syscall_ptr: felt* = syscall_ptr
    local pedersen_ptr: HashBuiltin* = pedersen_ptr
    local range_check_ptr = range_check_ptr

    require_owner()

    let (check_not_zero) = uint256_lt(Uint256(0,0), amount)

    with_attr error_message("Guild Contract: Amount cannot be 0"):
        assert check_not_zero = TRUE
    end

    if token_standard == TokenStandard.ERC721:
        let (check_one) = uint256_eq(amount, Uint256(1,0))
        with_attr error_message("Guild Contract: ERC721 amount must be 1"):
            assert check_one = TRUE
        end
        tempvar syscall_ptr: felt* = syscall_ptr
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr: felt* = syscall_ptr
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    let (guild_certificate) = _guild_certificate.read()
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate,
        owner=caller_address,
        guild=contract_address
    )

    let (check_exists) = IGuildCertificate.check_token_exists(
        contract_address=guild_certificate,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id
    )

    if token_standard == TokenStandard.ERC721:
        with_attr error_message(
            "Guild Contract: Caller certificate already holds ERC721 token"
        ):
            assert check_exists = FALSE
        end
        IERC721.transferFrom(
            contract_address=token, 
            from_=caller_address,
            to=contract_address,
            tokenId=token_id
        )
        IGuildCertificate.add_token_data(
            contract_address=guild_certificate,
            certificate_id=certificate_id,
            token_standard=token_standard,
            token=token,
            token_id=token_id,
            amount=amount
        )
        tempvar syscall_ptr: felt* = syscall_ptr
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr: felt* = syscall_ptr
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    let (initial_amount) = IGuildCertificate.get_token_amount(
        contract_address=guild_certificate,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id
    )

    let (new_amount, _) = uint256_add(initial_amount, amount)

    if token_standard == TokenStandard.ERC1155:
        IERC1155.transferFrom(
            contract_address=token, 
            from_=caller_address,
            to=contract_address,
            tokenId=token_id,
            amount=amount
        )
        tempvar syscall_ptr: felt* = syscall_ptr
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
        if check_exists == TRUE:
            IGuildCertificate.change_token_data(
                contract_address=guild_certificate,
                certificate_id=certificate_id,
                token_standard=token_standard,
                token=token,
                token_id=token_id,
                new_amount=new_amount
            )
            tempvar syscall_ptr: felt* = syscall_ptr
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            IGuildCertificate.add_token_data(
                contract_address=guild_certificate,
                certificate_id=certificate_id,
                token_standard=token_standard,
                token=token,
                token_id=token_id,
                amount=amount
            )
            tempvar syscall_ptr: felt* = syscall_ptr
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end
    else:
        tempvar syscall_ptr: felt* = syscall_ptr
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    deposited.emit(
        account=caller_address,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id
    )
    return ()
end

@external
func withdraw{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token_standard: felt,
        token: felt,
        token_id: Uint256,
        amount: Uint256
    ):
    alloc_locals

    local syscall_ptr: felt* = syscall_ptr
    local pedersen_ptr: HashBuiltin* = pedersen_ptr
    local range_check_ptr = range_check_ptr

    require_owner()

    if token_standard == TokenStandard.ERC721:
        let (check_one) = uint256_eq(amount, Uint256(1,0))
        with_attr error_message("Guild Contract: ERC721 amount must be 1"):
            assert check_one = TRUE
        end
    end

    let (guild_certificate) = _guild_certificate.read()
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate,
        owner=caller_address,
        guild=contract_address
    )

    let (check_exists) = IGuildCertificate.check_token_exists(
        contract_address=guild_certificate,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id
    )

    with_attr error_message("Caller certificate doesn't hold tokens"):
        assert check_exists = TRUE
    end

    if token_standard == TokenStandard.ERC721:
        IERC721.transferFrom(
            contract_address=token, 
            from_=contract_address,
            to=caller_address,
            tokenId=token_id
        )
        IGuildCertificate.change_token_data(
            contract_address=guild_certificate,
            certificate_id=certificate_id,
            token_standard=token_standard,
            token=token,
            token_id=token_id,
            new_amount=Uint256(0,0)
        )
        tempvar syscall_ptr: felt* = syscall_ptr
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr: felt* = syscall_ptr
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    let (initial_amount) = IGuildCertificate.get_token_amount(
        contract_address=guild_certificate,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id
    )

    let (new_amount) = uint256_sub(initial_amount, amount)

    if token_standard == TokenStandard.ERC1155:
        IERC1155.transferFrom(
            contract_address=token, 
            from_=contract_address,
            to=caller_address,
            tokenId=token_id,
            amount=amount
        )
        IGuildCertificate.change_token_data(
            contract_address=guild_certificate,
            certificate_id=certificate_id,
            token_standard=token_standard,
            token=token,
            token_id=token_id,
            new_amount=new_amount
        )
        tempvar syscall_ptr: felt* = syscall_ptr
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr: felt* = syscall_ptr
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    withdrawn.emit(
        account=caller_address,
        certificate_id=certificate_id,
        token_standard=token_standard,
        token=token,
        token_id=token_id,
        amount=amount
    )

    return ()
end

@external
func execute_transactions{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        call_array_len: felt,
        call_array: CallArray*,
        calldata_len: felt,
        calldata: felt*,
        nonce: felt
    ) -> (
        retdata_len: felt,
        retdata: felt*
    ):
    alloc_locals
    require_owner_or_member()
    let (caller) = get_caller_address()

    let (calls : Call*) = alloc()

    from_call_array_to_call(call_array_len, call_array, calldata, calls)

    let calls_len = call_array_len

    let (current_nonce) = _current_nonce.read()
    assert current_nonce = nonce
    _current_nonce.write(value=current_nonce + 1)

    let (tx_info) = get_tx_info()

    let (response : felt*) = alloc()

   let (response_len) = execute_list(
        calls_len,
        calls,
        response
    )
    # emit event
    transaction_executed.emit(
        account=caller,
        hash=tx_info.transaction_hash, 
        response_len=response_len, 
        response=response
    )
    return (retdata_len=response_len, retdata=response)
end

func execute_list{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        calls_len: felt,
        calls: Call*,
        response: felt*
    ) -> (
        response_len: felt
    ):
    alloc_locals

    # if no more calls
    if calls_len == 0:
        return (0)
    end

    let this_call: Call = [calls]

    # Check the tranasction is permitted
    check_permitted_call(
        this_call.to, 
        this_call.selector
    )

    # Actually execute it
    let res = call_contract(
        contract_address=this_call.to,
        function_selector=this_call.selector,
        calldata_size=this_call.calldata_len,
        calldata=this_call.calldata,
    )

    # copy the result in response
    memcpy(response, res.retdata, res.retdata_size)
    # do the next calls recursively
    let (response_len) = execute_list(calls_len - 1, calls + Call.SIZE, response + res.retdata_size)
    return (response_len + res.retdata_size)
end

@external
func initialize_permissions{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        permissions_len: felt,
        permissions: Permission*
    ):
    require_master()

    let (check_initialized) = _is_permissions_initialized.read()

    with_attr error_message("Guild: Permissions already initialized"):
        assert check_initialized = FALSE
    end

    set_permissions(
        permissions_len=permissions_len,
        permissions=permissions
    )

    _is_permissions_initialized.write(TRUE)

    return ()
end

@external
func set_permissions{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        permissions_len: felt,
        permissions: Permission*
    ):
    alloc_locals

    local syscall_ptr: felt* = syscall_ptr
    local pedersen_ptr: HashBuiltin* = pedersen_ptr
    local range_check_ptr = range_check_ptr

    _set_permissions(
        permissions_index=0,
        permissions_len=permissions_len,
        permissions=permissions
    )

    let (caller) = get_caller_address()

    permissions_set.emit(
        account=caller, 
        permissions_len=permissions_len, 
        permissions=permissions
    )
    return ()
end

func _set_permissions{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        permissions_index: felt,
        permissions_len: felt,
        permissions: Permission*
    ):
    if permissions_index == permissions_len:
        return ()
    end

    let (permissions_count) = _permissions_len.read()

    _permissions.write(permissions_index, permissions[permissions_index])

    _permissions_len.write(permissions_count + 1)

    _set_permissions(
        permissions_index=permissions_index + 1,
        permissions_len=permissions_len,
        permissions=permissions
    )
    return ()
end

func check_permitted_call{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(        
        to: felt,
        selector: felt
    ):
    alloc_locals
    let (permissions_len) = _permissions_len.read()
    let (check_calls) = alloc()
    _check_permitted_call(
        permissions_index=0, 
        permissions_len=permissions_len,
        to=to,
        selector=selector,
        check_calls=check_calls
    )
    let (check_calls_product) = array_product(
        arr_len=permissions_len,
        arr=check_calls
    )
    with_attr error_mesage("Contract is not permitted"):
        assert check_calls_product = 0
    end
    return ()
end

func _check_permitted_call{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(
        permissions_index: felt,
        permissions_len: felt,
        to: felt,
        selector: felt,
        check_calls: felt*
    ):
    if permissions_index == permissions_len:
        return ()
    end

    let (permission) = _permissions.read(permissions_index)
    let check_to = permission.to - to
    let check_selector = permission.selector - selector

    assert check_calls[permissions_index] = check_to + check_selector

    _check_permitted_call(
        permissions_index=permissions_index + 1,
        permissions_len=permissions_len,
        to=to,
        selector=selector,
        check_calls=check_calls
    )
    return ()
end

# Added for future intrgration with plugins
@external
func delegate_validate{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        plugin_data_len: felt,
        plugin_data: felt*,
        call_array_len: felt,
        call_array: CallArray*,
        calldata_len: felt,
        calldata: felt
    ):
    return ()
end

func from_call_array_to_call{syscall_ptr: felt*}(
        call_array_len: felt,
        call_array: CallArray*,
        calldata: felt*,
        calls: Call*
    ):
    # if no more calls
    if call_array_len == 0:
       return ()
    end
    
    # parse the current call
    assert [calls] = Call(
            to=[call_array].to,
            selector=[call_array].selector,
            calldata_len=[call_array].data_len,
            calldata=calldata + [call_array].data_offset
        )
    
    # parse the remaining calls recursively
    from_call_array_to_call(call_array_len - 1, call_array + CallArray.SIZE, calldata, calls + Call.SIZE)
    return ()
end

func force_transfer_items{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(certificate_id: Uint256, account: felt):
    let (guild_certificate) = _guild_certificate.read()

    let (tokens_len, tokens: Token*) = IGuildCertificate.get_tokens(
        contract_address=guild_certificate,
        certificate_id=certificate_id
    )

    _force_transfer_items(
        tokens_index=0,
        tokens_len=tokens_len,
        tokens=tokens,
        account=account
    )

    return()
end

func _force_transfer_items{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        tokens_index: felt,
        tokens_len: felt,
        tokens: Token*,
        account: felt
    ):
    if tokens_index == tokens_len:
        return ()
    end

    let token = tokens[tokens_index]

    let (check_amount) = uint256_lt(Uint256(0,0), token.amount)

    let (contract_address) = get_contract_address()
    let (guild_certificate) = _guild_certificate.read()

    let (certificate_id: Uint256) = IGuildCertificate.get_certificate_id(
        contract_address=guild_certificate,
        owner=account,
        guild=contract_address
    )

    if check_amount == TRUE:
        if token.token_standard == TokenStandard.ERC721:
            IERC721.transferFrom(
                contract_address=token.token, 
                from_=contract_address,
                to=account,
                tokenId=token.token_id
            )
            IGuildCertificate.change_token_data(
                contract_address=guild_certificate,
                certificate_id=certificate_id,
                token_standard=token.token_standard,
                token=token.token,
                token_id=token.token_id,
                new_amount=Uint256(0,0)
            )
            tempvar contract_address = contract_address
            tempvar guild_certificate = guild_certificate
            tempvar certificate_id: Uint256 = certificate_id
            tempvar syscall_ptr: felt* = syscall_ptr
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar contract_address = contract_address
            tempvar guild_certificate = guild_certificate
            tempvar certificate_id: Uint256 = certificate_id
            tempvar syscall_ptr: felt* = syscall_ptr
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end

        if token.token_standard == TokenStandard.ERC1155:
            IERC1155.transferFrom(
                contract_address=token.token, 
                from_=contract_address,
                to=account,
                tokenId=token.token_id,
                amount=token.amount
            )
            IGuildCertificate.change_token_data(
                contract_address=guild_certificate,
                certificate_id=certificate_id,
                token_standard=token.token_standard,
                token=token.token,
                token_id=token.token_id,
                new_amount=Uint256(0,0)
            )
            tempvar syscall_ptr: felt* = syscall_ptr
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar syscall_ptr: felt* = syscall_ptr
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end
    else:
        tempvar syscall_ptr: felt* = syscall_ptr
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    _force_transfer_items(
        tokens_index=tokens_index + 1,
        tokens_len=tokens_len,
        tokens=tokens,
        account=account
    )

    return ()
end
