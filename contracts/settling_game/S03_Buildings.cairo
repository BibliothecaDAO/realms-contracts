# ____MODULE_S03___BUILDING_STATE
#   TODO: Add Module Description
#
# MIT License
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.utils.constants import TRUE, FALSE
from contracts.settling_game.interfaces.imodules import IModuleController

from contracts.settling_game.utils.library import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
    MODULE_only_arbiter,
)

###########
# STORAGE #
###########

@storage_var
func realm_buildings(token_id : Uint256) -> (buildings : felt):
end

###############
# CONSTRUCTOR #
###############

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt
):
    # Store the address of the only fixed contract in the system.
    MODULE_initializer(address_of_controller)
    return ()
end

###########
# SETTERS #
###########

@external
func set_realm_buildings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, buildings_value : felt
):
    MODULE_only_approved()
    realm_buildings.write(token_id, buildings_value)

    return ()
end

###########
# GETTERS #
###########

# GETS REALM BUILDS
@view
func get_realm_buildings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (buildings : felt):
    let (buildings) = realm_buildings.read(token_id)

    return (buildings=buildings)
end
