# Shared utility functions
#   Functions used throughout the settling game. This is not a contract.
#   Instead, items from this file should be imported into any module
#   that is a contract and used there.
#
# MIT License

# SPDX-License-Identifier: MIT
# Realms Contracts v0.0.1 (library.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.math import assert_not_zero, assert_lt
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    uint256_le,
    uint256_lt,
    uint256_check,
)

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
    address_of_controller : felt
):
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

# MODULE WRITE ACCESS CHECK
func only_approved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    success : felt
):
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()

    # Pass this address on to the ModuleController
    # Will revert the transaction if not.
    let (success) = IModuleController.has_write_access(controller, caller)

    

    return (success)
end

func MODULE_only_approved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (success) = only_approved()
    let (self) = check_self()
    assert_not_zero(success + self)
    return ()
end

func check_self{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}()->(success: felt):
    let (caller) = get_caller_address()
    let (contract_address) = get_contract_address()

    if caller == contract_address :
        return(1)
    end

    return (0)
end

# ARBITER WRITE ACCESS CHECK
func only_arbiter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    success : felt
):
    alloc_locals
    let (controller) = controller_address.read()
    let (caller) = get_caller_address()
    let (current_arbiter) = IModuleController.get_arbiter(controller)

    if caller != current_arbiter:
        return (0)
    end

    return (1)
end

func MODULE_only_arbiter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (success) = only_arbiter()
    assert_not_zero(success)
    return ()
end
