%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn, assert_lt_felt, assert_not_zero, unsigned_div_rem
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check
)
# from starkware.cairo.common.eth_utils import assert_valid_eth_address

from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.starknet.common.messages import send_message_to_l1

from contracts.token.IERC721 import IERC721
from contracts.l2.bridge.IBridgeable_ERC721 import IBridgeable_ERC721

from contracts.Ownable_base import Ownable_initializer, Ownable_only_owner

@storage_var
func l1_lockbox_contract_address() -> (res: felt):
end

@storage_var
func l2_realms_contract_address() -> (res: felt):
end

@storage_var
func token_owners(token_id: Uint256) -> (owner: felt):
end

@constructor
func constructor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
        owner: felt,
        l2_realms_address: felt
    ):
    Ownable_initializer(owner)

    l2_realms_contract_address.write(l2_realms_address)

    return ()
end

##########################
## Depositing from L1
##########################
@l1_handler
func depositFromL1{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
        from_address: felt, # Starknet special field - filled for L1 caller contract
        to: felt,
        token_ids_len: felt, 
        token_ids: felt*
    ):
    alloc_locals
    # Make sure the message was sent by the intended L1 contract.
    let (address) = l1_lockbox_contract_address.read()
    assert from_address = address

    # Checking if token_ids_len was correctly formatted because it should contain [low, high, low, high] values
    # let (q, ids_len_rem) = unsigned_div_rem(token_ids_len, 2)
    # assert ids_len_rem = 0

    bridge_mint_loop(to, token_ids_len, token_ids)

    return ()
end

func bridge_mint_loop{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
        to: felt, 
        token_ids_len: felt, 
        token_ids: felt*
    ):
    alloc_locals
    
    if token_ids_len == 0:
        return ()
    end

    # Recreate Uin256 from low/high values
    tempvar token_id: Uint256 = Uint256([token_ids], [token_ids + 1])
    
    # Not tested and not sure but this call probably should be here - no big overhead 
    let (realms_address) = l2_realms_contract_address.read()
    
    IBridgeable_ERC721.bridge_mint(
        contract_address=realms_address, 
        to=to, 
        token_id=token_id
    )

    bridge_mint_loop(to, token_ids_len - 2, token_ids + 2)

    return ()
end

##########################
## Withdrawing to L1
##########################
@external
func withdrawToL1{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
        to_address: felt, # L1 wallet
        token_ids_len: felt,
        token_ids: Uint256*
    ):
    alloc_locals

    # Validate that to address is not a zero and Ethereum
    # assert_valid_eth_address(to_address)
    assert_not_zero(to_address)

    # Let's do this
    let (message_payload: felt*) = alloc()

    assert message_payload[0] = to_address

    # Collect all token_ids
    withdraw_loop(to_address, token_ids_len, token_ids, 1, message_payload)

    # Send a message
    let (l1_lockbox_addr) = l1_lockbox_contract_address.read()
    tempvar payload_size = 1 + (token_ids_len * 2)
    send_message_to_l1(
        to_address=l1_lockbox_addr,
        payload_size=payload_size,
        payload=message_payload
    )

    return ()
end

func withdraw_loop{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
        to: felt, 
        token_ids_len: felt, 
        token_ids: felt*,
        message_payload_len: felt,
        message_payload: felt*
    ):
    alloc_locals
    
    if token_ids_len == 0:
        return ()
    end

    # Not tested and not sure but this call probably should be here - no big overhead 
    let (realms_address) = l2_realms_contract_address.read()

    let (token_id: Uint256) = [token_ids]

    # Check if caller is the owner
    let (caller) = get_caller_address()
    let (owner) = IERC721.ownerOf(
        contract_address=realms_address,
        token_id=token_id
    )
    assert caller = owner

    # address(this) equivalent
    let (contract_address) = get_contract_address()

    # Move token to Bridge
    IERC721.transferFrom(
        contract_address=realms_address,
        _from=caller,
        to=contract_address,
        token_id=token_id
    )
 
    withdraw_loop(to, token_ids_len - 1, token_ids + 1)

    return ()
end


@external
func set_l1_lockbox_contract_address{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
        new_address: felt
    ):

    Ownable_only_owner()

    l1_lockbox_contract_address.write(new_address)

    return ()
end

@external
func set_l2_realms_contract_address{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
        new_address: felt
    ):

    Ownable_only_owner()

    l2_realms_contract_address.write(new_address)

    return ()
end

@view
func get_l1_lockbox_contract_address{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
    ) -> (address: felt):

    let (address) = l1_lockbox_contract_address.read()

    return (address)
end

@view
func get_l2_realms_contract_address{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
    ) -> (address: felt):

    let (address) = l2_realms_contract_address.read()

    return (address)
end