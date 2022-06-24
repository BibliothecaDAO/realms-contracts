%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div
from contracts.settling_game.utils.game_structs import (
    BuildingsFood,
    BuildingsPopulation,
    BuildingsCulture,
    RealmBuildings,
    RealmBuildingsIds,
    BuildingsIntegrityLength,
    RealmBuildingsSize,
    BuildingsDecaySlope,
)
from contracts.settling_game.library.library_buildings import BUILDINGS

from tests.settling_game.utils.test_structs import TEST_REALM_BUILDINGS

const BUILDING_QUANTITY = 1
const TEST_REALM_REGIONS = 4
const TEST_REALM_CITIES = 25

const TEST_TIMESTAMP = 1645743897
const TEST_TIME_BALANCE_TIMESTAMP = 1645743897 + 56400

@external
func test_get_building_left{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    # now - timestamp = param
    let (base_building_number, time_left) = BUILDINGS.get_base_building_left(
        TEST_TIME_BALANCE_TIMESTAMP, TEST_TIMESTAMP
    )
    %{ print(ids.base_building_number) %}

    let (decay_slope) = BUILDINGS.get_decay_slope(RealmBuildingsIds.Castle)

    # pass slope determined by building
    let (decay_rate) = BUILDINGS.get_decay_rate(base_building_number, decay_slope)
    %{ print(ids.decay_rate) %}

    # pass actual time balance + decay rate
    let (effective_building_time) = BUILDINGS.get_decayed_building_time(time_left, decay_rate)
    %{ print(ids.effective_building_time) %}

    let (buildings_left) = BUILDINGS.get_effective_buildings(effective_building_time)
    %{ print(ids.buildings_left) %}
    return ()
end

@external
func test_calculate_effective_buildings{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    let (base_building_number) = BUILDINGS.calculate_effective_buildings(
        RealmBuildingsIds.Castle, TEST_TIME_BALANCE_TIMESTAMP, TEST_TIMESTAMP
    )

    %{ print(ids.base_building_number) %}
    return ()
end

@external
func test_get_decay_slope{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (decay_slope) = BUILDINGS.get_decay_slope(RealmBuildingsIds.Castle)

    assert decay_slope = BuildingsDecaySlope.Castle

    return ()
end

@external
func test_get_integrity_length{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (final_time) = BUILDINGS.get_integrity_length(
        TEST_TIMESTAMP, RealmBuildingsIds.Castle, BUILDING_QUANTITY
    )

    assert final_time = BuildingsIntegrityLength.Castle * BUILDING_QUANTITY + TEST_TIMESTAMP

    return ()
end

@external
func test_can_build{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let test_buildings = RealmBuildings(
        TEST_REALM_BUILDINGS.HOUSE,
        TEST_REALM_BUILDINGS.STOREHOUSE,
        TEST_REALM_BUILDINGS.GRANARY,
        TEST_REALM_BUILDINGS.FARM,
        TEST_REALM_BUILDINGS.FISHINGVILLAGE,
        TEST_REALM_BUILDINGS.BARRACKS,
        TEST_REALM_BUILDINGS.MAGETOWER,
        TEST_REALM_BUILDINGS.ARCHERTOWER,
        TEST_REALM_BUILDINGS.CASTLE,
    )

    BUILDINGS.can_build(
        RealmBuildingsIds.Castle,
        BUILDING_QUANTITY,
        test_buildings,
        TEST_REALM_CITIES,
        TEST_REALM_REGIONS,
    )

    return ()
end

@external
func test_building_size{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (building_size) = BUILDINGS.get_building_size(RealmBuildingsIds.Castle)

    assert building_size = RealmBuildingsSize.Castle

    return ()
end

@external
func test_get_current_built_buildings_sqm{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    let test_buildings = RealmBuildings(
        TEST_REALM_BUILDINGS.HOUSE,
        TEST_REALM_BUILDINGS.STOREHOUSE,
        TEST_REALM_BUILDINGS.GRANARY,
        TEST_REALM_BUILDINGS.FARM,
        TEST_REALM_BUILDINGS.FISHINGVILLAGE,
        TEST_REALM_BUILDINGS.BARRACKS,
        TEST_REALM_BUILDINGS.MAGETOWER,
        TEST_REALM_BUILDINGS.ARCHERTOWER,
        TEST_REALM_BUILDINGS.CASTLE,
    )

    let (buildings_sqm) = BUILDINGS.get_current_built_buildings_sqm(test_buildings)

    let House = TEST_REALM_BUILDINGS.HOUSE * RealmBuildingsSize.House
    let StoreHouse = TEST_REALM_BUILDINGS.STOREHOUSE * RealmBuildingsSize.StoreHouse
    let Granary = TEST_REALM_BUILDINGS.GRANARY * RealmBuildingsSize.Granary
    let Farm = TEST_REALM_BUILDINGS.FARM * RealmBuildingsSize.Farm
    let FishingVillage = TEST_REALM_BUILDINGS.FISHINGVILLAGE * RealmBuildingsSize.FishingVillage
    let Barracks = TEST_REALM_BUILDINGS.BARRACKS * RealmBuildingsSize.Barracks
    let MageTower = TEST_REALM_BUILDINGS.MAGETOWER * RealmBuildingsSize.MageTower
    let ArcherTower = TEST_REALM_BUILDINGS.ARCHERTOWER * RealmBuildingsSize.ArcherTower
    let Castle = TEST_REALM_BUILDINGS.CASTLE * RealmBuildingsSize.Castle

    assert buildings_sqm = House + StoreHouse + Granary + Farm + FishingVillage + Barracks + MageTower + ArcherTower + Castle

    return ()
end

@external
func test_pack_buildings{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let test_buildings = RealmBuildings(
        TEST_TIMESTAMP,
        TEST_REALM_BUILDINGS.STOREHOUSE,
        TEST_REALM_BUILDINGS.GRANARY,
        TEST_REALM_BUILDINGS.FARM,
        TEST_REALM_BUILDINGS.FISHINGVILLAGE,
        TEST_REALM_BUILDINGS.BARRACKS,
        TEST_REALM_BUILDINGS.MAGETOWER,
        TEST_REALM_BUILDINGS.ARCHERTOWER,
        TEST_REALM_BUILDINGS.CASTLE,
    )

    let (packed_buildings) = BUILDINGS.pack_buildings(test_buildings, RealmBuildingsIds.House)

    let (unpacked_buildings) = BUILDINGS.unpack_buildings(packed_buildings)

    assert TEST_TIMESTAMP = unpacked_buildings.House
    assert TEST_REALM_BUILDINGS.STOREHOUSE = unpacked_buildings.StoreHouse
    assert TEST_REALM_BUILDINGS.GRANARY = unpacked_buildings.Granary
    assert TEST_REALM_BUILDINGS.FARM = unpacked_buildings.Farm
    assert TEST_REALM_BUILDINGS.FISHINGVILLAGE = unpacked_buildings.FishingVillage
    assert TEST_REALM_BUILDINGS.BARRACKS = unpacked_buildings.Barracks
    assert TEST_REALM_BUILDINGS.MAGETOWER = unpacked_buildings.MageTower
    assert TEST_REALM_BUILDINGS.ARCHERTOWER = unpacked_buildings.ArcherTower
    assert TEST_REALM_BUILDINGS.CASTLE = unpacked_buildings.Castle

    return ()
end
