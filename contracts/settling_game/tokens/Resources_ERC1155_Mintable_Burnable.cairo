# SPDX-License-Identifier: MIT
# OpenZeppelin Contracts for Cairo v0.1.0 (token/erc1155/ERC1155_Mintable_Burnable.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.access.ownable import Ownable

from openzeppelin.upgrades.library import Proxy

from openzeppelin.introspection.ERC165 import ERC165

# move to OZ lib once live
from contracts.token.library import ERC1155

#
# Initializer
#

@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    uri : felt, proxy_admin : felt
):
    ERC1155.initializer(uri)
    Ownable.initializer(proxy_admin)
    Proxy.initializer(proxy_admin)
    return ()
end

@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Ownable.assert_only_owner()
    Proxy._set_implementation_hash(new_implementation)
    return ()
end

#
# Getters
#

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    interfaceId : felt
) -> (success : felt):
    return ERC165.supports_interface(interfaceId)
end

@view
func uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (uri : felt):
    return ERC1155.uri()
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    account : felt, id : Uint256
) -> (balance : Uint256):
    return ERC1155.balance_of(account, id)
end

@view
func balanceOfBatch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    accounts_len : felt, accounts : felt*, ids_len : felt, ids : Uint256*
) -> (balances_len : felt, balances : Uint256*):
    let (balances_len, balances) = ERC1155.balance_of_batch(accounts_len, accounts, ids_len, ids)
    return (balances_len, balances)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    account : felt, operator : felt
) -> (is_approved : felt):
    let (is_approved) = ERC1155.is_approved_for_all(account, operator)
    return (is_approved)
end

#
# Externals
#

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    operator : felt, approved : felt
):
    ERC1155.set_approval_for_all(operator, approved)
    return ()
end

@external
func safeTransferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    from_ : felt, to : felt, id : Uint256, amount : Uint256, data_len : felt, data : felt*
):
    ERC1155.safe_transfer_from(from_, to, id, amount, data_len, data)
    return ()
end

@external
func safeBatchTransferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    from_ : felt,
    to : felt,
    ids_len : felt,
    ids : Uint256*,
    amounts_len : felt,
    amounts : Uint256*,
    data_len : felt,
    data : felt*,
):
    ERC1155.safe_batch_transfer_from(from_, to, ids_len, ids, amounts_len, amounts, data_len, data)
    return ()
end

@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to : felt, id : Uint256, amount : Uint256, data_len : felt, data : felt*
):
    check_can_action()
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    ERC1155._mint(to, id, amount, data_len, data)
    return ()
end

@external
func mintBatch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to : felt,
    ids_len : felt,
    ids : Uint256*,
    amounts_len : felt,
    amounts : Uint256*,
    data_len : felt,
    data : felt*,
):
    check_can_action()
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    ERC1155._mint_batch(to, ids_len, ids, amounts_len, amounts, data_len, data)
    return ()
end

@external
func burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    from_ : felt, id : Uint256, amount : Uint256
):
    ERC1155.assert_owner_or_approved(owner=from_)
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    ERC1155._burn(from_, id, amount)
    return ()
end

@external
func burnBatch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    from_ : felt, ids_len : felt, ids : Uint256*, amounts_len : felt, amounts : Uint256*
):
    # TODO: Module based approach
    # ERC1155.assert_owner_or_approved(owner=from_)
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    ERC1155._burn_batch(from_, ids_len, ids, amounts_len, amounts)
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
    Ownable.assert_only_owner()
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
    let (owner) = Ownable.owner()

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
