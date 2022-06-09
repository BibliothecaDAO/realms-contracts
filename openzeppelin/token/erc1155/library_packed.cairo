%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal, assert_lt_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_check)
from starkware.cairo.common.math import split_felt
from openzeppelin.introspection.IERC165 import IERC165
from openzeppelin.token.erc1155.interfaces.IERC1155_Receiver import IERC1155_Receiver

const IERC1155_interface_id = 0xd9b67a26
const IERC1155_MetadataURI_interface_id = 0x0e89341c
const IERC165_interface_id = 0x01ffc9a7

const IERC1155_RECEIVER_ID = 0x4e2312e0
const ON_ERC1155_RECEIVED_SELECTOR = 0xf23a6e61
const ON_BATCH_ERC1155_RECEIVED_SELECTOR = 0xbc197c81
const IACCOUNT_ID = 0xf10dbd44

#
# Events
#

@event
func TransferSingle(operator : felt, from_ : felt, to : felt, id : Uint256, value : Uint256):
end

@event
func TransferBatch(
        operator : felt, from_ : felt, to : felt, ids_len : felt, ids : Uint256*, values_len : felt,
        values : Uint256*):
end

@event
func ApprovalForAll(account : felt, operator : felt, approved : felt):
end

@event
func URI(value_len : felt, value : felt*, id : Uint256):
end

#
# Storage
#

@storage_var
func ERC1155_balances_(id : Uint256, account : felt) -> (balance : felt):
end

@storage_var
func ERC1155_operator_approvals_(account : felt, operator : felt) -> (approved : felt):
end

# TODO: decide URI format
@storage_var
func ERC1155_uri_() -> (uri : felt):
end

#
# Constructor
#

func ERC1155_initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        uri_ : felt):
    _setURI(uri_)
    return ()
end

#
# Getters
#

func ERC1155_supportsInterface(interface_id : felt) -> (res : felt):
    # Less expensive (presumably) than storage
    if interface_id == IERC1155_interface_id:
        return (1)
    end
    if interface_id == IERC1155_MetadataURI_interface_id:
        return (1)
    end
    if interface_id == IERC165_interface_id:
        return (1)
    end
    return (0)
end

func ERC1155_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        uri : felt):
    let (uri) = ERC1155_uri_.read()
    return (uri)
end

func ERC1155_balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        account : felt, id : Uint256) -> (balance : Uint256):
    with_attr error_message("ERC1155: balance query for the zero address"):
        assert_not_zero(account)
    end
    let (balance) = ERC1155_balances_.read(id=id, account=account)
    let (balance_felt) = _felt_to_uint(balance)
    return (balance_felt)
end

func ERC1155_balanceOfBatch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        accounts_len : felt, accounts : felt*, ids_len : felt, ids : Uint256*) -> (
        batch_balances_len : felt, batch_balances : Uint256*):
    alloc_locals
    # Check args are equal length arrays
    with_attr error_message("ERC1155: accounts and ids length mismatch"):
        assert ids_len = accounts_len
    end
    # Allocate memory
    let (local batch_balances : Uint256*) = alloc()
    let len = accounts_len
    # Call iterator
    balance_of_batch_iter(len, accounts, ids, batch_balances)
    return (batch_balances_len=len, batch_balances=batch_balances)
end

func ERC1155_isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        account : felt, operator : felt) -> (approved : felt):
    let (approved) = ERC1155_operator_approvals_.read(account=account, operator=operator)
    return (approved)
end

#
# Externals
#

func ERC1155_setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt, approved : felt):
    let (caller) = get_caller_address()
    # Non-zero caller asserted in called function
    _set_approval_for_all(owner=caller, operator=operator, approved=approved)
    return ()
end

func ERC1155_safeTransferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_ : felt, to : felt, id : Uint256, amount : Uint256):
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    with_attr error_message("ERC1155: caller is not owner nor approved"):
        owner_or_approved(from_)
    end
    _safe_transfer_from(from_, to, id, amount)
    return ()
end

func ERC1155_safeBatchTransferFrom{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_ : felt, to : felt, ids_len : felt, ids : Uint256*, amounts_len : felt,
        amounts : Uint256*):
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    with_attr error_message("ERC1155: transfer caller is not owner nor approved"):
        owner_or_approved(from_)
    end
    return _safe_batch_transfer_from(from_, to, ids_len, ids, amounts_len, amounts)
end

#
# Internals
#

