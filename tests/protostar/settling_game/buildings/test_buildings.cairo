%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from contracts.settling_game.utils.game_structs import (
    BuildingsPopulation,
    RealmBuildings,
    RealmBuildingsIds,
    BuildingsIntegrityLength,
    RealmBuildingsSize,
    BuildingsDecaySlope,
    Cost,
)
from contracts.settling_game.modules.buildings.library import Buildings

from tests.protostar.settling_game.test_structs import TEST_REALM_BUILDINGS

const BUILDING_QUANTITY = 1;
const TEST_REALM_REGIONS = 4;
const TEST_REALM_CITIES = 25;

const TEST_TIMESTAMP = 1645743897;
const TEST_TIME_BALANCE_TIMESTAMP = TEST_TIMESTAMP + 56400;

@external
func test_get_building_left{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    // now - timestamp = param
    let (base_building_number, time_left) = Buildings.get_base_building_left(
        TEST_TIME_BALANCE_TIMESTAMP, TEST_TIMESTAMP, RealmBuildingsIds.Castle
    );

    let (length) = Buildings.integrity_length(RealmBuildingsIds.Castle);

    let (buildings_left, _) = unsigned_div_rem(
        TEST_TIME_BALANCE_TIMESTAMP - TEST_TIMESTAMP, length
    );

    assert base_building_number = buildings_left;

    return ();
}

@external
func test_calculate_effective_buildings{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let (base_building_number, time_left) = Buildings.get_base_building_left(
        TEST_TIME_BALANCE_TIMESTAMP, TEST_TIMESTAMP, RealmBuildingsIds.Castle
    );

    let (decay_slope) = Buildings.get_decay_slope(RealmBuildingsIds.Castle);

    // pass slope determined by building
    let (decay_rate) = Buildings.get_decay_rate(base_building_number, decay_slope);

    // pass actual time balance + decay rate
    let (effective_building_time) = Buildings.get_decayed_building_time(time_left, decay_rate);

    let (effective_buildings) = Buildings.get_effective_buildings(
        effective_building_time, RealmBuildingsIds.Castle
    );

    let (calculated_effective_buildings) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.Castle, TEST_TIME_BALANCE_TIMESTAMP, TEST_TIMESTAMP
    );

    assert calculated_effective_buildings = effective_buildings;

    return ();
}

@external
func test_get_decay_slope{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (decay_slope) = Buildings.get_decay_slope(RealmBuildingsIds.Castle);

    assert decay_slope = BuildingsDecaySlope.Castle;

    return ();
}

@external
func test_get_integrity_length{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (final_time) = Buildings.get_integrity_length(
        TEST_TIMESTAMP, RealmBuildingsIds.Castle, BUILDING_QUANTITY
    );

    assert final_time = BuildingsIntegrityLength.Castle * BUILDING_QUANTITY + BuildingsIntegrityLength.Castle;

    return ();
}

@external
func test_can_build{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

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
    );

    let (can_build) = Buildings.can_build(
        RealmBuildingsIds.Castle,
        BUILDING_QUANTITY,
        test_buildings,
        TEST_REALM_CITIES,
        TEST_REALM_REGIONS,
    );

    assert can_build = TRUE;

    return ();
}

@external
func test_building_size{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (building_size) = Buildings.get_building_size(RealmBuildingsIds.Castle);

    assert building_size = RealmBuildingsSize.Castle;

    return ();
}

@external
func test_get_current_built_buildings_sqm{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

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
    );

    let (buildings_sqm) = Buildings.get_current_built_buildings_sqm(test_buildings);

    let House = TEST_REALM_BUILDINGS.HOUSE * RealmBuildingsSize.House;
    let StoreHouse = TEST_REALM_BUILDINGS.STOREHOUSE * RealmBuildingsSize.StoreHouse;
    let Granary = TEST_REALM_BUILDINGS.GRANARY * RealmBuildingsSize.Granary;
    let Farm = TEST_REALM_BUILDINGS.FARM * RealmBuildingsSize.Farm;
    let FishingVillage = TEST_REALM_BUILDINGS.FISHINGVILLAGE * RealmBuildingsSize.FishingVillage;
    let Barracks = TEST_REALM_BUILDINGS.BARRACKS * RealmBuildingsSize.Barracks;
    let MageTower = TEST_REALM_BUILDINGS.MAGETOWER * RealmBuildingsSize.MageTower;
    let ArcherTower = TEST_REALM_BUILDINGS.ARCHERTOWER * RealmBuildingsSize.ArcherTower;
    let Castle = TEST_REALM_BUILDINGS.CASTLE * RealmBuildingsSize.Castle;

    assert buildings_sqm = House + StoreHouse + Granary + Farm + FishingVillage + Barracks + MageTower + ArcherTower + Castle;

    return ();
}

