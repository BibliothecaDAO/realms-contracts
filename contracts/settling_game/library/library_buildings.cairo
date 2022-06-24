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
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.math import assert_250_bit
from contracts.settling_game.utils.game_structs import (
    RealmBuildings,
    RealmBuildingsSize,
    BuildingsIntegrityLength,
    BuildingsDecaySlope,
    PackedBuildings,
    RealmBuildingsIds,
)
from contracts.settling_game.utils.constants import DAY, BASE_SQM

from contracts.settling_game.utils.general import unpack_data

from contracts.settling_game.utils.constants import SHIFT_25

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

    func findPowLarger{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        base : felt, exp : felt, currVal : felt, target : felt
    ) -> (exp : felt):
        alloc_locals

        # Getting the next power of the base on this iteration

        local newVal = base * currVal

        assert_250_bit(newVal)

        # This handles flooring scenario

        let (isLe) = is_le(newVal, target)

        if isLe == 1:
            return findPowLarger(base, exp + 1, newVal, target)
        end

        # This handles exact match for base ^ exponent = target

        let (isNotEqual) = is_not_zero(newVal - target)

        if isNotEqual == 0:
            return (exp=exp)
        end

        return (exp=exp)
    end

    # Gets effective buildings on Realm
    func get_effective_buildings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        time_balance : felt
    ) -> (buildings : felt):
        alloc_locals

        # TODO: log function
        let (effective_buildings) = findPowLarger(2, 0, 1, time_balance)

        # TODO: REMOVE this should be made redundent in favour of the log but log is not working
        # let (buildings_left, _) = unsigned_div_rem(time_balance, 10000)

        return (time_balance)
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

    func unpack_buildings{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(packed_buildings : PackedBuildings) -> (unpacked_buildings : RealmBuildings):
        alloc_locals

        let (House) = unpack_data(packed_buildings.housing, 0, 2199023255551)
        let (StoreHouse) = unpack_data(packed_buildings.economic, 0, 2199023255551)
        let (Granary) = unpack_data(packed_buildings.economic, 41, 2199023255551)
        let (Farm) = unpack_data(packed_buildings.economic, 82, 2199023255551)
        let (FishingVillage) = unpack_data(packed_buildings.economic, 123, 2199023255551)
        let (Barracks) = unpack_data(packed_buildings.military, 0, 2199023255551)
        let (MageTower) = unpack_data(packed_buildings.military, 41, 2199023255551)
        let (ArcherTower) = unpack_data(packed_buildings.military, 82, 2199023255551)
        let (Castle) = unpack_data(packed_buildings.military, 123, 2199023255551)

        return (
            unpacked_buildings=RealmBuildings(
            House=House,
            StoreHouse=StoreHouse,
            Granary=Granary,
            Farm=Farm,
            FishingVillage=FishingVillage,
            Barracks=Barracks,
            MageTower=MageTower,
            ArcherTower=ArcherTower,
            Castle=Castle,
            ),
        )
    end

    func pack_buildings{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(current_buildings : RealmBuildings, building_id : felt) -> (
        packed_buildings : PackedBuildings
    ):
        alloc_locals

        let (buildings : felt*) = alloc()

        if building_id == RealmBuildingsIds.House:
            local id_1 = (current_buildings.House) * SHIFT_25._1
            buildings[0] = id_1
        else:
            buildings[0] = current_buildings.House * SHIFT_25._1
        end

        if building_id == RealmBuildingsIds.StoreHouse:
            local id_2 = (current_buildings.StoreHouse) * SHIFT_25._1
            buildings[1] = id_2
        else:
            local id_2 = current_buildings.StoreHouse * SHIFT_25._1
            buildings[1] = id_2
        end

        if building_id == RealmBuildingsIds.Granary:
            local id_3 = (current_buildings.Granary) * SHIFT_25._2
            buildings[2] = id_3
        else:
            local id_3 = current_buildings.Granary * SHIFT_25._2
            buildings[2] = id_3
        end

        if building_id == RealmBuildingsIds.Farm:
            local id_4 = (current_buildings.Farm) * SHIFT_25._3
            buildings[3] = id_4
        else:
            local id_4 = current_buildings.Farm * SHIFT_25._3
            buildings[3] = id_4
        end

        if building_id == RealmBuildingsIds.FishingVillage:
            local id_5 = (current_buildings.FishingVillage) * SHIFT_25._4
            buildings[4] = id_5
        else:
            local id_5 = current_buildings.FishingVillage * SHIFT_25._4
            buildings[4] = id_5
        end

        if building_id == RealmBuildingsIds.Barracks:
            local id_6 = (current_buildings.Barracks) * SHIFT_25._1
            buildings[5] = id_6
        else:
            local id_6 = current_buildings.Barracks * SHIFT_25._1
            buildings[5] = id_6
        end

        if building_id == RealmBuildingsIds.MageTower:
            local id_7 = (current_buildings.MageTower) * SHIFT_25._2
            buildings[6] = id_7
        else:
            local id_7 = current_buildings.MageTower * SHIFT_25._2
            buildings[6] = id_7
        end

        if building_id == RealmBuildingsIds.ArcherTower:
            local id_8 = (current_buildings.ArcherTower) * SHIFT_25._3
            buildings[7] = id_8
        else:
            local id_8 = current_buildings.ArcherTower * SHIFT_25._3
            buildings[7] = id_8
        end

        if building_id == RealmBuildingsIds.Castle:
            local id_9 = (current_buildings.Castle) * SHIFT_25._4
            buildings[8] = id_9
        else:
            local id_9 = current_buildings.Castle * SHIFT_25._4
            buildings[8] = id_9
        end

        tempvar housing_value = buildings[0]

        tempvar economic_value = buildings[4] + buildings[3] + buildings[2] + buildings[1]

        tempvar military_value = buildings[8] + buildings[7] + buildings[6] + buildings[5]

        return (
            PackedBuildings(military=military_value, economic=economic_value, housing=housing_value)
        )
    end
end
