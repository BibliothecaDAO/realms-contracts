# ____TRAVEL
#   Logic for travel
#   Assets must exist on the same point in space in order to interact with each other.
#
# MIT License

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    get_tx_info,
    get_contract_address,
)

from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.utils.game_structs import TravelInformation, ExternalContractIds, Point
from contracts.settling_game.library.library_module import Module

from contracts.settling_game.modules.travel.library import Travel

###########
# STORAGE #
###########

# @asset_id: ContractId
# @token_id: ContractId
@storage_var
func coordinates(asset_id : felt, token_id : Uint256) -> (point : Point):
end

@storage_var
func travel_information(traveller_asset_id : felt, traveller : Uint256) -> (
    travel_information : TravelInformation
):
end

###############
# CONSTRUCTOR #
###############

# @notice Module initializer
# @param address_of_controller: Controller/arbiter address
# @param xoroshiro_addr: Address of a PRNG contract conforming to IXoroshiro
# @proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt, xoroshiro_addr : felt, proxy_admin : felt
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

############
# EXTERNAL #
############

# @traveller_asset_id: ContractId
# @traveller: Asset moving (Realm, Adventurer)
# @destination_asset_id: ContractId
# @destination: Destination
@external
func travel{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    traveller_asset_id : felt,
    traveller_token_id : Uint256,
    destination_asset_id : felt,
    destination_token_id : Uint256,
):
    alloc_locals

    Module.ERC721_owner_check(traveller_token_id, ExternalContractIds.S_Realms)

    # get travel coordinates
    let (traveller_coordinates : Point) = get_coordinates(traveller_asset_id, traveller_token_id)

    # get destination coordinates
    let (destination_coordinates : Point) = get_coordinates(
        destination_asset_id, destination_token_id
    )

    # get distance between two points
    let (distance) = Travel.calculate_distance(traveller_coordinates, destination_coordinates)

    # calculate time
    let (time) = Travel.calculate_time(distance)

    let (now) = get_block_timestamp()

    # set travel_information
    travel_information.write(
        traveller_asset_id,
        traveller_token_id,
        TravelInformation(destination_asset_id, destination_token_id, now + time),
    )

    return ()
end

###########
# GETTERS #
###########

@view
func get_coordinates{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    asset_id : felt, token_id : Uint256
) -> (point : Point):
    return coordinates.read(asset_id, token_id)
end

@view
func get_travel_information{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    asset_id : felt, token_id : Uint256
) -> (travel_information : TravelInformation):
    return travel_information.read(asset_id, token_id)
end

@view
func assert_arrived{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    asset_id : felt, token_id : Uint256
):
    alloc_locals
    let (now) = get_block_timestamp()
    let (travel_information : TravelInformation) = get_travel_information(asset_id, token_id)

    let (arrived) = is_le(travel_information.travel_time, now)

    if arrived == TRUE:
        return ()
    end

    with_attr error_message("TRAVEL: You have not arrived"):
        assert 0 = TRUE
    end

    return ()
end

#########
# ADMIN #
#########

@external
func set_coordinates{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    asset_id : felt, token_id : Uint256, point : Point
):
    Proxy.assert_only_admin()
    coordinates.write(asset_id, token_id, point)
    return ()
end