@external
func test_pack_buildings{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let test_buildings = RealmBuildings(
        TEST_TIMESTAMP,
        TEST_TIMESTAMP,
        TEST_TIMESTAMP,
        TEST_TIMESTAMP,
        TEST_TIMESTAMP,
        TEST_TIMESTAMP,
        TEST_TIMESTAMP,
        TEST_TIMESTAMP,
        TEST_TIMESTAMP,
    );

    let (packed_buildings) = Buildings.pack_buildings(test_buildings);

    let (unpacked_buildings) = Buildings.unpack_buildings(packed_buildings);

    assert TEST_TIMESTAMP = unpacked_buildings.House;
    assert TEST_TIMESTAMP = unpacked_buildings.StoreHouse;
    assert TEST_TIMESTAMP = unpacked_buildings.Granary;
    assert TEST_TIMESTAMP = unpacked_buildings.Farm;
    assert TEST_TIMESTAMP = unpacked_buildings.FishingVillage;
    assert TEST_TIMESTAMP = unpacked_buildings.Barracks;
    assert TEST_TIMESTAMP = unpacked_buildings.MageTower;
    assert TEST_TIMESTAMP = unpacked_buildings.ArcherTower;
    assert TEST_TIMESTAMP = unpacked_buildings.Castle;

    return ();
}

@external
func test_add_time_to_buildings{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let test_buildings = RealmBuildings(TEST_TIME_BALANCE_TIMESTAMP, 0, 0, 0, 0, 0, 0, 0, 0);

    let (time_to_add) = Buildings.get_integrity_length(TEST_TIMESTAMP, RealmBuildingsIds.House, 1);

    let (unpacked_buildings) = Buildings.add_time_to_buildings(
        test_buildings, RealmBuildingsIds.House, TEST_TIMESTAMP, time_to_add
    );

    assert TEST_TIME_BALANCE_TIMESTAMP + time_to_add = unpacked_buildings.House;
    assert 0 = unpacked_buildings.StoreHouse;
    assert 0 = unpacked_buildings.Granary;
    assert 0 = unpacked_buildings.Farm;
    assert 0 = unpacked_buildings.FishingVillage;
    assert 0 = unpacked_buildings.Barracks;
    assert 0 = unpacked_buildings.MageTower;
    assert 0 = unpacked_buildings.ArcherTower;
    assert 0 = unpacked_buildings.Castle;

    let (time_to_add) = Buildings.get_integrity_length(
        TEST_TIMESTAMP, RealmBuildingsIds.Barracks, 1
    );
    let (unpacked_buildings) = Buildings.add_time_to_buildings(
        test_buildings, RealmBuildingsIds.Barracks, TEST_TIMESTAMP, time_to_add
    );

    // assert 0 = unpacked_buildings.House
    assert 0 = unpacked_buildings.StoreHouse;
    assert 0 = unpacked_buildings.Granary;
    assert 0 = unpacked_buildings.Farm;
    assert 0 = unpacked_buildings.FishingVillage;
    assert TEST_TIMESTAMP + time_to_add = unpacked_buildings.Barracks;
    assert 0 = unpacked_buildings.MageTower;
    assert 0 = unpacked_buildings.ArcherTower;
    assert 0 = unpacked_buildings.Castle;

    return ();
}

@external
func test_get_packed_value{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let test_buildings = RealmBuildings(
        TEST_TIME_BALANCE_TIMESTAMP,
        TEST_TIME_BALANCE_TIMESTAMP,
        TEST_TIME_BALANCE_TIMESTAMP,
        TEST_TIME_BALANCE_TIMESTAMP,
        TEST_TIME_BALANCE_TIMESTAMP,
        TEST_TIME_BALANCE_TIMESTAMP,
        TEST_TIME_BALANCE_TIMESTAMP,
        TEST_TIME_BALANCE_TIMESTAMP,
        TEST_TIME_BALANCE_TIMESTAMP,
    );

    let (building) = Buildings.get_unpacked_value(test_buildings, RealmBuildingsIds.House);

    assert TEST_TIME_BALANCE_TIMESTAMP = building;

    return ();
}
