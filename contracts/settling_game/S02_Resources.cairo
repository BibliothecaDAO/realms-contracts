%lang starknet

from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.interfaces.imodules import IModuleController
from contracts.settling_game.utils.library import (
    MODULE_controller_address, MODULE_only_approved, MODULE_initializer, MODULE_only_arbiter)

# ___MODULE_S02___RESOURCE_STATE

# STORE RESOURCE LEVEL
@storage_var
func resource_levels(token_id : Uint256, resource_id : felt) -> (level : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    MODULE_initializer(address_of_controller)
    return ()
end

############
# EXTERNAL #
############

@external
func set_resource_level{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(token_id : Uint256, resource_id : felt, level : felt) -> ():
    MODULE_only_approved()
    resource_levels.write(token_id, resource_id, level)

    return ()
end

###########
# GETTERS #
###########

@view
func get_resource_level{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, resource : felt) -> (level : felt):
    let (level) = resource_levels.read(token_id, resource)

    return (level=level)
end
