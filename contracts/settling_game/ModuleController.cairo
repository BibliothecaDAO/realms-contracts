// -----------------------------------
//   MODULE CONTROLLER
//   A long-lived open-ended lookup table that routes logic between modules.
//   Each module must be registered here and Logic vs State write permissions are mapped here.
//
//  Is in control of the addresses game modules use.
//  Is controlled by the Arbiter, who can update addresses. This will be a Multisig.
//  Maintains a generic mapping that is open ended and which
//  can be added to for new modules.
//
//  To be compliant with this system, a new module containint variables
//  intended to be open to the ecosystem MUST implement a check
//  on any contract.
//  1. Get address attempting to write to the variables in the contract.
//  2. Call 'has_write_access()'
//
// This way, new modules can be added to update existing systems a
// and create new dynamics.
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.upgrades.library import Proxy

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func arbiter() -> (address: felt) {
}

// The contract address for a module.
@storage_var
func address_of_module_id(module_id: felt) -> (address: felt) {
}

// The module id of a contract address.
@storage_var
func module_id_of_address(address: felt) -> (module_id: felt) {
}

// A mapping of which modules have write access to the others. 1=yes.
@storage_var
func can_write_to(doing_writing: felt, being_written_to: felt) -> (bool: felt) {
}

// NON Module Address Lookup table
@storage_var
func external_contract_table(external_contract_id: felt) -> (address: felt) {
}

// Genesis time
@storage_var
func genesis() -> (time: felt) {
}

// Random number address
@storage_var
func xoroshiro_address() -> (address: felt) {
}

// -----------------------------------
// Initialize & upgrade
// -----------------------------------

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @return proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    arbiter_address: felt, proxy_admin: felt
) {
    arbiter.write(arbiter_address);

    // set genesis
    let (block_timestamp) = get_block_timestamp();
    genesis.write(block_timestamp);

    Proxy.initializer(proxy_admin);
    return ();
}

// @notice Set new proxy implementation
// @dev Can only be set by the arbiter
// @param new_implementation: New implementation contract address
@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

// -----------------------------------
// SETTERS
// -----------------------------------

// -----------------------------------
// SETTERS
// -----------------------------------
// @notice Called by the Arbiter to set new address mappings
// @param external_contract_id: External contract id
// @param contract_address: New contract address
@external
func set_address_for_external_contract{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(external_contract_id: felt, contract_address: felt) {
    only_arbiter();
    external_contract_table.write(external_contract_id, contract_address);
    return ();
}

// @notice Called by the current Arbiter to replace itself.
// @param new_arbiter: New arbiter contract address
@external
func appoint_new_arbiter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_arbiter: felt
) {
    only_arbiter();
    arbiter.write(new_arbiter);
    return ();
}

// @notice Called by the Arbiter to set new address mappings
// @param module_id: Module id
// @param module_address: New module address
@external
func set_address_for_module_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    module_id: felt, module_address: felt
) {
    only_arbiter();
    address_of_module_id.write(module_id, module_address);
    module_id_of_address.write(module_address, module_id);
    return ();
}

// @notice Called to authorise write access of one module to another.
// @param module_id_doing_writing: Writer module id
// @param module_id_being_written_to: Module id being written to
@external
func set_write_access{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    module_id_doing_writing: felt, module_id_being_written_to: felt
) {
    only_arbiter();
    can_write_to.write(module_id_doing_writing, module_id_being_written_to, TRUE);
    return ();
}

@external
func set_xoroshiro{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    xoroshiro: felt
) {
    only_arbiter();
    xoroshiro_address.write(xoroshiro);
    return ();
}

// -----------------------------------
// GETTERS
// -----------------------------------

// @notice Get module address
// @param module_id: Module id
// @return address: Module address
@view
func get_module_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    module_id: felt
) -> (address: felt) {
    return address_of_module_id.read(module_id);
}

// @notice Get external contract address
// @param external_contract_id: External contract id
// @return address: External contract address
@view
func get_external_contract_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    external_contract_id: felt
) -> (address: felt) {
    return external_contract_table.read(external_contract_id);
}

// @notice Get time of deployment
// @return genesis_time: Genesis time
@view
func get_genesis{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    time: felt
) {
    return genesis.read();
}

// @notice Get arbiter
// @return Arbiter address
@view
func get_arbiter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
) {
    return arbiter.read();
}

@view
func get_xoroshiro{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    address: felt
) {
    return xoroshiro_address.read();
}
// -----------------------------------
// INTERNALS
// -----------------------------------

// @notice Check if a module (caller) has write access to another module
// @param address_attempting_to_write
// @return success: 1 if successful, 0 otherwise
@view
func has_write_access{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address_attempting_to_write: felt
) -> (success: felt) {
    alloc_locals;

    // Approves the write-permissions between two modules, ensuring
    // first that the modules are both active (not replaced), and
    // then that write-access has been given.

    // Get the address of the module calling (being written to).
    let (caller) = get_caller_address();
    let (module_id_being_written_to) = module_id_of_address.read(caller);

    // Make sure the module has not been replaced.
    let (current_module_address) = address_of_module_id.read(module_id_being_written_to);

    if (current_module_address != caller) {
        return (FALSE,);
    }

    // Get the module id of the contract that is trying to write.
    let (module_id_attempting_to_write) = module_id_of_address.read(address_attempting_to_write);

    // Make sure that module has not been replaced.
    let (active_address) = address_of_module_id.read(module_id_attempting_to_write);

    if (active_address != address_attempting_to_write) {
        return (FALSE,);
    }
    // See if the module has permission.
    let (bool) = can_write_to.read(module_id_attempting_to_write, module_id_being_written_to);

    if (bool == FALSE) {
        return (FALSE,);
    }

    return (TRUE,);
}

// -----------------------------------
// PRIVATES
// -----------------------------------

// @notice Check if caller is the arbiter
// @dev Reverts if caller is not the arbiter
func only_arbiter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller) = get_caller_address();
    let (current_arbiter) = arbiter.read();
    assert caller = current_arbiter;
    return ();
}
