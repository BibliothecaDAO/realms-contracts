%lang starknet
%builtins pedersen range_check

# Starkware
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn, assert_lt_felt, assert_not_zero, unsigned_div_rem
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check
)
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.starknet.common.messages import send_message_to_l1

# OZ
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721
from openzeppelin.access.ownable import Ownable_initializer, Ownable_only_owner
from openzeppelin.utils.constants import IERC721_RECEIVER_ID
from openzeppelin.introspection.ERC165 import (
    ERC165_supports_interface,
    ERC165_register_interface
)

@storage_var
func l1_bridge_contract_address() -> (res: felt):
end

@storage_var
func l2_realms_contract_address() -> (res: felt):
end

# 1 or 2
@storage_var
func journey_versions(token_id: Uint256) -> (version: felt):
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

    ERC165_register_interface(IERC721_RECEIVER_ID)

    l2_realms_contract_address.write(l2_realms_address)

    return ()
end

##########################
## Complience
##########################
@view
func supportsInterface{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(interfaceId: felt) -> (success: felt):
    let (success) = ERC165_supports_interface(interfaceId)
    return (success)
end

@view
func onERC721Received(
        operator: felt,
        from_: felt,
        tokenId: Uint256,
        data_len: felt,
        data: felt*
    ) -> (selector: felt): 
    return (IERC721_RECEIVER_ID)
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
        data_len: felt, 
        data: felt*
    ):
    alloc_locals
    # Make sure the message was sent by the intended L1 contract.
    let (address) = l1_bridge_contract_address.read()
    assert from_address = address

    bridge_transfer_loop(to, data_len, data)

    return ()
end

func bridge_transfer_loop{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
        to: felt,
        data_len: felt, 
        data: felt*
    ):
    alloc_locals
    
    if data_len == 0:
        return ()
    end

    # Recreate Uin256 from low/high values
    tempvar token_id: Uint256 = Uint256([data], [data + 1])

    tempvar journey_version = [data + 2]
    
    # Not tested and not sure but this call probably should be here - no big overhead 
    let (realms_address) = l2_realms_contract_address.read()

    let (contract_address) = get_contract_address()

    IERC721.transferFrom(
        contract_address=realms_address,
        from_=contract_address,
        to=to,
        tokenId=token_id
    )

    # Save Journey for future withdrawal - we need to know which contract to call on L1
    journey_versions.write(token_id, journey_version)

    bridge_transfer_loop(to, data_len - 3, data + 3)

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
    withdraw_loop(to_address, token_ids_len, token_ids, 1, message_payload + 1)

    # Send a message
    let (l1_bridge_addr) = l1_bridge_contract_address.read()
    
    tempvar payload_size = 1 + (token_ids_len * 3) # 2 for low/high, 1 for journey version
    
    send_message_to_l1(
        to_address=l1_bridge_addr,
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
        token_ids: Uint256*,
        message_payload_len: felt,
        message_payload: felt*
    ):
    alloc_locals
    
    if token_ids_len == 0:
        return ()
    end

    # Not tested and not sure but this call probably should be here - no big overhead 
    let (realms_address) = l2_realms_contract_address.read()

    let token_id: Uint256 = [token_ids]

    # Check if caller is the owner
    let (caller) = get_caller_address()
    let (owner) = IERC721.ownerOf(
        contract_address=realms_address,
        tokenId=token_id
    )
    assert caller = owner

    # Move token to Bridge
    # address(this) equivalent
    let (contract_address) = get_contract_address()
    IERC721.transferFrom(
        contract_address=realms_address,
        from_=caller,
        to=contract_address,
        tokenId=token_id
    )

    # Save to payload
    assert [message_payload] = token_id.low
    assert [message_payload + 1] = token_id.high

    # Get Journey version
    let (journey_version) = journey_versions.read(token_id)
    assert [message_payload + 2] = journey_version
 
    withdraw_loop(to, token_ids_len - 1, token_ids + Uint256.SIZE, message_payload_len + 3, message_payload + 3)

    return ()
end


@external
func set_l1_bridge_contract_address{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
        new_address: felt
    ):

    Ownable_only_owner()

    l1_bridge_contract_address.write(new_address)

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
func get_l1_bridge_contract_address{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
    ) -> (address: felt):

    let (address) = l1_bridge_contract_address.read()

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