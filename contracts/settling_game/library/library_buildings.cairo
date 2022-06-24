# BUILDINGS LIBRARY
#   functions for
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
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.registers import get_label_location
from contracts.settling_game.utils.game_structs import (
    RealmBuildings,
    RealmBuildingsSize,
    BuildingsIntegrityLength,
    BuildingsDecaySlope,
)
from contracts.settling_game.utils.constants import DAY, BASE_SQM
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_ln

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

        let idx = building_id - 1

        let (type_label) = get_label_location(building_area_sqm)

        return ([type_label + idx])

        building_area_sqm:
        dw RealmBuildingsSize.House  # house
        dw RealmBuildingsSize.StoreHouse  # storehouse
        dw RealmBuildingsSize.Granary  # granary
        dw RealmBuildingsSize.Farm  # farm
        dw RealmBuildingsSize.FishingVillage  # fishing village
        dw RealmBuildingsSize.Barracks  # barracks
        dw RealmBuildingsSize.MageTower  # mage tower
        dw RealmBuildingsSize.ArcherTower  # archer tower
        dw RealmBuildingsSize.Castle  # castle
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
    func get_integrity_length{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        block_timestamp : felt, building_id : felt, quantity : felt
    ) -> (time : felt):
        let idx = building_id - 1

        let (type_label) = get_label_location(building_integrity_length)

        return (block_timestamp + [type_label + idx] * quantity)

        building_integrity_length:
        dw BuildingsIntegrityLength.House  # house
        dw BuildingsIntegrityLength.StoreHouse  # storehouse
        dw BuildingsIntegrityLength.Granary  # granary
        dw BuildingsIntegrityLength.Farm  # farm
        dw BuildingsIntegrityLength.FishingVillage  # fishing village
        dw BuildingsIntegrityLength.Barracks  # barracks
        dw BuildingsIntegrityLength.MageTower  # mage tower
        dw BuildingsIntegrityLength.ArcherTower  # archer tower
        dw BuildingsIntegrityLength.Castle  # castle
    end

    # Gets raw building time left of building on realm. This is only used for precalulations
    func get_base_building_left{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        time_balance : felt, time_stamp : felt
    ) -> (buildings : felt, time_left : felt):
        alloc_locals

        let time_left = time_balance - time_stamp
        # if time is negative return 0 meaning no effective buildings
        let (is_less_than_zero_time) = is_le(time_left, 0)

        if is_less_than_zero_time == TRUE:
            return (0, 0)
        end

        let (buildings_left, _) = unsigned_div_rem(time_left, 10000)

        return (buildings_left, time_left)
    end

    func get_decay_slope{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        building_id : felt
    ) -> (slope : felt):
        alloc_locals

        let idx = building_id - 1

        let (type_label) = get_label_location(building_decay_slope_bp)

        return ([type_label + idx])

        building_decay_slope_bp:
        dw BuildingsDecaySlope.House  # house
        dw BuildingsDecaySlope.StoreHouse  # storehouse
        dw BuildingsDecaySlope.Granary  # granary
        dw BuildingsDecaySlope.Farm  # farm
        dw BuildingsDecaySlope.FishingVillage  # fishing village
        dw BuildingsDecaySlope.Barracks  # barracks
        dw BuildingsDecaySlope.MageTower  # mage tower
        dw BuildingsDecaySlope.ArcherTower  # archer tower
        dw BuildingsDecaySlope.Castle  # castle
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
    func get_effective_buildings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        time_balance : felt
    ) -> (buildings : felt):
        alloc_locals

        # TODO: log function
        # let (effective_buildings) = Math64x61_ln(time_balance)

        # TODO: REMOVE this should be made redundent in favour of the log but log is not working
        let (buildings_left, _) = unsigned_div_rem(time_balance, 10000)

        return (buildings_left)
    end

    # Effective building time calc
    # This takes in the actual time balance and returns a decayed time
    func get_decayed_building_time{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(time_balance : felt, decay_rate : felt) -> (effective_building_time : felt):
        # Calculate effective building time

        # TODO: Add Max decay to stop overflow
        let (effective_building_time, _) = unsigned_div_rem(
            (10000 - decay_rate) * time_balance, 10000
        )

        return (effective_building_time)
    end

    func calculate_effective_buildings{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(building_id : felt, time_balance : felt, block_timestamp : felt) -> (
        effective_buildings : felt
    ):
        alloc_locals

        let (base_building_number, time_left) = get_base_building_left(
            time_balance, block_timestamp
        )

        let (decay_slope) = get_decay_slope(building_id)

        # pass slope determined by building
        let (decay_rate) = get_decay_rate(base_building_number, decay_slope)

        # pass actual time balance + decay rate
        let (effective_building_time) = get_decayed_building_time(time_left, decay_rate)

        let (effective_buildings) = get_effective_buildings(effective_building_time)

        return (effective_buildings)
    end
end
