# Resources ERC1155 Token
#   Token created for each resource that can be minted, traded, and burned.
#
# MIT License

%lang starknet
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address
from openzeppelin.access.ownable import (
    Ownable_only_owner,
    Ownable_initializer,
    Ownable_owner,
    Ownable_get_owner,
)
from openzeppelin.token.erc1155.library import (
    ERC1155_initializer,
    ERC1155_supportsInterface,
    ERC1155_uri,
    ERC1155_balanceOf,
    ERC1155_balanceOfBatch,
    ERC1155_isApprovedForAll,
    ERC1155_setApprovalForAll,
    ERC1155_safeTransferFrom,
    ERC1155_safeBatchTransferFrom,
    ERC1155_mint,
    ERC1155_mint_batch,
    ERC1155_burn,
    ERC1155_burn_batch,
    owner_or_approved,
)

from openzeppelin.upgrades.library import (
    Proxy_initializer,
    Proxy_only_admin,
    Proxy_set_implementation
)

#
# Constructor
#

@external
func initializer{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        uri: felt,
        owner: felt
    ):
    ERC1155_initializer(uri)
    Ownable_initializer(owner)
    return ()
end

@external
func upgrade{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(new_implementation: felt):
    Ownable_only_owner()
    Proxy_set_implementation(new_implementation)
    return ()
end

#
# Getters
#

@view
func getOwner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (owner: felt):
    return Ownable_get_owner()
end

@view
func supportsInterface(interfaceId : felt) -> (is_supported : felt):
    return ERC1155_supportsInterface(interfaceId)
end

@view
func uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (uri : felt):
    return ERC1155_uri()
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    account : felt, id : Uint256
) -> (balance : Uint256):
    return ERC1155_balanceOf(account, id)
end

@view
func balanceOfBatch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    accounts_len : felt, accounts : felt*, ids_len : felt, ids : Uint256*
) -> (balances_len : felt, balances : Uint256*):
    return ERC1155_balanceOfBatch(accounts_len, accounts, ids_len, ids)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    account : felt, operator : felt
) -> (is_approved : felt):
    return ERC1155_isApprovedForAll(account, operator)
end

#
# Externals
#

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    operator : felt, approved : felt
):
    ERC1155_setApprovalForAll(operator, approved)
    return ()
end

@external
func safeTransferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _from : felt, to : felt, id : Uint256, amount : Uint256
):
    ERC1155_safeTransferFrom(_from, to, id, amount)
    return ()
end

@external
func safeBatchTransferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _from : felt, to : felt, ids_len : felt, ids : Uint256*, amounts_len : felt, amounts : Uint256*
):
    ERC1155_safeBatchTransferFrom(_from, to, ids_len, ids, amounts_len, amounts)
    return ()
end

@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to : felt, id : Uint256, amount : Uint256
):
    # TODO: Restrict
    # Ownable_only_owner()
    check_can_action()
    ERC1155_mint(to, id, amount)
    return ()
end

@external
func mintBatch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to : felt, ids_len : felt, ids : Uint256*, amounts_len : felt, amounts : Uint256*
):
    # TODO: Restrict
    # Ownable_only_owner()
    # check_can_action()
    ERC1155_mint_batch(to, ids_len, ids, amounts_len, amounts)
    return ()
end

@external
func burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _from : felt, id : Uint256, amount : Uint256
):
    # TODO: Restrict
    # owner_or_approved(owner=_from)
    ERC1155_burn(_from, id, amount)
    return ()
end

@external
func burnBatch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _from : felt, ids_len : felt, ids : Uint256*, amounts_len : felt, amounts : Uint256*
):
    # TODO: Restrict
    # owner_or_approved(owner=_from)
    ERC1155_burn_batch(_from, ids_len, ids, amounts_len, amounts)
    return ()
end

#
# Bibliotheca added methods
#

@storage_var
func Module_access() -> (address : felt):
end

@external
func Set_module_access{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    address : felt
):
    Ownable_only_owner()
    Module_access.write(address)
    return ()
end

func check_caller{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    value : felt
):
    let (address) = Module_access.read()
    let (caller) = get_caller_address()

    if address == caller:
        return (1)
    end

    return (0)
end

func check_owner{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    value : felt
):
    let (caller) = get_caller_address()
    let (owner) = Ownable_get_owner()

    if caller == owner:
        return (1)
    end

    return (0)
end

func check_can_action{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (caller) = check_caller()
    let (owner) = check_owner()

    assert_not_zero(owner + caller)
    return ()
end
