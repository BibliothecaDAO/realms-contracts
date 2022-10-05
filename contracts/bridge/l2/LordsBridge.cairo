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
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.introspection.ERC165.library import ERC165
from openzeppelin.upgrades.library import Proxy

@storage_var
func l1_bridge_contract_address() -> (res: felt):
end

@storage_var
func lords_contract_address() -> (res: felt):
end

###############
# CONSTRUCTOR #
###############

@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proxy_admin : felt
):
    Ownable.initializer(proxy_admin)
    Proxy.initializer(proxy_admin)
    ERC165.register_interface(IERC721_RECEIVER_ID)

    return ()
end

@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy.assert_only_admin()
    Proxy._set_implementation_hash(new_implementation)
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
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
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
        amount: felt
    ):
    alloc_locals

    # Make sure the message was sent by the intended L1 contract.
    let (address) = l1_bridge_contract_address.read()
    assert from_address = address

    let (lords_address) = lords_contract_address.read()
    let (contract_address) = get_contract_address()

    ILords.bridge_mint(to, amount)

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
        amount: felt
    ):
    alloc_locals

    # Validate that to address is not a zero and Ethereum
    # assert_valid_eth_address(to_address)
    assert_not_zero(to_address)

    assert_not_zero(amount)

    # Burn
    ILords.bridge_burn(amount)

    # Send message
    let (l1_bridge_addr) = l1_bridge_contract_address.read()

    let (message_payload: felt*) = alloc()

    assert message_payload[0] = to_address
    assert message_payload[1] = amount
    
    send_message_to_l1(
        to_address=l1_bridge_addr,
        payload_size=2,
        payload=message_payload
    )

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

    Ownable.assert_only_owner()

    l1_bridge_contract_address.write(new_address)

    return ()
end

@external
func set_lords_contract_address{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
        new_address: felt
    ):

    Ownable.assert_only_owner()

    lords_contract_address.write(new_address)

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
func get_lords_contract_address{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (
    ) -> (address: felt):

    let (address) = lords_contract_address.read()

    return (address)
end