func _safe_transfer_from{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_ : felt, to : felt, id : Uint256, amount : Uint256):
    alloc_locals
    # Check args
    with_attr error_message("ERC1155: transfer to the zero address"):
        assert_not_zero(to)
    end
    with_attr error_message("ERC1155: invalid uint in calldata"):
        uint256_check(id)
        uint256_check(amount)
    end
    # Todo: beforeTokenTransfer

    # Check balance sufficient
    let (local from_balance) = ERC1155_balances_.read(id=id, account=from_)
    let (balance_uint) = _felt_to_uint(from_balance)
    let (sufficient_balance) = uint256_le(amount, balance_uint)
    with_attr error_message("ERC1155: insufficient balance for transfer"):
        assert_not_zero(sufficient_balance)
    end
    # Deduct from sender
    let (new_balance : Uint256) = uint256_sub(balance_uint, amount)

    let (new_balance_uint) = _uint_to_felt(new_balance)
    ERC1155_balances_.write(id=id, account=from_, value=new_balance_uint)

    # Add to reciever
    let (to_balance) = ERC1155_balances_.read(id=id, account=to)
    let (to_balance_uint) = _felt_to_uint(from_balance)
    let (new_balance : Uint256, carry) = uint256_add(to_balance_uint, amount)
    let (new_balance_uint) = _uint_to_felt(new_balance)
    with_attr error_message("arithmetic overflow"):
        assert carry = 0
    end
    ERC1155_balances_.write(id=id, account=to, value=new_balance_uint)

    let (operator) = get_caller_address()

    TransferSingle.emit(operator, from_, to, id, amount)

    _do_safe_transfer_acceptance_check(operator, from_, to, id, amount)

    return ()
end

func _safe_batch_transfer_from{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_ : felt, to : felt, ids_len : felt, ids : Uint256*, amounts_len : felt,
        amounts : Uint256*):
    alloc_locals
    with_attr error_message("ERC1155: ids and amounts length mismatch"):
        assert_not_zero(to)
    end
    # Check args are equal length arrays
    with_attr error_message("ERC1155: transfer to the zero address"):
        assert ids_len = amounts_len
    end
    # Recursive call
    let len = ids_len
    safe_batch_transfer_from_iter(from_, to, len, ids, amounts)
    let (operator) = get_caller_address()
    TransferBatch.emit(operator, from_, to, ids_len, ids, amounts_len, amounts)
    _do_safe_batch_transfer_acceptance_check(
        operator, from_, to, ids_len, ids, amounts_len, amounts)
    return ()
end

func ERC1155_mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, id : Uint256, amount : Uint256):
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    # Cannot mint to zero address
    with_attr error_message("ERC1155: mint to the zero address"):
        assert_not_zero(to)
    end
    # Check uints valid
    with_attr error_message("ERC1155: invalid uint256 in calldata"):
        uint256_check(id)
        uint256_check(amount)
    end
    # beforeTokenTransfer
    # add to minter check for overflow
    let (to_balance) = ERC1155_balances_.read(id=id, account=to)
    let (to_balance_uint) = _felt_to_uint(to_balance)
    let (new_balance : Uint256, carry) = uint256_add(to_balance_uint, amount)
    with_attr error_message("ERC1155: arithmetic overflow"):
        assert carry = 0
    end
    let (new_balance_uint) = _uint_to_felt(new_balance)
    ERC1155_balances_.write(id=id, account=to, value=new_balance_uint)
    # doSafeTransferAcceptanceCheck
    let (operator) = get_caller_address()
    TransferSingle.emit(operator=operator, from_=0, to=to, id=id, value=amount)
    _do_safe_transfer_acceptance_check(operator, 0, to, id, amount)

    return ()
end

func ERC1155_mint_batch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, ids_len : felt, ids : Uint256*, amounts_len : felt, amounts : Uint256*):
    alloc_locals
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    # Cannot mint to zero address
    with_attr error_message("ERC1155: mint to the zero address"):
        assert_not_zero(to)
    end
    # Check args are equal length arrays
    with_attr error_message("ERC1155: ids and amounts length mismatch"):
        assert ids_len = amounts_len
    end
    # Recursive call
    let len = ids_len
    mint_batch_iter(to, len, ids, amounts)
    let (operator) = get_caller_address()
    TransferBatch.emit(
        operator=operator,
        from_=0,
        to=to,
        ids_len=ids_len,
        ids=ids,
        values_len=amounts_len,
        values=amounts)
    _do_safe_batch_transfer_acceptance_check(operator, 0, to, ids_len, ids, amounts_len, amounts)
    return ()
end

