%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.starknet.common.eth_utils import assert_eth_address_range
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import get_caller_address

// aliases
using address = felt;
using l1_address = felt;

// operation ID sent in the message payload to L1
const PROCESS_WITHDRAWAL = 1;

@contract_interface
namespace IMintable {
    func mint(to: address, amount: Uint256) {
    }
}

@contract_interface
namespace IBurnable {
    func burn_away(owner: address, amount: Uint256) {
    }
}

// L1 bridge contract address, the L1 counterpart to this contract
@storage_var
func l1_bridge() -> (addr: l1_address) {
}

// L2 $LORDS token address
@storage_var
func lords() -> (addr: address) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _l1_bridge: l1_address, _lords: address
) {
    l1_bridge.write(_l1_bridge);
    lords.write(_lords);

    return ();
}

@l1_handler
func handle_deposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_address: felt, recipient: address, amount_low: felt, amount_high: felt, sender: l1_address
) {
    // note: `sender` is the L1 msg.sender value, we don't use it

    with_attr error_message("Bridge: Invalid L1 message origin") {
        let (bridge: l1_address) = l1_bridge.read();
        assert from_address = bridge;
    }

    let amount: Uint256 = Uint256(low=amount_low, high=amount_high);
    let (lords_token: address) = lords.read();

    IMintable.mint(lords_token, recipient, amount);

    return ();
}

@external
func initiate_withdrawal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    l1_recipient: l1_address, amount: Uint256
) {
    with_attr error_message("Bridge: Invalid L1 address") {
        assert_eth_address_range(l1_recipient);
    }

    with_attr error_message("Bridge: Invalid amount") {
        uint256_check(amount);
    }

    let (bridge: l1_address) = l1_bridge.read();
    with_attr error_message("Bridge: L1 recipient cannot be the bridge") {
        assert_not_equal(l1_recipient, bridge);
    }

    let (lords_token: address) = lords.read();
    let (caller: address) = get_caller_address();

    IBurnable.burn_away(lords_token, caller, amount);

    tempvar payload: felt* = new (PROCESS_WITHDRAWAL, l1_recipient, amount.low, amount.high);
    send_message_to_l1(bridge, 4, payload);

    return ();
}

@view
func get_l1_bridge{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    addr: l1_address
) {
    let (addr: l1_address) = l1_bridge.read();
    return (addr,);
}

@view
func get_lords{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    addr: address
) {
    let (addr: address) = lords.read();
    return (addr,);
}
