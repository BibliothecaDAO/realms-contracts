%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.utils.constants import TRUE, FALSE
from contracts.settling_game.interfaces.imodules import IModuleController

from contracts.settling_game.utils.library import (
    MODULE_controller_address, MODULE_only_approved, MODULE_initializer, MODULE_only_arbiter)

# ____MODULE_S03___BUILDING_STATE

###########
# STORAGE #
###########

@storage_var
func building_cost_ids(building_id : felt) -> (cost_ids : felt):
end

@storage_var
func building_cost_values(building_id : felt) -> (cost_values : felt):
end

@storage_var
func realm_buildings(token_id : Uint256) -> (buildings : felt):
end

###############
# CONSTRUCTOR #
###############

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    # Store the address of the only fixed contract in the system.
    MODULE_initializer(address_of_controller)
    return ()
end

###########
# SETTERS #
###########

@external
func set_building_cost_ids{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt, cost : felt) -> (success : felt):
    # TODO: ONLY ALLOW OWNER
    building_cost_ids.write(building_id, cost)

    return (TRUE)
end

@external
func set_building_cost_values{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt, cost : felt) -> (success : felt):
    # TODO: ONLY ALLOW OWNER
    building_cost_values.write(building_id, cost)

    return (TRUE)
end

@external
func set_realm_buildings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, buildings_value : felt):
    MODULE_only_approved()
    realm_buildings.write(token_id, buildings_value)

    return ()
end

###########
# GETTERS #
###########

# GETS BUILDING COST IDS
@external
func get_building_cost_ids{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt) -> (cost : felt):
    let (ids) = building_cost_ids.read(building_id)

    return (cost=ids)
end

# GETS BUILDING COSTS VALUES
@external
func get_building_cost_values{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt) -> (cost : felt):
    let (cost) = building_cost_values.read(building_id)

    return (cost=cost)
end

# GETS REALM BUILDS
@external
func get_realm_buildings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (buildings : felt):
    let (buildings) = realm_buildings.read(token_id)

    return (buildings=buildings)
end
