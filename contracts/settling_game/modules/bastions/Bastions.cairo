// -----------------------------------
//   Module.Bastions
//   Logic around Bastions

// ELI5:
//      The module allows armies of enemy orders to go to war against each other on new locations
//      called Bastions. These bastions are situated on the border between orders and are composed
//      of 1 central square, 4 towers and 1 staging area. The staging area is the default location
//      when an army travels to the bastion, it’s a safe space where no armies can get attacked.
//      After arriving on the staging area, armies can then move to different locations.
//      The towers are locations where combat can happen, and they can be conquered when all armies
//      of the location’s defending order are annihilated. The central square can only be reached
//      by an order who was conquered all 4 towers. An order holding the central square will receive bonuses.
//
// Moving Time:
//      We explicitely use "move" instead of "travel" in order to differentiate with the Travel Module.
//      Armies can move between locations in the bastion, but each move takes a different number of blocks
//      depending on the distance. In order to tackle this in the contract, we use the concept of "settled"
//      vs "unsettled" armies. When armies move using the "bastion_move" entrypoint, the arrival block is
//      stored in the current_movers storage_var. These armies are considered "unsettled", meaning that the
//      contract does not know yet if they have arrived or not. Only when new armies use "bastion_move" does
//      the contract verify which armies have arrived and updates a counter storage_var containing the number
//      of armies present on a location.

// MIT License
// -----------------------------------

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_not_zero, is_le
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_le,
    assert_not_equal,
    split_felt,
    unsigned_div_rem,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_number
from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.utils.game_structs import ExternalContractIds, Point, ModuleIds
from contracts.settling_game.modules.bastions.constants import MovingTimes
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.modules.combat.library import Combat
from contracts.settling_game.modules.bastions.library import Bastions
from contracts.settling_game.interfaces.IRealms import IRealms
from contracts.settling_game.modules.travel.interface import ITravel
from contracts.settling_game.modules.travel.library import Travel
from contracts.desiege.game_utils.grid_position import pack_position

from contracts.settling_game.modules.combat.interface import ICombat

// -----------------------------------
// Structs
// -----------------------------------

struct MoverData {
    arrival_block: felt,
    number_of_armies: felt,
}

struct ArmyLocationData {
    arrival_block: felt,
    location: felt,
}

// -----------------------------------
// Events
// -----------------------------------

// Emited every time an army moves from one location to another
@event
func BastionArmyMoved(
    point: Point,
    previous_location: felt,
    next_location: felt,
    arrival_block: felt,
    realm_id: Uint256,
    army_id: felt,
) {
}

// Emited every time a location is taken by a new order
@event
func BastionLocationTaken(point: Point, location: felt, order: felt, cooldown_end: felt) {
}

// -----------------------------------
// Storage
// -----------------------------------

// Bonus type of each bastion
@storage_var
func bastion_bonus_type(point: Point) -> (bonus_type: felt) {
}

// Moving times between locations of a Bastion
// @dev Set when deploying the contract
@storage_var
func bastion_moving_times(move_type: felt) -> (block_time: felt) {
}

// Number of blocks that a location takes to cooldown when invaded by a new order
// @dev Set when deploying the contract
@storage_var
func bastion_location_cooldown_period(location: felt) -> (cooldown_period: felt) {
}

// End period of cooldown for each location of each bastion, set when an order invades a location
@storage_var
func bastion_location_cooldown_end(point: Point, location: felt) -> (end_block: felt) {
}

// Track the number of movers that have not been "settled" yet.
@storage_var
func current_movers(point: Point, location: felt, order: felt, index: felt) -> (
    mover_data: MoverData
) {
}

// Number of armies per order on one location that have arrived and whose arrival_block has been verified by the contract
@storage_var
func bastion_location_order_count(point: Point, location: felt, order: felt) -> (count: felt) {
}

// Defending order of a location
@storage_var
func bastion_location_defending_order(point: Point, location: felt) -> (order: felt) {
}

// Location and arrival block of an army
@storage_var
func bastion_army_location(realm_id: Uint256, army_id: felt) -> (
    army_location_data: ArmyLocationData
) {
}

// -----------------------------------
// Initialize & upgrade
// -----------------------------------

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @return proxy_admin: Proxy admin address
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

