%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.general import scale
from contracts.settling_game.utils.game_structs import (
    RealmBuildings, RealmBuildingCostIds, RealmBuildingCostValues)

from contracts.settling_game.utils.constants import TRUE, FALSE

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721
from contracts.settling_game.interfaces.imodules import IModuleController

from contracts.settling_game.utils.library import (
    MODULE_controller_address, MODULE_only_approved, MODULE_initializer)

# ____MODULE_L03___BUILDING_STATE

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
    MODULE_only_approved()
    building_cost_ids.write(building_id, cost)

    return (TRUE)
end

@external
func set_building_cost_values{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt, cost : felt) -> (success : felt):
    MODULE_only_approved()
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
