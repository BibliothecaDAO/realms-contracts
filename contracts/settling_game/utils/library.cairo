# SPDX-License-Identifier: MIT
# Realms Contracts v0.0.1 (library.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_lt
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check)

from contracts.settling_game.interfaces.imodules import IModuleController

###########
# STORAGE #
###########

@storage_var
func controller_address() -> (address : felt):
end

########
# INIT #
########

func MODULE_initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    controller_address.write(address_of_controller)
    return ()
end

###########
# GETTERS #
###########

func MODULE_controller_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (address : felt):
    let (address) = controller_address.read()
    return (address)
end

##########
# CHECKS #
##########

func MODULE_only_approved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()

    # Pass this address on to the ModuleController
    # Will revert the transaction if not.
    IModuleController.has_write_access(
        contract_address=controller, address_attempting_to_write=caller)
    return ()
end
