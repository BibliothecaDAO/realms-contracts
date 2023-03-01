%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from contracts.desiege.utils.interfaces import IModuleController

@storage_var
func controller_address() -> (address: felt) {
}

// Stores whether a (L1) address has minted
// for a given game idx
@storage_var
func has_minted(l1_address: felt, game_idx: felt) -> (has_minted: felt) {
}

// token IDs vary each game so token_id is only param required
@storage_var
func total_minted(token_id: felt) -> (total: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address_of_controller: felt
) {
    controller_address.write(address_of_controller);
    return ();
}

@view
func get_has_minted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    l1_address: felt, game_idx: felt
) -> (result: felt) {
    let (minted) = has_minted.read(l1_address, game_idx);
    return (result=minted);
}

@external
func set_has_minted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    l1_address: felt, game_idx: felt, minted_bool: felt
) {
    only_approved();

    has_minted.write(l1_address, game_idx, minted_bool);
    return ();
}

@view
func get_total_minted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_idx: felt
) -> (total: felt) {
    let (total) = total_minted.read(token_idx);
    return (total,);
}

@external
func set_total_minted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_idx: felt, total: felt
) {
    only_approved();

    total_minted.write(token_idx, total);
    return ();
}

// Checks write-permission of the calling contract.
func only_approved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // Get the address of the module trying to write to this contract.
    let (caller) = get_caller_address();
    let (controller) = controller_address.read();
    // Pass this address on to the ModuleController.
    // "Does this address have write-authority here?"
    // Will revert the transaction if not.
    IModuleController.has_write_access(
        contract_address=controller, address_attempting_to_write=caller
    );
    return ();
}