// @notice Creates bastions on given coordinates
// @param: points_len
// @param: points: Array of coordinates for each bastion
// @param: bonus_types_len
// @param: bonus_types: Array of bonus_types for each bastion
// @param: grid_dimension
@external
func spawn_bastions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    points_len: felt,
    points: Point*,
    bonus_types_len: felt,
    bonus_types: felt*,
    grid_dimension: felt,
) -> () {
    Proxy.assert_only_admin();
    assert points_len = bonus_types_len;
    loop_bastions(points_len, points, bonus_types_len, bonus_types, grid_dimension, 0);

    return ();
}

// @notice Takes location when there are no defenders on the location
// @param point: Coordinates of the bastion
// @param location: Location inside the bastion
// @param realm_id: Realm ID
// @param army_id: Army ID
@external
func bastion_take_location{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    point: Point, location: felt, realm_id: Uint256, army_id: felt
) {
    alloc_locals;
    Module.ERC721_owner_check(realm_id, ExternalContractIds.S_Realms);

    // Check that location is between 1 and 5 included
    with_attr error_message("Bastions: invalid location") {
        assert [range_check_ptr] = location - 1;
        assert [range_check_ptr + 1] = 5 - location;
        let range_check_ptr = range_check_ptr + 2;
    }

    // verify that there is a bastion there
    with_attr error_message("Bastions: No bastion as this location") {
        let (bonus_type) = bastion_bonus_type.read(point);
        assert_not_zero(bonus_type);
    }

    // verify that the army_id is at bastion coordinates
    let (travel_address) = Module.get_module_address(ModuleIds.Travel);
    let (army_coordinates) = ITravel.get_coordinates(
        travel_address, ExternalContractIds.S_Realms, realm_id, army_id
    );
    Travel.assert_same_points(army_coordinates, point);

    // get location and arrival block
    let (army_location_data) = bastion_army_location.read(realm_id, army_id);
    let (current_block) = get_block_number();

    // verify that the army is at right location in the bastion and not moving
    with_attr error_message("Bastions: army is not at right location") {
        assert army_location_data.location = location;
        assert_le(army_location_data.arrival_block, current_block);
    }

    // verify cooldown
    let (cooldown_end_block) = bastion_location_cooldown_end.read(point, location);
    with_attr error_message("Bastion: the cooldown period has not passed yet") {
        assert_le(cooldown_end_block, current_block);
    }

    // fetch realms data to retrieve the order
    let (realm_contract_address) = Module.get_external_contract_address(ExternalContractIds.Realms);
    let (realms_data) = IRealms.fetch_realm_data(realm_contract_address, realm_id);
    let order = realms_data.order;

    // get location defending order
    let (defending_order) = bastion_location_defending_order.read(point, location);
    let has_defending_order = is_not_zero(defending_order);

    // if has defending order, asset that no defending armies are there
    if (has_defending_order == TRUE) {
        with_attr error_message("Bastions: Army order is already defending order") {
            assert_not_equal(order, defending_order);
        }

        // check that the defending order does not have any more troops there
        let (order_count) = bastion_location_order_count.read(point, location, defending_order);

        // max moving time would be to go from tower gate to central square through an opposite tower
        let (d1) = bastion_moving_times.read(MovingTimes.DistanceGateGate);
        let (d2) = bastion_moving_times.read(MovingTimes.DistanceTowerCentralSquare);
        let max_moving_time = 2 * d1 + 2;

        // verify if there is at least one settled army
        with_attr error_message("Bastions: There are still settled defenders in the location") {
            assert order_count = 0;
        }

        // verify if there is at least one unsettled army
        let (found) = find_one_arrived_army(
            point, location, defending_order, current_block, 0, max_moving_time
        );
        with_attr error_message("Bastions: There are still unsettled defenders in the location") {
            assert found = FALSE;
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    // update cooldown period
    let (cooldown_period) = bastion_location_cooldown_period.read(location);
    let cooldown_end = current_block + cooldown_period;
    bastion_location_cooldown_end.write(point, location, cooldown_end);

    // update defending order
    bastion_location_defending_order.write(point, location, order);

    // emit event
    BastionLocationTaken.emit(point, location, order, cooldown_end);

    return ();
}

// @notice Attacks an army on the bastion and takes the location if attacked army
// @notice is killed and was last of the defending order
// @param point: Coordinates of the bastion
// @param attacking_realm_id: Attacking realm ID
// @param attacking_army_id: Attacking army ID
// @param defending_realm_id: Defending realm ID
// @param defending_army_id: Defending army ID
@external
func bastion_attack{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    point: Point,
    attacking_realm_id: Uint256,
    attacking_army_id: felt,
    defending_realm_id: Uint256,
    defending_army_id: felt,
) -> () {
    alloc_locals;

    // before battle
    // verify that there is a bastion there
    let (bonus_type) = bastion_bonus_type.read(point);
    with_attr error_message("Bastions: No bastion on these coordinates") {
        assert_not_zero(bonus_type);
    }

    let (current_block) = get_block_number();

    // arrival block and location of defending army
    let (defender_location_data) = bastion_army_location.read(
        defending_realm_id, defending_army_id
    );

    // verify that the defender is in the bastion
    with_attr error_message("Bastions: Defending army is in staging area") {
        assert_not_zero(defender_location_data.location);
    }
    // verify that the defending army is not moving
    with_attr error_message("Bastions: Defending army has not arrived yet") {
        assert_le(defender_location_data.arrival_block, current_block);
    }

    // arrival block and location of attacking army
    let (attacker_location_data) = bastion_army_location.read(
        attacking_realm_id, attacking_army_id
    );
    // verify that the defender and the attacker are on the same location
    with_attr error_message("Bastions: Attacker and defender not on the same location") {
        assert defender_location_data.location = attacker_location_data.location;
    }
    // verify that the attacking army is not moving
    with_attr error_message("Bastions: Attacking army has not arrived yet") {
        assert_le(attacker_location_data.arrival_block, current_block);
    }

    // fetch realms data to retrieve the attacker and defender order
    let (realm_contract_address) = Module.get_external_contract_address(ExternalContractIds.Realms);
    let (defender_realms_data) = IRealms.fetch_realm_data(
        realm_contract_address, defending_realm_id
    );
    let (attacker_realms_data) = IRealms.fetch_realm_data(
        realm_contract_address, attacking_realm_id
    );

    let (defending_order) = bastion_location_defending_order.read(
        point, defender_location_data.location
    );
    // if attacked army is the defending order, then verify that cooldown has passed
    if (defender_realms_data.order == defending_order) {
        // verify that the cooldown period was passed if you are attacking defending order
        let (cooldown_end_block) = bastion_location_cooldown_end.read(
            point, defender_location_data.location
        );
        with_attr error_message("Bastion: the cooldown period has not passed yet") {
            assert_le(cooldown_end_block, current_block);
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    // Does not verify that the owner is right and order is not the same because already done in combat module
    let (combat_address) = Module.get_module_address(ModuleIds.L06_Combat);

    Module.ERC721_owner_check(attacking_realm_id, ExternalContractIds.S_Realms);
    ICombat.initiate_combat_approved_module(
        combat_address, attacking_army_id, attacking_realm_id, defending_army_id, defending_realm_id
    );

    // get army data to get army population
    let (defending_army_data) = ICombat.get_realm_army_combat_data(
        combat_address, defending_army_id, defending_realm_id
    );
    let (attacking_army_data) = ICombat.get_realm_army_combat_data(
        combat_address, attacking_army_id, attacking_realm_id
    );
    let defending_army_population = Combat.population_of_army(defending_army_data.packed);
    let attacking_army_population = Combat.population_of_army(attacking_army_data.packed);

    // needed to check if the destroyed army was already settled or not
    let (max_moving_time) = bastion_moving_times.read(MovingTimes.DistanceStagingAreaCentralSquare);

    // update storage in case defender army gets destroyed
    // if no more defenders, the attacker becomes new defending order
    if (defending_army_population == 0) {
        update_storage_destroyed_army(
            point,
            defending_realm_id,
            defending_army_id,
            defender_location_data,
            defender_realms_data.order,
            max_moving_time,
        );

        if (defender_realms_data.order == defending_order) {
            take_location_if_no_more_defenders(
                point,
                defender_location_data.location,
                defending_order,
                attacker_realms_data.order,
                current_block,
                max_moving_time,
            );
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }

        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    // update storage in case attacker army gets destroyed
    if (attacking_army_population == 0) {
        update_storage_destroyed_army(
            point,
            attacking_realm_id,
            attacking_army_id,
            attacker_location_data,
            attacker_realms_data.order,
            max_moving_time,
        );
        // if attacker became new defending order from previous storage update but get destroyed as well
        // then new order becomes 0 (neutral location)
        let (defending_order) = bastion_location_defending_order.read(
            point, defender_location_data.location
        );
        if (attacker_realms_data.order == defending_order) {
            take_location_if_no_more_defenders(
                point,
                defender_location_data.location,
                defending_order,
                0,
                current_block,
                max_moving_time,
            );
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }

        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    return ();
}

// @notice Move inside the bastion
// @param point: Coordinates of the bastion
// @param next_location: Destination of the move
// @param realm_id: Moving realm ID
// @param army_id: Moving army ID
@external
func bastion_move{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    point: Point, next_location: felt, realm_id: Uint256, army_id: felt
) {
    alloc_locals;
    Module.ERC721_owner_check(realm_id, ExternalContractIds.S_Realms);

    with_attr error_message("Bastions: invalid location") {
        // Check that location is between 0 and 5 included
        assert [range_check_ptr] = next_location;
        assert [range_check_ptr + 1] = 5 - next_location;
        let range_check_ptr = range_check_ptr + 2;
    }

    // verify that there is a bastion there
    with_attr error_message("Bastions: No bastion as this location") {
        let (bonus_type) = bastion_bonus_type.read(point);
        assert_not_zero(bonus_type);
    }

    // verify that the defending army_id is at bastion coordinates
    let (travel_address) = Module.get_module_address(ModuleIds.Travel);
    let (army_coordinates) = ITravel.get_coordinates(
        travel_address, ExternalContractIds.S_Realms, realm_id, army_id
    );

    // assert travel
    Travel.assert_same_points(army_coordinates, point);
    ITravel.assert_arrived(travel_address, ExternalContractIds.S_Realms, realm_id, army_id);

    // get army location data (arrival block and location)
    let (army_location_data) = bastion_army_location.read(realm_id, army_id);
    let (current_block) = get_block_number();

    // verify that the defending army is not defending already on that line
    with_attr error_message("Bastions: army is already on this location") {
        assert_not_equal(army_location_data.location, next_location);
    }
    // assert that the army is not currently moving
    with_attr error_message("Bastions: army is currently moving") {
        assert_le(army_location_data.arrival_block, current_block);
    }

    // fetch realms data to retrieve the order
    let (realm_contract_address) = Module.get_external_contract_address(ExternalContractIds.Realms);
    let (realms_data) = IRealms.fetch_realm_data(realm_contract_address, realm_id);
    let order = realms_data.order;

    // calculates how many block it takes to go to next location
    // asserts that move is valid as well
    let (block_time) = get_move_block_time(
        point, army_location_data.location, next_location, order
    );

    // retrieves the biggest travel distance in number of blocks
    let (max_moving_time) = bastion_moving_times.read(MovingTimes.DistanceStagingAreaCentralSquare);

    //
    // UPDATE PREVIOUS LOCATION
    //
    let (_, previous_arrival_index) = unsigned_div_rem(
        army_location_data.arrival_block, max_moving_time
    );

    let (previous_loc_mover_data) = current_movers.read(
        point, army_location_data.location, order, previous_arrival_index
    );
    // don't change previous location storage if they were on 0 location (staging area)
    let is_not_on_staging_area = is_not_zero(army_location_data.location);
    if (is_not_on_staging_area == TRUE) {
        if (previous_loc_mover_data.arrival_block == army_location_data.arrival_block) {
            // if true, then army was not settled yet, remove one from there
            current_movers.write(
                point,
                army_location_data.location,
                order,
                previous_arrival_index,
                MoverData(
                    previous_loc_mover_data.arrival_block,
                    previous_loc_mover_data.number_of_armies - 1,
                ),
            );
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            // if false, means army was settled and we can directly decrease location counter
            let (current_location_count) = bastion_location_order_count.read(
                point, army_location_data.location, order
            );
            bastion_location_order_count.write(
                point, army_location_data.location, order, current_location_count - 1
            );
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
    } else {
        // if they are coming from staging area, add the travel restrain from Travel module
        ITravel.forbid_travel(travel_address, ExternalContractIds.S_Realms, realm_id, army_id);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    //
    // UPDATE NEXT LOCATION
    //
    // To update next location we either settle an arrived army by replacing it,
    // don't change next location storage if they go to the 0 (staging area)
    let next_arrival_block = current_block + block_time;
    let (_, next_arrival_index) = unsigned_div_rem(next_arrival_block, max_moving_time);
    let (next_loc_mover_data) = current_movers.read(
        point, next_location, order, next_arrival_index
    );
    let is_not_going_to_staging_area = is_not_zero(next_location);
    if (is_not_going_to_staging_area == TRUE) {
        // if other armies arrive at same block, then there are already armies there, you can add army
        if (next_loc_mover_data.arrival_block == next_arrival_block) {
            current_movers.write(
                point,
                next_location,
                order,
                next_arrival_index,
                MoverData(
                    next_loc_mover_data.arrival_block, next_loc_mover_data.number_of_armies + 1
                ),
            );
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            // if dont arrive at same block, means previous armies already arrived
            // you need to settle them by replacing them and adding the number_of_armies to the location counter
            current_movers.write(
                point, next_location, order, next_arrival_index, MoverData(next_arrival_block, 1)
            );
            let (next_location_count) = bastion_location_order_count.read(
                point, next_location, order
            );
            bastion_location_order_count.write(
                point,
                next_location,
                order,
                next_location_count + next_loc_mover_data.number_of_armies,
            );
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
    } else {
        // if they are going to staging area, remove the travel restrain from Travel module
        // TODO: this allows armies to go out of the bastion before having to wait to arrive at staging area
        ITravel.allow_travel(travel_address, ExternalContractIds.S_Realms, realm_id, army_id);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    bastion_army_location.write(
        realm_id, army_id, ArmyLocationData(next_arrival_block, next_location)
    );
    // emit event
    BastionArmyMoved.emit(
        point, army_location_data.location, next_location, next_arrival_block, realm_id, army_id
    );
    return ();
}

// -----------------------------------
// Internals
// -----------------------------------

// @notice Updates the storage when an army is fully destroyed
// @dev The updates include removing the army from the location counter, the current_movers,
// @dev allowing the army to travel again
// @param point: Coordinates of the bastion
// @param destroyed_realm_id: Destroyed realm ID
// @param destroyed_army_id: Destroyed army ID
// @param destroyed_army_loc_data: Location data of the destroyed army ID
// @param destroyed_army_order: Order of the destroyed army ID
// @param max_moving_time: The maximum distance in number of blocks
func update_storage_destroyed_army{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    point: Point,
    destroyed_realm_id: Uint256,
    destroyed_army_id: felt,
    destroyed_army_loc_data: ArmyLocationData,
    destroyed_army_order: felt,
    max_moving_time: felt,
) -> () {
    alloc_locals;
    let (defending_location_order) = bastion_location_defending_order.read(
        point, destroyed_army_loc_data.location
    );
    let (current_location_count) = bastion_location_order_count.read(
        point, destroyed_army_loc_data.location, destroyed_army_order
    );

    //
    // REMOVE DESTROYED ARMY FROM STORAGE
    //
    let (_, previous_arrival_index) = unsigned_div_rem(
        destroyed_army_loc_data.arrival_block, max_moving_time
    );

    let (previous_loc_mover_data) = current_movers.read(
        point, destroyed_army_loc_data.location, destroyed_army_order, previous_arrival_index
    );

    local new_count;
    // verifies if the destroyed army was settled or not
    if (previous_loc_mover_data.arrival_block == destroyed_army_loc_data.arrival_block) {
        let has_armies = is_not_zero(previous_loc_mover_data.number_of_armies);
        // if has armies with same arrival_block => army was not settled
        // can remove 1 from the number_of_movers
        if (has_armies == TRUE) {
            current_movers.write(
                point,
                destroyed_army_loc_data.location,
                destroyed_army_order,
                previous_arrival_index,
                MoverData(
                    previous_loc_mover_data.arrival_block,
                    previous_loc_mover_data.number_of_armies - 1,
                ),
            );
            new_count = current_location_count;
        } else {
            new_count = current_location_count - 1;
            bastion_location_order_count.write(
                point, destroyed_army_loc_data.location, destroyed_army_order, new_count
            );
        }
    } else {
        // if != arrival block, army was settled, can remove it from the counter directly
        new_count = current_location_count - 1;
        bastion_location_order_count.write(
            point, destroyed_army_loc_data.location, destroyed_army_order, new_count
        );
    }

    // reset bastion location of destroyed army to 0
    bastion_army_location.write(
        destroyed_realm_id,
        destroyed_army_id,
        ArmyLocationData(destroyed_army_loc_data.arrival_block, 0),
    );

    let (travel_address) = Module.get_module_address(ModuleIds.Travel);

    // allow destroyed army_id to travel again because it is not in bastion anymore
    ITravel.allow_travel(
        travel_address, ExternalContractIds.S_Realms, destroyed_realm_id, destroyed_army_id
    );

    // DISCUSS: set the army back to its realm when dead
    // set coordinates back to 0
    ITravel.reset_coordinates(
        contract_address=travel_address,
        contract_id=ExternalContractIds.S_Realms,
        token_id=destroyed_realm_id,
        nested_id=destroyed_army_id,
    );

    return ();
}

// @notice Verifies if there are any defenders left, if not then takes the location
// @param point: Coordinates of the bastion
// @param location: Location inside the bastion
// @param defending_order: The current defending order
// @param new_order: The new order if no more armies in current order
// @param current_block: The current block
// @param max_moving_time: The maximum distance in number of blocks
func take_location_if_no_more_defenders{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    point: Point,
    location,
    defending_order: felt,
    new_order: felt,
    current_block: felt,
    max_moving_time: felt,
) -> () {
    let (defender_count) = bastion_location_order_count.read(point, location, defending_order);
    // search for other defenders and take location if none
    if (defender_count == 0) {
        let (found) = find_one_arrived_army(
            point, location, defending_order, current_block, 0, max_moving_time
        );

        if (found == FALSE) {
            // if no other defending army found, take bastion
            let (cooldown_period) = bastion_location_cooldown_period.read(location);
            let cooldown_end = current_block + cooldown_period;
            bastion_location_cooldown_end.write(point, location, cooldown_end);
            bastion_location_defending_order.write(point, location, new_order);
            // emit event
            BastionLocationTaken.emit(point, location, new_order, cooldown_end);

            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        // cannot take the bastion
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    return ();
}

// @notice Returns TRUE if it found at least one army that has arrived in the current movers
// @param point: Coordinates of the bastion
// @param location: Location inside the bastion
// @param order: The order for which we look for an army
// @param current_block: The current block
// @param index: The index for the recursion
// @param max_index: The highest index (here the biggest travel distance in blocks)
// @return found: True if there was at least one arrived army in the current_movers
func find_one_arrived_army{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    point: Point, location: felt, order: felt, current_block: felt, index: felt, max_index: felt
) -> (found: felt) {
    if (index == max_index) {
        return (FALSE,);
    }

    let (mover_data) = current_movers.read(point, location, order, index);
    let has_passed = is_le(mover_data.arrival_block, current_block);
    if (has_passed == TRUE) {
        if (mover_data.number_of_armies == 0) {
            return find_one_arrived_army(
                point, location, order, current_block, index + 1, max_index
            );
        } else {
            return (TRUE,);
        }
    } else {
        return find_one_arrived_army(point, location, order, current_block, index + 1, max_index);
    }
}

// TODO: add a way to forbid armies in the central square to flee the bastion
// when towers are taken by ennemy order, but still letting them attack towers
// @notice Calculates the time in block to arrive to destination
// @param point: Coordinates of the bastion
// @param current_location: The current location of the army
// @param next_location: The next location of the army
// @param mover_order: The order of the moving army
// @return block_time: The number of blocks to arrive to destination
func get_move_block_time{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    point: Point, current_location: felt, next_location: felt, mover_order: felt
) -> (block_time: felt) {
    alloc_locals;
    let (current_location_defender) = bastion_location_defending_order.read(
        point, current_location
    );
    let (next_location_defender) = bastion_location_defending_order.read(point, next_location);

    let (tower_1_defending_order) = bastion_location_defending_order.read(point, 1);
    let (tower_2_defending_order) = bastion_location_defending_order.read(point, 2);
    let (tower_3_defending_order) = bastion_location_defending_order.read(point, 3);
    let (tower_4_defending_order) = bastion_location_defending_order.read(point, 4);

    let (local number_of_conquered_towers) = Bastions.number_of_conquered_towers(
        mover_order,
        tower_1_defending_order,
        tower_2_defending_order,
        tower_3_defending_order,
        tower_4_defending_order,
    );
    // location 5 = central square
    if (next_location == 5) {
        // if mover order is the same as the central square defending order
        if (next_location_defender == mover_order) {
            with_attr error_message(
                    "Bastions: Central square defending order needs to have at least one tower") {
                assert_le(1, number_of_conquered_towers);
            }
            if (current_location == 0) {
                let (moving_time) = bastion_moving_times.read(
                    MovingTimes.DistanceStagingAreaCentralSquare
                );
            } else {
                // towers
                // if not 0, it has to be one of the towers because i already know hes not on location 5
                if (current_location_defender == mover_order) {
                    let (moving_time) = bastion_moving_times.read(
                        MovingTimes.DistanceTowerCentralSquare
                    );
                } else {
                    let (distance_gate_tower) = bastion_moving_times.read(
                        MovingTimes.DistanceGateTower
                    );
                    let (distance_tower_cs) = bastion_moving_times.read(
                        MovingTimes.DistanceTowerCentralSquare
                    );
                    // if you are on a tower gate, you need to through the closest tower
                    // you need to go through a tower to enter CS but you don't need to go through a tower to exit
                    let (moving_time) = Bastions.find_shortest_path_from_tower_to_central_square(
                        mover_order,
                        current_location,
                        tower_1_defending_order,
                        tower_2_defending_order,
                        tower_3_defending_order,
                        tower_4_defending_order,
                        distance_gate_tower,
                        distance_tower_cs,
                    );
                }
            }
        } else {
            // if not the same order as the central square defending order, need to verify
            // that all towers are taken
            with_attr error_message("Bastions: Need to conquer all towers") {
                assert number_of_conquered_towers = 4;
            }
            // if conquered all towers, they can go to the central square
            if (current_location == 0) {
                let (moving_time) = bastion_moving_times.read(
                    MovingTimes.DistanceStagingAreaCentralSquare
                );
            } else {
                let (moving_time) = bastion_moving_times.read(MovingTimes.DistanceTowerInnerGate);
            }
        }
    } else {
        // if you are moving to staging area
        if (next_location == 0) {
            // if you are on central square
            if (current_location == 5) {
                if (current_location_defender == mover_order) {
                    let (moving_time) = bastion_moving_times.read(
                        MovingTimes.DistanceStagingAreaCentralSquare
                    );
                } else {
                    with_attr error_message(
                            "Bastions: attacker cannot move out of inner gate if does not hold all 4 towers") {
                        assert number_of_conquered_towers = 4;
                    }
                    let (moving_time) = bastion_moving_times.read(
                        MovingTimes.DistanceStagingAreaCentralSquare
                    );
                }
            } else {
                // you are on a tower
                let (moving_time) = bastion_moving_times.read(MovingTimes.DistanceStagingAreaTower);
            }
        } else {
            // if you are moving to towers
            // if you move from staging area to towers
            if (current_location == 0) {
                let (moving_time) = bastion_moving_times.read(MovingTimes.DistanceStagingAreaTower);
            } else {
                // you can only move to adjacent towers
                if (current_location == 5) {
                    // CS defender can move as he wants
                    if (next_location_defender == mover_order) {
                        if (current_location_defender == mover_order) {
                            let (moving_time) = bastion_moving_times.read(
                                MovingTimes.DistanceTowerCentralSquare
                            );
                        } else {
                            // attackers can only move from CS if all towers are taken
                            with_attr error_message(
                                    "Bastions: attacker cannot move out of inner gate if does not hold all 4 towers") {
                                assert number_of_conquered_towers = 4;
                            }
                            let (moving_time) = bastion_moving_times.read(
                                MovingTimes.DistanceTowerInnerGate
                            );
                        }
                    } else {
                        with_attr error_message(
                                "Bastions: attacker cannot move out of inner gate if does not hold all 4 towers") {
                            assert current_location_defender = mover_order;
                        }
                        let (moving_time) = bastion_moving_times.read(
                            MovingTimes.DistanceTowerInnerGate
                        );
                    }
                } else {
                    // going from tower to tower
                    let (is_adjacent_tower) = Bastions.is_adjacent_tower(
                        current_location, next_location
                    );
                    // TODO: maybe in the future add a way to move to non adjacent tower
                    with_attr error_message(
                            "Bastions: Can only move from tower to adjacent tower") {
                        assert is_adjacent_tower = TRUE;
                    }
                    // if you move from your order tower to another of your order tower
                    if (next_location_defender == mover_order) {
                        if (current_location_defender == mover_order) {
                            let (moving_time) = bastion_moving_times.read(
                                MovingTimes.DistanceTowerTower
                            );
                        } else {
                            let (moving_time) = bastion_moving_times.read(
                                MovingTimes.DistanceGateTower
                            );
                        }
                    } else {
                        if (current_location_defender == mover_order) {
                            let (moving_time) = bastion_moving_times.read(
                                MovingTimes.DistanceGateTower
                            );
                        } else {
                            let (moving_time) = bastion_moving_times.read(
                                MovingTimes.DistanceGateGate
                            );
                        }
                    }
                }
            }
        }
    }
    return (moving_time,);
}

// @notice Loops over array and sets bastion in storage
// @param points_len
// @param points: Array of coordinates for each bastion
// @param bonus_types_len
// @param bonus_types: Array of bonus_types for each bastion
// @param grid_dimension
// @param index: index for recursion
func loop_bastions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    points_len: felt,
    points: Point*,
    bonus_types_len: felt,
    bonus_types: felt*,
    grid_dimension: felt,
    index: felt,
) -> () {
    if (index == points_len) {
        return ();
    } else {
        bastion_bonus_type.write(points[index], bonus_types[index]);
    }

    // use the coordinates as ID for the bastion
    // because can only have one bastion per coordinate
    let (bastion_id) = pack_position(grid_dimension, points[index].x, points[index].y);
    let (bastion_id_high, bastion_id_low) = split_felt(bastion_id);

    let (travel_address) = Module.get_module_address(ModuleIds.Travel);
    // set the coordinates with the travel module
    ITravel.set_coordinates(
        contract_address=travel_address,
        contract_id=ModuleIds.Bastions,
        token_id=Uint256(bastion_id_low, bastion_id_high),
        nested_id=0,
        point=points[index],
    );

    loop_bastions(points_len, points, bonus_types_len, bonus_types, grid_dimension, index + 1);

    return ();
}

// -----------------------------------
// Setters
// -----------------------------------

@external
func set_bastion_location_cooldown{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    bastion_cooldown_: felt, location: felt
) -> () {
    Proxy.assert_only_admin();
    bastion_location_cooldown_period.write(location, bastion_cooldown_);
    return ();
}

@external
func set_bastion_bonus_type{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    point: Point, bonus_type: felt
) -> () {
    Proxy.assert_only_admin();
    bastion_bonus_type.write(point, bonus_type);
    return ();
}

@external
func set_bastion_moving_times{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    move_type: felt, block_time: felt
) -> () {
    Proxy.assert_only_admin();
    bastion_moving_times.write(move_type, block_time);
    return ();
}

// -----------------------------------
// Getters
// -----------------------------------

@view
func get_bastion_location_defending_order{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(point: Point, location: felt) -> (defending_order: felt) {
    let (defending_order) = bastion_location_defending_order.read(point, location);
    return (defending_order,);
}

// @dev You can use this to identify when an order has taken a Bastion so that you can
// @dev distribute the bonus accordingly
@view
func get_bastion_location_cooldown_end{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(point: Point, location: felt) -> (cooldown_end: felt) {
    let (cooldown_end) = bastion_location_cooldown_end.read(point, location);
    return (cooldown_end,);
}

@view
func get_bastion_bonus_type{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    point: Point
) -> (bonus_type: felt) {
    let (bonus_type) = bastion_bonus_type.read(point);
    return (bonus_type,);
}
