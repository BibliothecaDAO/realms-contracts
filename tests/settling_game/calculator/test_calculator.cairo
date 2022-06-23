%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div
from contracts.settling_game.utils.game_structs import (
    BuildingsFood,
    BuildingsPopulation,
    BuildingsCulture,
)
from contracts.settling_game.library.library_calculator import CALCULATOR

const food = 10
const culture = 10
const population = 100

const Fairgrounds = 0
const RoyalReserve = 0
const GrandMarket = 0
const Castle = 0
const Guild = 0
const OfficerAcademy = 0
const Granary = 0
const Housing = 0
const Amphitheater = 0
const ArcherTower = 0
const School = 0
const MageTower = 0
const TradeOffice = 0
const Architect = 0
const ParadeGrounds = 0
const Barracks = 0
const Dock = 0
const Fishmonger = 0
const Farms = 0
const Hamlet = 0
const troops = 50

const testHappiness = 100
const output = 100

@external
func test_production_cap{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (production_output, _) = unsigned_div_rem(output * testHappiness, 100)

    assert production_output = 100

    return ()
end

@external
func test_happiness{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    return ()
end

# @external
# func test_happiness{syscall_ptr : felt*, range_check_ptr}():
#     alloc_locals

# let castleFood = BuildingsFood.Castle * Castle
#     let FairgroundsFood = BuildingsFood.Fairgrounds * Fairgrounds
#     let RoyalReserveFood = BuildingsFood.RoyalReserve * RoyalReserve
#     let GrandMarketFood = BuildingsFood.GrandMarket * GrandMarket
#     let GuildFood = BuildingsFood.Guild * Guild
#     let OfficerAcademyFood = BuildingsFood.OfficerAcademy * OfficerAcademy
#     let GranaryFood = BuildingsFood.Granary * Granary
#     let HousingFood = BuildingsFood.Housing * Housing
#     let AmphitheaterFood = BuildingsFood.Amphitheater * Amphitheater
#     let ArcherTowerFood = BuildingsFood.ArcherTower * ArcherTower
#     let SchoolFood = BuildingsFood.School * School
#     let MageTowerFood = BuildingsFood.MageTower * MageTower
#     let TradeOfficeFood = BuildingsFood.TradeOffice * TradeOffice
#     let ArchitectFood = BuildingsFood.Architect * Architect
#     let ParadeGroundsFood = BuildingsFood.ParadeGrounds * ParadeGrounds
#     let BarracksFood = BuildingsFood.Barracks * Barracks
#     let DockFood = BuildingsFood.Dock * Dock
#     let FishmongerFood = BuildingsFood.Fishmonger * Fishmonger
#     let FarmsFood = BuildingsFood.Farms * Farms
#     let HamletFood = BuildingsFood.Hamlet * Hamlet

# let castlePop= BuildingsPopulation.Castle * Castle
#     let FairgroundsPop = BuildingsPopulation.Fairgrounds * Fairgrounds
#     let RoyalReservePop = BuildingsPopulation.RoyalReserve * RoyalReserve
#     let GrandMarketPop = BuildingsPopulation.GrandMarket * GrandMarket
#     let GuildPop = BuildingsPopulation.Guild * Guild
#     let OfficerAcademyPop = BuildingsPopulation.OfficerAcademy * OfficerAcademy
#     let GranaryPop = BuildingsPopulation.Granary * Granary
#     let HousingPop = BuildingsPopulation.Housing * Housing
#     let AmphitheaterPop = BuildingsPopulation.Amphitheater * Amphitheater
#     let ArcherTowerPop = BuildingsPopulation.ArcherTower * ArcherTower
#     let SchoolPop = BuildingsPopulation.School * School
#     let MageTowerPop = BuildingsPopulation.MageTower * MageTower
#     let TradeOfficePop = BuildingsPopulation.TradeOffice * TradeOffice
#     let ArchitectPop = BuildingsPopulation.Architect * Architect
#     let ParadeGroundsPop = BuildingsPopulation.ParadeGrounds * ParadeGrounds
#     let BarracksPop = BuildingsPopulation.Barracks * Barracks
#     let DockPop = BuildingsPopulation.Dock * Dock
#     let FishmongerPop= BuildingsPopulation.Fishmonger * Fishmonger
#     let FarmsPop = BuildingsPopulation.Farms * Farms
#     let HamletPop = BuildingsPopulation.Hamlet * Hamlet

# let castleCulture = BuildingsCulture.Castle * Castle
#     let FairgroundsCulture = BuildingsCulture.Fairgrounds * Fairgrounds
#     let RoyalReserveCulture = BuildingsCulture.RoyalReserve * RoyalReserve
#     let GrandMarketCulture = BuildingsCulture.GrandMarket * GrandMarket
#     let GuildCulture = BuildingsCulture.Guild * Guild
#     let OfficerAcademyCulture = BuildingsCulture.OfficerAcademy * OfficerAcademy
#     let GranaryCulture = BuildingsCulture.Granary * Granary
#     let HousingCulture = BuildingsCulture.Housing * Housing
#     let AmphitheaterCulture = BuildingsCulture.Amphitheater * Amphitheater
#     let ArcherTowerCulture = BuildingsCulture.ArcherTower * ArcherTower
#     let SchoolCulture = BuildingsCulture.School * School
#     let MageTowerCulture = BuildingsCulture.MageTower * MageTower
#     let TradeOfficeCulture = BuildingsCulture.TradeOffice * TradeOffice
#     let ArchitectCulture = BuildingsCulture.Architect * Architect
#     let ParadeGroundsCulture= BuildingsCulture.ParadeGrounds * ParadeGrounds
#     let BarracksCulture = BuildingsCulture.Barracks * Barracks
#     let DockCulture = BuildingsCulture.Dock * Dock
#     let FishmongerCulture= BuildingsCulture.Fishmonger * Fishmonger
#     let FarmsCulture = BuildingsCulture.Farms * Farms
#     let HamletCulture = BuildingsCulture.Hamlet * Hamlet

# let troopsFood = troops * - 1
#     let troopsPop = troops * - 1

# let food = 10 + castleFood + FairgroundsFood + RoyalReserveFood + GrandMarketFood + GuildFood + OfficerAcademyFood + GranaryFood +HousingFood + AmphitheaterFood + ArcherTowerFood + SchoolFood + MageTowerFood + TradeOfficeFood + ArchitectFood + ParadeGroundsFood + BarracksFood + DockFood + FishmongerFood + FarmsFood + HamletFood + troopsFood

# let population = 100 + castlePop + FairgroundsPop + RoyalReservePop + GrandMarketPop + GuildPop + OfficerAcademyPop + GranaryPop +HousingPop + AmphitheaterPop + ArcherTowerPop + SchoolPop + MageTowerPop + TradeOfficePop + ArchitectPop + ParadeGroundsPop + BarracksPop + DockPop + FishmongerPop + FarmsPop + HamletPop + troopsPop

# let culture = 10 + castleCulture + FairgroundsCulture + RoyalReserveCulture + GrandMarketCulture + GuildCulture + OfficerAcademyCulture + GranaryCulture + HousingCulture + AmphitheaterCulture + ArcherTowerCulture + SchoolCulture + MageTowerCulture + TradeOfficeCulture + ArchitectCulture + ParadeGroundsCulture + BarracksCulture + DockCulture + FishmongerCulture + FarmsCulture + HamletCulture

# let (happiness) = CALCULATOR.get_happiness(culture, population, food)

# assert happiness = 60

# return ()
# end
