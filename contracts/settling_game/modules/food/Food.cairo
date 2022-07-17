# -----------------------------------
# ____Module.L02___RELIC
#   Logic around Relics
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp

from contracts.settling_game.library.library_module import Module
from contracts.settling_game.utils.constants import BASE_HARVESTS, BASE_FOOD_PRODUCTION
from contracts.settling_game.utils.game_structs import (
    RealmData,
    ModuleIds,
    ExternalContractIds,
    ResourceIds,
    Cost,
    HarvestType,
)
from contracts.settling_game.modules.food.library import Food
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from openzeppelin.upgrades.library import Proxy
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
# -----------------------------------
# Events
# -----------------------------------

# @storage_var
# func Food(token_id : felt) -> (farms_left : felt, last_harvest : felt):
# end

# -----------------------------------
# Storage
# -----------------------------------

@storage_var
func farms(token_id : Uint256) -> (farms_left : felt):
end

# each farms build can be harvested 10 times
@storage_var
func harvests_left(token_id : Uint256) -> (harvests_left : felt):
end

@storage_var
func last_harvest(token_id : Uint256) -> (last_harvest : felt):
end

# -----------------------------------
# INITIALIZER & UPGRADE
# -----------------------------------

# @notice Module initializer
# @param address_of_controller: Controller/arbiter address
# @proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt, proxy_admin : felt
):
    Module.initializer(address_of_controller)
    Proxy.initializer(proxy_admin)
    return ()
end

# @notice Set new proxy implementation
# @dev Can only be set by the arbiter
# @param new_implementation: New implementation contract address
@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy.assert_only_admin()
    Proxy._set_implementation_hash(new_implementation)
    return ()
end

# -----------------------------------
# EXTERNAL
# -----------------------------------

@external
func create_farm{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, number_farms : felt, food_building_id : felt
):
    alloc_locals
    let (block_timestamp) = get_block_timestamp()
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms)
    let (realm_data) = realms_IERC721.fetch_realm_data(realms_address, token_id)

    # Farm expirary time
    let (time) = Food.create(number_farms, food_building_id, realm_data)
    last_harvest.write(token_id, block_timestamp)

    # save number of farms
    farms.write(token_id, number_farms)

    # save harvests
    harvests_left.write(token_id, BASE_HARVESTS)

    return ()
end

@external
func harvest_farm{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, harvest_type : felt
):
    alloc_locals
    let (block_timestamp) = get_block_timestamp()

    let (plant_time) = last_harvest.read(token_id)

    # Farm expirary time
    let (total_harvest, total_remaining, decayed_farms) = Food.calculate_harvest(
        plant_time, block_timestamp
    )
    let (s_realms_address) = Module.get_external_contract_address(ExternalContractIds.S_Realms)
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources)

    let (owner) = realms_IERC721.ownerOf(s_realms_address, token_id)

    let total_food = total_harvest * BASE_FOOD_PRODUCTION * 10 ** 18

    if harvest_type == HarvestType.Store:
        IERC1155.mint(
            resources_address, owner, Uint256(ResourceIds.wheat, 0), Uint256(total_food, 0)
        )
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        # send to Storehouse
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    # Deducte harvests from total
    # TODO: Check no overflow
    let (current_harvests) = harvests_left.read(token_id)
    harvests_left.write(token_id, current_harvests - total_harvest - decayed_farms)

    return ()
end

@external
func convert_to_store{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, quantity : felt
):
    alloc_locals

    # convert token quantity into time
    # store timestamp in storage

    return ()
end

# Calculate food available

# -----------------------------------
# SETTERS
# -----------------------------------

# -----------------------------------
# GETTERS
# -----------------------------------
