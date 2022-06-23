# STAKING LIBRARY
#   Helper functions for staking.
#
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.settling_game.utils.game_structs import RealmBuildings
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_ln

# Example Castle time
const CASTLE_RATE = 10000

# Base sqm on a Realm
const BASE_SQM = 25

namespace BUILDINGS:
    # Checks if you can build on a Realm, reverts if you cannot
    func can_build{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt,
        quantity : felt,
        current_buildings : RealmBuildings,
        cities : felt,
        regions : felt,
    ):
        alloc_locals

        with_attr error_message("BUILDINGS: Ser, you must build more than 0 buildings"):
            assert_nn(quantity)
        end

        # Get total buildable units on Realm
        let (buildable_units) = get_realm_buildable_area(cities, regions)

        # Pass current_buildings and return buildable units
        let (current_buildings_sqm) = get_current_built_buildings_sqm(current_buildings)

        # Calculate requested building size
        let (building_size) = get_building_size(building_id)

        with_attr error_message("BUILDINGS: building size greater than buildable area"):
            assert_le(building_size * quantity + current_buildings_sqm, buildable_units)
        end

        return ()
    end

    # gets building size for each
    func get_building_size{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt
    ) -> (buildable_area : felt):
        alloc_locals
        # TODO: Add other buildings sizes
        let castle_size = 10
        # Get buildable units
        return (castle_size)
    end

    # gets buildable area for each
    func get_realm_buildable_area{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(cities : felt, regions : felt) -> (buildable_area : felt):
        # Get buildable units
        return (cities * regions + BASE_SQM)
    end

    # gets current built buildings
    func get_current_built_buildings_sqm{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(current_buildings : RealmBuildings) -> (size : felt):
        # Get buildable units
        # TODO: Loop to calculate current built buildings, hardcoded for now
        let size = 40
        return (size)
    end

    # returns time to add
    func get_final_time{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt, quantity : felt
    ) -> (time : felt):
        let (block_timestamp) = get_block_timestamp()
        let building_time = 2000
        return (block_timestamp + building_time * quantity)
    end

    # Gets raw building time left of building on realm. This is only used for precalulations
    func get_base_building_left{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        time_balance : felt
    ) -> (buildings : felt):
        alloc_locals

        let (buildings_left, _) = unsigned_div_rem(time_balance, 100)

        return (buildings_left)
    end

    func get_decay_slope{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt
    ) -> (slope : felt):
        alloc_locals

        # TODO: set buildings slopes
        let slope = 400

        return (slope)
    end

    # Returns decay rate in bp
    # you must convert to float in order to use
    func get_decay_rate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        buildings_left : felt, decay_slope : felt
    ) -> (decay_rate : felt):
        # divide time left by building decay time
        return (decay_slope * buildings_left)
    end

    # Gets effective buildings on Realm
    func get_effective_building_left{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(time_balance : felt) -> (buildings : felt):
        alloc_locals

        # TODO: log function
        # let (effective_buildings) = Math64x61_ln(time_balance)

        # TODO: REMOVE this should be made redundent in favour of the log but log is not working
        let (buildings_left) = get_base_building_left(time_balance)

        return (buildings_left)
    end

    # Effective building time calc
    # This takes in the actual time balance and returns a decayed time
    func get_effective_building_time{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(time_balance : felt, decay_rate : felt) -> (current_actual_time : felt):
        # Calculate effective building time

        # TODO: Add Max decay to stop overflow
        let (current_actual_time, _) = unsigned_div_rem((10000 - decay_rate) * time_balance, 10000)

        return (current_actual_time)
    end

    func calculate_effective_buildings{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(building_id : felt, time_balance : felt) -> (effective_buildings : felt):
        alloc_locals

        let (base_building_number) = get_base_building_left(time_balance)

        let (decay_slope) = get_decay_slope(1)

        # pass slope determined by building
        let (decay_rate) = get_decay_rate(base_building_number, decay_slope)

        # pass actual time balance + decay rate
        let (effective_building_time) = get_effective_building_time(time_balance, decay_rate)

        let (buildings_left) = get_effective_building_left(effective_building_time)

        return (buildings_left)
    end
end
