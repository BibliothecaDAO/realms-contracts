%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from contracts.settling_game.utils.game_structs import (
    BuildingsFood,
    BuildingsPopulation,
    BuildingsCulture,
    RealmBuildings,
    BuildingsTroopIndustry,
)
from contracts.settling_game.library.library_calculator import Calculator

from tests.protostar.settling_game.test_structs import TEST_REALM_BUILDINGS

const TROOP_POPULATION = 10;

@external
func test_calculate_happiness{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
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

    let (realm_population) = Calculator.calculate_food(test_buildings, TROOP_POPULATION);

    let (realm_food) = Calculator.calculate_food(test_buildings, TROOP_POPULATION);

    let (realm_happiness) = Calculator.calculate_happiness(realm_population, realm_food);

    // %{ print('Realm Happiness:', ids.realm_happiness) %}

    // TODO: missing assert

    return ();
}

@external
func test_calculate_food{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
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

    let (realm_food) = Calculator.calculate_food(test_buildings, TROOP_POPULATION);

    // %{ print('Realm Food:', ids.realm_food) %}

    let House = BuildingsFood.House * TEST_REALM_BUILDINGS.HOUSE;
    let StoreHouse = BuildingsFood.StoreHouse * TEST_REALM_BUILDINGS.STOREHOUSE;
    let Granary = BuildingsFood.Granary * TEST_REALM_BUILDINGS.GRANARY;
    let Farm = BuildingsFood.Farm * TEST_REALM_BUILDINGS.FARM;
    let FishingVillage = BuildingsFood.FishingVillage * TEST_REALM_BUILDINGS.FISHINGVILLAGE;
    let Barracks = BuildingsFood.Barracks * TEST_REALM_BUILDINGS.BARRACKS;
    let MageTower = BuildingsFood.MageTower * TEST_REALM_BUILDINGS.MAGETOWER;
    let ArcherTower = BuildingsFood.ArcherTower * TEST_REALM_BUILDINGS.ARCHERTOWER;
    let Castle = BuildingsFood.Castle * TEST_REALM_BUILDINGS.CASTLE;

    assert realm_food = House + StoreHouse + Granary + Farm + FishingVillage + Barracks + MageTower + ArcherTower + Castle - TROOP_POPULATION;

    return ();
}

@external
func test_calculate_population{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
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

    let (realm_population) = Calculator.calculate_population(test_buildings, TROOP_POPULATION);

    // %{ print('Realm Population:', ids.realm_population) %}

    let House = BuildingsPopulation.House * TEST_REALM_BUILDINGS.HOUSE;
    let StoreHouse = BuildingsPopulation.StoreHouse * TEST_REALM_BUILDINGS.STOREHOUSE;
    let Granary = BuildingsPopulation.Granary * TEST_REALM_BUILDINGS.GRANARY;
    let Farm = BuildingsPopulation.Farm * TEST_REALM_BUILDINGS.FARM;
    let FishingVillage = BuildingsPopulation.FishingVillage * TEST_REALM_BUILDINGS.FISHINGVILLAGE;
    let Barracks = BuildingsPopulation.Barracks * TEST_REALM_BUILDINGS.BARRACKS;
    let MageTower = BuildingsPopulation.MageTower * TEST_REALM_BUILDINGS.MAGETOWER;
    let ArcherTower = BuildingsPopulation.ArcherTower * TEST_REALM_BUILDINGS.ARCHERTOWER;
    let Castle = BuildingsPopulation.Castle * TEST_REALM_BUILDINGS.CASTLE;

    assert realm_population = House + StoreHouse + Granary + Farm + FishingVillage + Barracks + MageTower + ArcherTower + Castle - TROOP_POPULATION;

    return ();
}

@external
func test_calculate_troop_coefficient{syscall_ptr: felt*, range_check_ptr}() {
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

    let (troop_coefficient) = Calculator.calculate_troop_coefficient(test_buildings);

    // %{ print('Troop coefficient:', ids.troop_coefficient) %}

    let barracks = TEST_REALM_BUILDINGS.BARRACKS * BuildingsTroopIndustry.Barracks;
    let mageTower = TEST_REALM_BUILDINGS.MAGETOWER * BuildingsTroopIndustry.MageTower;
    let archerTower = TEST_REALM_BUILDINGS.ARCHERTOWER * BuildingsTroopIndustry.ArcherTower;
    let castle = TEST_REALM_BUILDINGS.CASTLE * BuildingsTroopIndustry.Castle;

    assert troop_coefficient = barracks + mageTower + archerTower + castle;

    return ();
}
