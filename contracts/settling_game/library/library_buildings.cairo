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
from starkware.cairo.common.registers import get_label_location
from contracts.settling_game.utils.game_structs import (
    RealmBuildings,
    RealmBuildingsSize,
    BuildingsTime,
)
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_ln

# Example Castle time

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
    # pass building struct and return sqm
    func get_current_built_buildings_sqm{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(current_buildings : RealmBuildings) -> (size : felt):
        # Get buildable units

        let House = current_buildings.House * RealmBuildingsSize.House
        let StoreHouse = current_buildings.StoreHouse * RealmBuildingsSize.StoreHouse
        let Granary = current_buildings.Granary * RealmBuildingsSize.Granary
        let Farm = current_buildings.Farm * RealmBuildingsSize.Farm
        let FishingVillage = current_buildings.FishingVillage * RealmBuildingsSize.FishingVillage
        let Barracks = current_buildings.Barracks * RealmBuildingsSize.Barracks
        let MageTower = current_buildings.MageTower * RealmBuildingsSize.MageTower
        let ArcherTower = current_buildings.ArcherTower * RealmBuildingsSize.ArcherTower
        let Castle = current_buildings.Castle * RealmBuildingsSize.Castle

        let size = House + StoreHouse + Granary + Farm + FishingVillage + Barracks + MageTower + ArcherTower + Castle

        return (size)
    end

    # returns time to add
    func get_final_time{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        block_timestamp : felt, building_id : felt, quantity : felt
    ) -> (time : felt):
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

        let idx = building_id - 1

        let (type_label) = get_label_location(building_decay_slope_bp)

        return ([type_label + idx])

        building_decay_slope_bp:
        dw 400  # house
        dw 400  # storehouse
        dw 400  # granary
        dw 400  # farm
        dw 400  # fishing village
        dw 400  # barracks
        dw 400  # mage tower
        dw 400  # archer tower
        dw 200  # castle
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

        let (decay_slope) = get_decay_slope(building_id)

        # pass slope determined by building
        let (decay_rate) = get_decay_rate(base_building_number, decay_slope)

        # pass actual time balance + decay rate
        let (effective_building_time) = get_effective_building_time(time_balance, decay_rate)

        let (buildings_left) = get_effective_building_left(effective_building_time)

        return (buildings_left)
    end
end