func ERC1155_burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_ : felt, id : Uint256, amount : Uint256):
    alloc_locals
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    with_attr error_message("ERC1155: burn from the zero address"):
        assert_not_zero(from_)
    end
    # beforeTokenTransfer
    # Check balance sufficient
    let (local from_balance) = ERC1155_balances_.read(id=id, account=from_)
    let (to_from_balance_uint) = _felt_to_uint(from_balance)
    let (sufficient_balance) = uint256_le(amount, to_from_balance_uint)
    with_attr error_message("ERC1155: burn amount exceeds balance"):
        assert_not_zero(sufficient_balance)
    end
    # Deduct from burner
    let (new_balance) = uint256_sub(to_from_balance_uint, amount)
    let (new_balance_uint) = _uint_to_felt(new_balance)
    ERC1155_balances_.write(id=id, account=from_, value=new_balance_uint)
    let (operator) = get_caller_address()
    TransferSingle.emit(operator=operator, from_=from_, to=0, id=id, value=amount)
    return ()
end

func ERC1155_burn_batch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_ : felt, ids_len : felt, ids : Uint256*, amounts_len : felt, amounts : Uint256*):
    alloc_locals
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    with_attr error_message("ERC1155: burn from the zero address"):
        assert_not_zero(from_)
    end
    # Check args are equal length arrays
    with_attr error_message("ERC1155: ids and amounts length mismatch"):
        assert ids_len = amounts_len
    end
    # Recursive call
    let len = ids_len
    burn_batch_iter(from_, len, ids, amounts)
    let (operator) = get_caller_address()
    TransferBatch.emit(
        operator=operator,
        from_=from_,
        to=0,
        ids_len=ids_len,
        ids=ids,
        values_len=amounts_len,
        values=amounts)
    return ()
end

#
# Internals
#

func _set_approval_for_all{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, operator : felt, approved : felt):
    # check approved is bool
    assert approved * (approved - 1) = 0
    # since caller can now be 0
    with_attr error_message("ERC1155: setting approval status for zero address"):
        assert_not_zero(owner * operator)
    end
    with_attr error_message("ERC1155: setting approval status for self"):
        assert_not_equal(owner, operator)
    end
    ERC1155_operator_approvals_.write(owner, operator, approved)
    ApprovalForAll.emit(owner, operator, approved)
    return ()
end

func _setURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(newuri : felt):
    ERC1155_uri_.write(newuri)
    return ()
end

func _do_safe_transfer_acceptance_check{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt, from_ : felt, to : felt, id : Uint256, amount : Uint256):
    let (caller) = get_caller_address()
    # ERC1155_RECEIVER_ID = 0x4e2312e0
    let (is_supported) = IERC165.supportsInterface(to, IERC1155_RECEIVER_ID)
    if is_supported == 1:
        let (selector) = IERC1155_Receiver.onERC1155Received(to, operator, from_, id, amount)

        # onERC1155Recieved selector
        with_attr error_message("ERC1155: ERC1155Receiver rejected tokens"):
            assert selector = ON_ERC1155_RECEIVED_SELECTOR
        end
        return ()
    end
    let (is_account) = IERC165.supportsInterface(to, IACCOUNT_ID)
    with_attr error_message("ERC1155: transfer to non ERC1155Receiver implementer"):
        assert_not_zero(is_account)
    end
    # IAccount_ID = 0x50b70dcb
    return ()
end

func _do_safe_batch_transfer_acceptance_check{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt, from_ : felt, to : felt, ids_len : felt, ids : Uint256*,
        amounts_len : felt, amounts : Uint256*):
    let (caller) = get_caller_address()
    # Confirm supports IERC1155Reciever interface
    let (is_supported) = IERC165.supportsInterface(to, IERC1155_RECEIVER_ID)
    if is_supported == 1:
        let (selector) = IERC1155_Receiver.onERC1155BatchReceived(
            to, operator, from_, ids_len, ids, amounts_len, amounts)

        # Confirm onBatchERC1155Recieved selector returned
        with_attr error_message("ERC1155: ERC1155Receiver rejected tokens"):
            assert selector = ON_BATCH_ERC1155_RECEIVED_SELECTOR
        end
        return ()
    end

    # Alternatively confirm EOA
    let (is_account) = IERC165.supportsInterface(to, IACCOUNT_ID)
    with_attr error_message("ERC1155: transfer to non ERC1155Receiver implementer"):
        assert_not_zero(is_account)
    end
    return ()
end

#
# Helpers
#

func balance_of_batch_iter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        len : felt, accounts : felt*, ids : Uint256*, batch_balances : Uint256*):
    if len == 0:
        return ()
    end
    # may be unnecessary now
    # Read current entries, Todo: perform Uint256 checks
    let id : Uint256 = [ids]
    uint256_check(id)
    let account : felt = [accounts]

    let (balance : Uint256) = ERC1155_balanceOf(account, id)
    assert [batch_balances] = balance
    return balance_of_batch_iter(
        len - 1, accounts + 1, ids + Uint256.SIZE, batch_balances + Uint256.SIZE)
end

