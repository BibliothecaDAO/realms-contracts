# CALCULATOR LIBRARY
#   Helper functions for staking.
#
#
# MIT License

%lang starknet

from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.utils.game_structs import (
    BuildingsTroopIndustry,
    RealmBuildings,
    BuildingsFood,
    BuildingsPopulation,
)
namespace CALCULATOR:
    func calculate_happiness{syscall_ptr : felt*, range_check_ptr}(
        population : felt, food : felt
    ) -> (happiness : felt):
        alloc_locals
        # FETCH VALUES
        let (population_calculation, _) = unsigned_div_rem(population, 10)
        let food_calc = food - population_calculation

        # SANITY FALL BACK CHECK INCASE OF OVERFLOW....
        let (assert_check) = is_nn(100 + food_calc)
        if assert_check == 0:
            return (50)
        end

        let happiness = 100 + food_calc

        # if happiness less than 50, cap it
        let (is_lessthan_threshold) = is_le(happiness, 50)
        if is_lessthan_threshold == 1:
            return (50)
        end

        # if happiness greater than 150 cap it
        let (is_greaterthan_threshold) = is_le(150, happiness)
        if is_greaterthan_threshold == 1:
            return (150)
        end
        return (happiness)
    end

    func calculate_food{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        buildings : RealmBuildings, troop_population : felt
    ) -> (food : felt):
        alloc_locals

        let House = BuildingsFood.House * buildings.House
        let StoreHouse = BuildingsFood.StoreHouse * buildings.StoreHouse
        let Granary = BuildingsFood.Granary * buildings.Granary
        let Farm = BuildingsFood.Farm * buildings.Farm
        let FishingVillage = BuildingsFood.FishingVillage * buildings.FishingVillage
        let Barracks = BuildingsFood.Barracks * buildings.Barracks
        let MageTower = BuildingsFood.MageTower * buildings.MageTower
        let ArcherTower = BuildingsFood.ArcherTower * buildings.ArcherTower
        let Castle = BuildingsFood.Castle * buildings.Castle

        let food = House + StoreHouse + Granary + Farm + FishingVillage + Barracks + MageTower + ArcherTower + Castle

        return (food - troop_population)
    end

    func calculate_population{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        buildings : RealmBuildings, troop_population : felt
    ) -> (food : felt):
        alloc_locals

        let House = BuildingsPopulation.House * buildings.House
        let StoreHouse = BuildingsPopulation.StoreHouse * buildings.StoreHouse
        let Granary = BuildingsPopulation.Granary * buildings.Granary
        let Farm = BuildingsPopulation.Farm * buildings.Farm
        let FishingVillage = BuildingsPopulation.FishingVillage * buildings.FishingVillage
        let Barracks = BuildingsPopulation.Barracks * buildings.Barracks
        let MageTower = BuildingsPopulation.MageTower * buildings.MageTower
        let ArcherTower = BuildingsPopulation.ArcherTower * buildings.ArcherTower
        let Castle = BuildingsPopulation.Castle * buildings.Castle

        let population = House + StoreHouse + Granary + Farm + FishingVillage + Barracks + MageTower + ArcherTower + Castle

        return (population - troop_population)
    end

    # Returns coefficient for troop production in bp
    func calculate_troop_coefficient{syscall_ptr : felt*, range_check_ptr}(
        buildings : RealmBuildings
    ) -> (coefficient : felt):
        alloc_locals

        let Barracks = buildings.Barracks * BuildingsTroopIndustry.Barracks
        let MageTower = buildings.MageTower * BuildingsTroopIndustry.MageTower
        let ArcherTower = buildings.ArcherTower * BuildingsTroopIndustry.ArcherTower
        let Castle = buildings.Castle * BuildingsTroopIndustry.Castle

        return (Barracks + MageTower + ArcherTower + Castle)
    end
end
