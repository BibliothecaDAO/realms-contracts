%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check
)
from starkware.starknet.common.messages import send_message_to_l1
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

@l1_handler
func depositFromL1{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
        from_address: felt, # Starknet special field - filled for L1 caller contract
        l1_owner_address: felt,
        to: felt, 
        token_ids_len: felt, 
        token_ids: felt*
    ):
    alloc_locals
    # Make sure the message was sent by the intended L1 contract.
    let (address) = l1_lockbox_contract_address.read()
    assert from_address = address

    let (realms_address) = l2_realms_contract_address.read()

    mint_loop(to, token_ids_len, token_ids, l1_owner_address, realms_address)

    return ()
end

func mint_loop{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
        to: felt, 
        token_ids_len: felt, 
        token_ids: felt*,
        l1_owner_address: felt,
        l2_realms_address: felt
    ):
    alloc_locals
    if token_ids_len == 0:
        return ()
    end

    # Recreate Uin256 from low/high values
    let token_id: Uint256 = Uint256([token_ids], [token_ids + 1])

    IBridgeable_ERC721.bridge_mint(
        contract_address=l2_realms_address, 
        to=to, 
        token_id=token_id
    )

    # Used for withdrawing back to L1
    token_owners.write(token_id, l1_owner_address)

    mint_loop(to, token_ids_len - 2, token_ids + 2, l1_owner_address, l2_realms_address)

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