%lang starknet

from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.interfaces.imodules import IModuleController
from contracts.settling_game.utils.library import (
    MODULE_controller_address, MODULE_only_approved, MODULE_initializer, MODULE_only_arbiter)

# #### Module 2B #########
# Claim & Resource State #
##########################

@storage_var
func resource_levels(token_id : Uint256, resource_id : felt) -> (level : felt):
end

@storage_var
func resource_upgrade_cost(resource_id : felt) -> (value : felt):
end

@storage_var
func resource_upgrade_value(resource_id : felt) -> (ids : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    MODULE_initializer(address_of_controller)
    return ()
end

# ##### SETTERS ######

@external
func set_resource_upgrade_value{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(resource_id : felt, _resource_upgrade_ids : felt) -> ():
    # TODO: ONLY ALLOW OWNER
    resource_upgrade_value.write(resource_id, _resource_upgrade_ids)

    return ()
end

@external
func set_resource_upgrade_cost{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(resource_id : felt, _resource_upgrade_values : felt) -> ():
    # TODO: ONLY ALLOW OWNER
    resource_upgrade_cost.write(resource_id, _resource_upgrade_values)

    return ()
end

@external
func set_resource_level{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(token_id : Uint256, resource_id : felt, level : felt) -> ():
    MODULE_only_approved()
    resource_levels.write(token_id, resource_id, level)

    return ()
end

#
# GETTERS
#

@external
func get_resource_level{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, resource : felt) -> (level : felt):
    alloc_locals

    local l

    let (level) = resource_levels.read(token_id, resource)

    # TODO Change to dynamic figure
    if level == 0:
        assert l = 100
    else:
        assert l = level * 100
    end

    return (level=l)
end

# TODO: Price of Resource upgrades should increase
@external
func get_resource_upgrade_cost{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(token_id : Uint256, resource_id : felt) -> (level : felt):
    let (data) = resource_upgrade_cost.read(resource_id)

    return (level=data)
end

@external
func get_resource_upgrade_value{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(resource_id : felt) -> (level : felt):
    let (data) = resource_upgrade_value.read(resource_id)

    return (level=data)
end
