// -----------------------------------
//   ARBITER
//   The Arbiter has authority over the ModuleController.
//   Responsible for deciding how the controller administers authority.
//   Can be replaced by a vote-based module by calling the
//   appoint_new_arbiter() in the ModuleController.
//   Has an Owner, that may itself be a multisig account contract.
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.interfaces.imodules import IModuleController

@storage_var
func controller_address() -> (address: felt) {
}

// 1=locked.
@storage_var
func lock() -> (bool: felt) {
}

// -----------------------------------
// Initialize & upgrade
// -----------------------------------

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @return proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt
) {
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

// @notice Invoked to save the address of the Module Controller
// @param contract_address: Address of the Module Controller
@external
func set_address_of_controller{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_address: felt
) {
    Proxy.assert_only_admin();
    let (locked) = lock.read();
    // Locked starts as zero
    assert_not_zero(TRUE - locked);
    lock.write(TRUE);

    controller_address.write(contract_address);
    return ();
}

// @notice Invoked to replace the contract that controls the Arbiter
// @param new_arbiter_address: Address of the new arbiter
@external
func replace_self{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_arbiter_address: felt
) {
    Ownable.assert_only_owner();
    let (controller) = controller_address.read();
    // The ModuleController has a fixed address. The Arbiter
    // may be upgraded by calling the ModuleController and declaring
    // the new Arbiter.
    IModuleController.appoint_new_arbiter(controller, new_arbiter_address);

    return ();
}

// @notice Invoked to appoint a new owner
// @param new_owner_address: New owner address
@external
func appoint_new_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_owner_address: felt
) {
    Proxy.assert_only_admin();
    Ownable.transfer_ownership(new_owner_address);
    return ();
}

// @notice Invoked to approve a deployed module as identified by an ID
// @param module_address: Module address
// @param module_id: Module id
@external
func appoint_contract_as_module{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    module_address: felt, module_id: felt
) {
    Proxy.assert_only_admin();
    let (controller) = controller_address.read();
    // Call the ModuleController and enable the new address.
    IModuleController.set_address_for_module_id(controller, module_id, module_address);
    return ();
}

// @notice Invoked to set an external contract
// @param address: External contract address
// @param contract_id: External contract id
@external
func set_external_contract_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt, contract_id: felt
) {
    Proxy.assert_only_admin();
    let (controller) = controller_address.read();
    // Call the ModuleController and enable the new address.
    IModuleController.set_address_for_external_contract(controller, contract_id, address);
    return ();
}

// @notice Sets Xoroshiro or other random number address
// @param address: Xoroshiro contract address
@external
func set_xoroshiro{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) {
    Proxy.assert_only_admin();
    let (controller) = controller_address.read();
    IModuleController.set_xoroshiro(controller, address);
    return ();
}

// @notice Called to authorise write access of one module to another
// @param module_id_doing_writing: Writing module id
// @param module_id_being_written_to: Writee module id
@external
func approve_module_to_module_write_access{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(module_id_doing_writing: felt, module_id_being_written_to: felt) {
    Proxy.assert_only_admin();
    let (controller) = controller_address.read();
    IModuleController.set_write_access(
        contract_address=controller,
        module_id_doing_writing=module_id_doing_writing,
        module_id_being_written_to=module_id_being_written_to,
    );
    return ();
}