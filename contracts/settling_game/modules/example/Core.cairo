// -----------------------------------
//   Module.EXAMPLE
//   [insert what this module does]
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from contracts.settling_game.interfaces.imodules import IModuleController

from contracts.settling_game.library.library_module import Module

from openzeppelin.upgrades.library import Proxy

// Steps - Copy and modify this template contract for new modules.
// 1. Start writing Logic within the library.cairo file.
// 2. Create tests around this Logic within the ./tests/protostar/settling_game/[module]/module_test.cairo
// 3. Once stateless logic is complete, begin on the Core.cairo file.
// 4. Import library into this file
// 5. Import other libraries where neded
// 6. Add module ID into the ModuleIds struct.

// -----------------------------------
// INITIALIZER & UPGRADE
// -----------------------------------

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address_of_controller: felt, proxy_admin: felt
) {
    Module.initializer(address_of_controller);
    Proxy.initializer(proxy_admin);
    return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

// -----------------------------------
// EXTERNAL
// -----------------------------------

// Called by another module to update a global variable.
@external
func update_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // TODO Customise.
    Module.only_approved();
    return ();
}

// -----------------------------------
// GETTERS
// -----------------------------------

// -----------------------------------
// SETTERS
// -----------------------------------
