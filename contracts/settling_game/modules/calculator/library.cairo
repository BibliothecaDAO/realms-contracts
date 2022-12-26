// CALCULATOR LIBRARY
//   Helper functions for staking.
//
//
// MIT License

%lang starknet

from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.utils.game_structs import (
    BuildingsTroopIndustry,
    RealmBuildings,
    BuildingsPopulation,
)
namespace Calculator {
    func calculate_population(buildings: RealmBuildings) -> felt {
        let House = BuildingsPopulation.House * buildings.House;
        let StoreHouse = BuildingsPopulation.StoreHouse * buildings.StoreHouse;
        let Granary = BuildingsPopulation.Granary * buildings.Granary;
        let Farm = BuildingsPopulation.Farm * buildings.Farm;
        let FishingVillage = BuildingsPopulation.FishingVillage * buildings.FishingVillage;
        let Barracks = BuildingsPopulation.Barracks * buildings.Barracks;
        let MageTower = BuildingsPopulation.MageTower * buildings.MageTower;
        let ArcherTower = BuildingsPopulation.ArcherTower * buildings.ArcherTower;
        let Castle = BuildingsPopulation.Castle * buildings.Castle;

        let population = House + StoreHouse + Granary + Farm + FishingVillage + Barracks + MageTower + ArcherTower + Castle;

        return (population);
    }

    // Returns coefficient for troop production in bp
    func calculate_troop_coefficient(buildings: RealmBuildings) -> (coefficient: felt) {
        let Barracks = buildings.Barracks * BuildingsTroopIndustry.Barracks;
        let MageTower = buildings.MageTower * BuildingsTroopIndustry.MageTower;
        let ArcherTower = buildings.ArcherTower * BuildingsTroopIndustry.ArcherTower;
        let Castle = buildings.Castle * BuildingsTroopIndustry.Castle;

        return (Barracks + MageTower + ArcherTower + Castle,);
    }

    func get_randomness_value{range_check_ptr}(randomness_value: felt) -> felt {
        alloc_locals;

        let (type_label) = get_label_location(daily_value);

        return ([type_label + randomness_value - 1]);

        // this length must == NUMBER_OF_RANDOM_EVENTS
        daily_value:
        dw 1;
        dw 2;
        dw 3;
        dw 1;
        dw 2;
        dw 3;
        dw 1;
        dw 2;
        dw 3;
    }
}