func safe_batch_transfer_from_iter{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_ : felt, to : felt, len : felt, ids : Uint256*, amounts : Uint256*):
    # Base case
    alloc_locals
    if len == 0:
        return ()
    end

    # Read current entries,  perform Uint256 checks
    let id = [ids]
    with_attr error_message("ERC1155: invalid uint in calldata"):
        uint256_check(id)
    end
    let amount = [amounts]
    with_attr error_message("ERC1155: invalid uint in calldata"):
        uint256_check(amount)
    end

    # Check balance is sufficient
    let (from_balance) = ERC1155_balances_.read(id=id, account=from_)
    let (from_balance_uint) = _felt_to_uint(from_balance)
    let (sufficient_balance) = uint256_le(amount, from_balance_uint)
    with_attr error_message("ERC1155: insufficient balance for transfer"):
        assert_not_zero(sufficient_balance)
    end
    # deduct from
    let (new_balance : Uint256) = uint256_sub(from_balance_uint, amount)
    let (from_new_balance_felt) = _uint_to_felt(new_balance)    
    ERC1155_balances_.write(id=id, account=from_, value=from_new_balance_felt)

    # add to
    let (to_balance) = ERC1155_balances_.read(id=id, account=to)
    let (to_balance_uint) = _felt_to_uint(to_balance)
    let (new_balance : Uint256, carry) = uint256_add(to_balance_uint, amount)
    with_attr error_message("arithmetic overflow"):
        assert carry = 0  # overflow protection
    end
    let (from_new_balance_felt) = _uint_to_felt(new_balance) 
    ERC1155_balances_.write(id=id, account=to, value=from_new_balance_felt)

    # Recursive call
    return safe_batch_transfer_from_iter(
        from_, to, len - 1, ids + Uint256.SIZE, amounts + Uint256.SIZE)
end

func mint_batch_iter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, len : felt, ids : Uint256*, amounts : Uint256*):
    # Base case
    alloc_locals
    if len == 0:
        return ()
    end

    # Read current entries, Todo: perform Uint256 checks
    let id : Uint256 = [ids]
    let amount : Uint256 = [amounts]
    with_attr error_message("ERC1155: invalid uint256 in calldata"):
        uint256_check(id)
        uint256_check(amount)
    end
    # add to
    let (to_balance) = ERC1155_balances_.read(id=id, account=to)
    let (to_balance_uint) = _felt_to_uint(to_balance)
    let (new_balance : Uint256, carry) = uint256_add(to_balance_uint, amount)
    with_attr error_message("ERC1155: arithmetic overflow"):
        assert carry = 0  # overflow protection
    end
    let (new_balance_felt) = _uint_to_felt(new_balance) 
    ERC1155_balances_.write(id=id, account=to, value=new_balance_felt)

    # Recursive call
    return mint_batch_iter(to, len - 1, ids + Uint256.SIZE, amounts + Uint256.SIZE)
end

func burn_batch_iter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        from_ : felt, len : felt, ids : Uint256*, amounts : Uint256*):
    # Base case
    alloc_locals
    if len == 0:
        return ()
    end

    # Read current entries, Todo: perform Uint256 checks
    let id : Uint256 = [ids]
    with_attr error_message("ERC1155: invalid uint in calldata"):
        uint256_check(id)
    end
    let amount : Uint256 = [amounts]
    with_attr error_message("ERC1155: invalid uint in calldata"):
        uint256_check(amount)
    end

    # Check balance is sufficient
    let (from_balance) = ERC1155_balances_.read(id=id, account=from_)
    let (from_balance_uint) = _felt_to_uint(from_balance)
    let (sufficient_balance) = uint256_le(amount, from_balance_uint)
    with_attr error_message("ERC1155: burn amount exceeds balance"):
        assert_not_zero(sufficient_balance)
    end

    # deduct from
    let (new_balance : Uint256) = uint256_sub(from_balance_uint, amount)

    let (new_balance_felt) = _uint_to_felt(new_balance)

    ERC1155_balances_.write(id=id, account=from_, value=new_balance_felt)

    # Recursive call
    return burn_batch_iter(from_, len - 1, ids + Uint256.SIZE, amounts + Uint256.SIZE)
end

func owner_or_approved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner):
    let (caller) = get_caller_address()
    if caller == owner:
        return ()
    end
    let (approved) = ERC1155_isApprovedForAll(owner, caller)
    assert approved = 1
    return ()
end

func _uint_to_felt{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (value: Uint256) -> (value: felt):
    assert_lt_felt(value.high, 2**123)
    return (value.high * (2 ** 128) + value.low)
end

func _felt_to_uint{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (value: felt) -> (value: Uint256):
    let (high, low) = split_felt(value)
    tempvar res: Uint256
    res.high = high
    res.low = low
    return (res)
end