// ____TRAVEL
//   Logic for travel
//   Assets must exist on the same point in space in order to interact with each other.
//   Assets have nested selectors allowing (n) number of potential assets to spawn from a single asset.
// MIT License

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le, is_nn
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp

from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.utils.game_structs import TravelInformation, ExternalContractIds, Point
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.modules.travel.library import Travel

// -----------------------------------
// Events
// -----------------------------------

// @notice Event fires on every movement of an Asset/Army
// @param traveller_nested_id: This exists for nested units within the token. Eg: An Army.
//        If the asset has no nested ID, then this will be 0.
// @param traveller_contract_id: Traveller contract ID of asset
// @param traveller_token_id: Traveller token_id (Actual NFT ID)
// @param destination_contract_id: Destination contract id
// @param destination_token_id: Destination token_id (Actual NFT ID)
// @param arrival_time: Arrival time in unix
@event
func TravelAction(
    traveller_contract_id: felt,
    traveller_token_id: Uint256,
    traveller_nested_id: felt,
    destination_contract_id: felt,
    destination_token_id: Uint256,
    destination_nested_id: felt,
    arrival_time: felt,
) {
}

// -----------------------------------
// Storage
// -----------------------------------

// @asset_id: ContractId
// @token_id: TokenID
// @nested_asset_id: NestedID
@storage_var
func coordinates(asset_id: felt, token_id: Uint256, nested_asset_id: felt) -> (point: Point) {
}

// @traveller_contract_id: ContractId
// @traveller: TokenID
// @traveller_nested_id: NestedID
@storage_var
func travel_information(
    traveller_contract_id: felt, traveller: Uint256, traveller_nested_id: felt
) -> (travel_information: TravelInformation) {
}

// -----------------------------------
// Initialize & upgrade
// -----------------------------------

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address_of_controller: felt, proxy_admin: felt
) {
    Module.initializer(address_of_controller);
    Proxy.initializer(proxy_admin);
    return ();
}

// @notice Set new proxy implementation
// @dev Can only be set by the arbiter
// @param new_implementation: New implementation contract address
@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

// -----------------------------------
// External
// -----------------------------------

// @traveller_contract_id: External contract ID -> keeping the same for consistency
// @traveller_token_id: Asset token ID moving (Realm, Adventurer)
// @traveller_nested_id: Nested asset ID (Armies, persons etc)
// @destination_contract_id: ContractId
// @destination_token_id: Destination token ID
// @destination_nested_id: Nested asset ID (Armies, persons etc)
@external
func travel{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    traveller_contract_id: felt,
    traveller_token_id: Uint256,
    traveller_nested_id: felt,
    destination_contract_id: felt,
    destination_token_id: Uint256,
    destination_nested_id: felt,
) {
    alloc_locals;

    // TODO: assert is correct ID (can't try move unmoveable assets)

    // You cannot move nested asset ID 0 - this is the actual location.
    let is_not_defending_army = is_nn(traveller_nested_id);
    with_attr error_message("Combat: You cannot move your Defending Army") {
        assert is_not_defending_army = TRUE;
    }

    Module.ERC721_owner_check(traveller_token_id, traveller_contract_id);

    // check has arrived
    assert_arrived(traveller_contract_id, traveller_token_id, traveller_nested_id);

    // get travel coordinates
    let (traveller_coordinates: Point) = get_coordinates(
        traveller_contract_id, traveller_token_id, traveller_nested_id
    );

    // if no current location set, use the home coordinates
    if (traveller_coordinates.x == 0) {
        let (traveller_coordinates: Point) = get_coordinates(
            traveller_contract_id, traveller_token_id, 0
        );
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }

    tempvar traveller_coordinates = traveller_coordinates;

    // get destination coordinates
    let (destination_coordinates: Point) = get_coordinates(
        destination_contract_id, destination_token_id, destination_nested_id
    );

    // calculate time
    let (time) = get_travel_time(traveller_coordinates, destination_coordinates);

    // set travel_information
    travel_information.write(
        traveller_contract_id,
        traveller_token_id,
        traveller_nested_id,
        TravelInformation(destination_contract_id, destination_token_id, destination_nested_id, time),
    );

    // emit event
    TravelAction.emit(
        traveller_contract_id,
        traveller_token_id,
        traveller_nested_id,
        destination_contract_id,
        destination_token_id,
        destination_nested_id,
        time,
    );

    return ();
}

// -----------------------------------
// Getters
// -----------------------------------

@view
func get_coordinates{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_id: felt, token_id: Uint256, nested_id: felt
) -> (point: Point) {
    return coordinates.read(contract_id, token_id, nested_id);
}

@view
func get_travel_information{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_id: felt, token_id: Uint256, nested_id: felt
) -> (travel_information: TravelInformation) {
    return travel_information.read(contract_id, token_id, nested_id);
}

@view
func get_arrival_time{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    traveller_coordinates: Point, destination_coordinates: Point
) -> (time: felt) {
    // get distance between two points
    let (distance) = get_travel_distance(traveller_coordinates, destination_coordinates);

    // calculate time
    let (time) = Travel.calculate_time(distance);

    let (now) = get_block_timestamp();

    return (time + now,);
}

@view
func get_travel_time{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    traveller_coordinates: Point, destination_coordinates: Point
) -> (time: felt) {
    // get distance between two points
    let (distance) = get_travel_distance(traveller_coordinates, destination_coordinates);

    // calculate time
    let (time) = Travel.calculate_time(distance);

    return (time,);
}

@view
func get_travel_distance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    traveller_coordinates: Point, destination_coordinates: Point
) -> (distance: felt) {
    // get distance between two points
    let (distance) = Travel.calculate_distance(traveller_coordinates, destination_coordinates);

    return (distance,);
}

@view
func assert_arrived{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_id: felt, token_id: Uint256, nested_id: felt
) {
    alloc_locals;
    let (now) = get_block_timestamp();
    let (travel_information: TravelInformation) = get_travel_information(
        contract_id, token_id, nested_id
    );

    let arrived = is_le(travel_information.travel_time, now);

    with_attr error_message("TRAVEL: You are mid travel. You cannot change course!") {
        assert arrived = TRUE;
    }

    return ();
}

@view
func assert_traveller_is_at_location{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    traveller_contract_id: felt,
    traveller_token_id: Uint256,
    traveller_nested_id: felt,
    destination_contract_id: felt,
    destination_token_id: Uint256,
    destination_nested_id: felt,
) {
    alloc_locals;

    // check traveller has arrived
    assert_arrived(traveller_contract_id, traveller_token_id, traveller_nested_id);

    // get traveller information
    let (traveller_information: TravelInformation) = get_travel_information(
        traveller_contract_id, traveller_token_id, traveller_nested_id
    );

    // get coordinates of travellers destination
    let (traveller_destination) = get_coordinates(
        traveller_information.destination_asset_id,
        traveller_information.destination_token_id,
        traveller_information.destination_nested_asset_id,
    );

    // get requested destination coordinates
    let (destination) = get_coordinates(
        destination_contract_id, destination_token_id, destination_nested_id
    );

    // assert travellers destination and requested information is the same
    Travel.assert_same_points(traveller_destination, destination);

    return ();
}

// -----------------------------------
// Admin
// -----------------------------------

@external
func set_coordinates{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract_id: felt, token_id: Uint256, nested_id: felt, point: Point
) {
    Proxy.assert_only_admin();
    coordinates.write(contract_id, token_id, nested_id, point);
    return ();
}
