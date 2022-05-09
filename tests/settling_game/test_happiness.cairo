%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div
from contracts.settling_game.utils.game_structs import BuildingsFood, BuildingsPopulation, BuildingsCulture

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
const troops = 0



const testHappiness = 100
const outPut = 100


@external
func test_production_cap{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (production_output, _) = unsigned_div_rem(outPut * testHappiness, 100)

    %{ print(ids.production_output) %}

    return ()
end

@external
func test_food{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let castleFood = BuildingsFood.Castle * Castle
    let FairgroundsFood = BuildingsFood.Fairgrounds * Fairgrounds
    let RoyalReserveFood = BuildingsFood.RoyalReserve * RoyalReserve
    let GrandMarketFood = BuildingsFood.GrandMarket * GrandMarket
    let GuildFood = BuildingsFood.Guild * Guild
    let OfficerAcademyFood = BuildingsFood.OfficerAcademy * OfficerAcademy
    let GranaryFood = BuildingsFood.Granary * Granary
    let HousingFood = BuildingsFood.Housing * Housing
    let AmphitheaterFood = BuildingsFood.Amphitheater * Amphitheater
    let ArcherTowerFood = BuildingsFood.ArcherTower * ArcherTower
    let SchoolFood = BuildingsFood.School * School
    let MageTowerFood = BuildingsFood.MageTower * MageTower
    let TradeOfficeFood = BuildingsFood.TradeOffice * TradeOffice
    let ArchitectFood = BuildingsFood.Architect * Architect
    let ParadeGroundsFood = BuildingsFood.ParadeGrounds * ParadeGrounds
    let BarracksFood = BuildingsFood.Barracks * Barracks
    let DockFood = BuildingsFood.Dock * Dock
    let FishmongerFood = BuildingsFood.Fishmonger * Fishmonger
    let FarmsFood = BuildingsFood.Farms * Farms
    let HamletFood = BuildingsFood.Hamlet * Hamlet

    let castlePop= BuildingsPopulation.Castle * Castle
    let FairgroundsPop = BuildingsPopulation.Fairgrounds * Fairgrounds
    let RoyalReservePop = BuildingsPopulation.RoyalReserve * RoyalReserve
    let GrandMarketPop = BuildingsPopulation.GrandMarket * GrandMarket
    let GuildPop = BuildingsPopulation.Guild * Guild
    let OfficerAcademyPop = BuildingsPopulation.OfficerAcademy * OfficerAcademy
    let GranaryPop = BuildingsPopulation.Granary * Granary
    let HousingPop = BuildingsPopulation.Housing * Housing
    let AmphitheaterPop = BuildingsPopulation.Amphitheater * Amphitheater
    let ArcherTowerPop = BuildingsPopulation.ArcherTower * ArcherTower
    let SchoolPop = BuildingsPopulation.School * School
    let MageTowerPop = BuildingsPopulation.MageTower * MageTower
    let TradeOfficePop = BuildingsPopulation.TradeOffice * TradeOffice
    let ArchitectPop = BuildingsPopulation.Architect * Architect
    let ParadeGroundsPop = BuildingsPopulation.ParadeGrounds * ParadeGrounds
    let BarracksPop = BuildingsPopulation.Barracks * Barracks
    let DockPop = BuildingsPopulation.Dock * Dock
    let FishmongerPop= BuildingsPopulation.Fishmonger * Fishmonger
    let FarmsPop = BuildingsPopulation.Farms * Farms
    let HamletPop = BuildingsPopulation.Hamlet * Hamlet

    let castleCulture = BuildingsCulture.Castle * Castle
    let FairgroundsCulture = BuildingsCulture.Fairgrounds * Fairgrounds
    let RoyalReserveCulture = BuildingsCulture.RoyalReserve * RoyalReserve
    let GrandMarketCulture = BuildingsCulture.GrandMarket * GrandMarket
    let GuildCulture = BuildingsCulture.Guild * Guild
    let OfficerAcademyCulture = BuildingsCulture.OfficerAcademy * OfficerAcademy
    let GranaryCulture = BuildingsCulture.Granary * Granary
    let HousingCulture = BuildingsCulture.Housing * Housing
    let AmphitheaterCulture = BuildingsCulture.Amphitheater * Amphitheater
    let ArcherTowerCulture = BuildingsCulture.ArcherTower * ArcherTower
    let SchoolCulture = BuildingsCulture.School * School
    let MageTowerCulture = BuildingsCulture.MageTower * MageTower
    let TradeOfficeCulture = BuildingsCulture.TradeOffice * TradeOffice
    let ArchitectCulture = BuildingsCulture.Architect * Architect
    let ParadeGroundsCulture= BuildingsCulture.ParadeGrounds * ParadeGrounds
    let BarracksCulture = BuildingsCulture.Barracks * Barracks
    let DockCulture = BuildingsCulture.Dock * Dock
    let FishmongerCulture= BuildingsCulture.Fishmonger * Fishmonger
    let FarmsCulture = BuildingsCulture.Farms * Farms
    let HamletCulture = BuildingsCulture.Hamlet * Hamlet

    let troopsFood = troops * - 1
    let troopsPop = troops * - 1

    let totalFood = 10 + castleFood + FairgroundsFood + RoyalReserveFood + GrandMarketFood + GuildFood + OfficerAcademyFood + GranaryFood +HousingFood + AmphitheaterFood + ArcherTowerFood + SchoolFood + MageTowerFood + TradeOfficeFood + ArchitectFood + ParadeGroundsFood + BarracksFood + DockFood + FishmongerFood + FarmsFood + HamletFood + troopsFood

    let totalPopulation = 100 + castlePop + FairgroundsPop + RoyalReservePop + GrandMarketPop + GuildPop + OfficerAcademyPop + GranaryPop +HousingPop + AmphitheaterPop + ArcherTowerPop + SchoolPop + MageTowerPop + TradeOfficePop + ArchitectPop + ParadeGroundsPop + BarracksPop + DockPop + FishmongerPop + FarmsPop + HamletPop + troopsPop

    let totalCulture = 10 + castleCulture + FairgroundsCulture + RoyalReserveCulture + GrandMarketCulture + GuildCulture + OfficerAcademyCulture + GranaryCulture +HousingCulture + AmphitheaterCulture + ArcherTowerCulture + SchoolCulture + MageTowerCulture + TradeOfficeCulture + ArchitectCulture + ParadeGroundsCulture + BarracksCulture + DockCulture + FishmongerCulture + FarmsCulture + HamletCulture
    
    let pop_calc = totalPopulation / 10

    let culture_calc = totalCulture - pop_calc

    let food_calc = totalFood - pop_calc

    let (assert_check) = is_nn(100 + culture_calc + food_calc)
    
    # %{ print(ids.happiness) %}
    if assert_check == 0:
        %{ print(100 + ids.culture_calc + ids.food_calc) %}
        return ()
    end

    let happiness = 100 + culture_calc + food_calc

    let (is_lessthan_threshold) = is_le(happiness, 50)

    let (is_greaterthan_threshold) = is_le(150, happiness)

    if is_lessthan_threshold == 1:
        %{ print(50) %}
        return ()
    end

    if is_greaterthan_threshold == 1:
        %{ print(150) %}
        return ()
    end

    %{ print(ids.happiness) %}

    return ()
end
# @contract_interface
# namespace ProxyInterface:
#     func initializer(address_of_controller : felt, proxy_admin : felt):
#     end
# end

# @contract_interface
# namespace LordsInterface:
#     func initializer(
#         name : felt,
#         symbol : felt,
#         decimals : felt,
#         initial_supply : Uint256,
#         recipient : felt,
#         proxy_admin : felt,
#     ):
#     end
# end

# @contract_interface
# namespace RealmsInterface:
#     func initializer(
#         name: felt,
#         symbol: felt,
#         proxy_admin: felt
#     ):
#     end
# end

# @external
# func test_happiness{syscall_ptr : felt*, range_check_ptr}():
#     alloc_locals

#     local lords : felt
#     local realms : felt
#     local s_realms : felt
#     local resources : felt

#     local proxy_lords : felt
#     local proxy_realms : felt
#     local proxy_s_realms : felt
#     local proxy_resources : felt

#     local Account : felt
#     local Arbiter : felt
#     local ModuleController : felt

#     local L01_Settling : felt
#     local L01_Proxy_Settling : felt

#     local L02_Resources : felt
#     local L03_Buildings : felt
#     local L04_Calculator : felt

#     %{ ids.Account = deploy_contract("./openzeppelin/account/Account.cairo", [123456]).contract_address %}

#     %{ print("lords") %}
#     %{ ids.lords = deploy_contract("./contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo", []).contract_address %}
#     %{ ids.proxy_lords = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.lords]).contract_address %}
#     LordsInterface.initializer(proxy_lords, 1234, 1234, 18, Uint256(50000, 0), Account, Account)

#     %{ print("realms") %}
#     %{ ids.realms = deploy_contract("./contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo", []).contract_address %}
#     %{ ids.proxy_realms = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.realms]).contract_address %}
#     RealmsInterface.initializer(proxy_realms, 1234, 1234, Account)

#     %{ print("s_realms") %}
#     %{ ids.s_realms = deploy_contract("./contracts/settling_game/tokens/S_Realms_ERC721_Mintable.cairo", []).contract_address %}
#     %{ ids.proxy_s_realms = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.s_realms]).contract_address %}
#     RealmsInterface.initializer(proxy_s_realms, 1234, 1234, Account)

#     # GAME CONTROLLERS
#     %{ ids.Arbiter = deploy_contract("./contracts/settling_game/Arbiter.cairo", [ids.Account]).contract_address %}
#     %{ ids.ModuleController = deploy_contract("./contracts/settling_game/ModuleController.cairo", [ids.Arbiter,ids.proxy_lords,ids.proxy_lords,ids.proxy_lords,ids.proxy_lords,ids.proxy_lords]).contract_address %}

#     # GAME MODULES
#     %{ ids.L01_Settling = deploy_contract("./contracts/settling_game/L01_Settling.cairo", []).contract_address %}
#     %{ ids.L01_Proxy_Settling = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.L01_Settling]).contract_address %}

#     # Settling
#     ProxyInterface.initializer(
#         contract_address=L01_Proxy_Settling,
#         address_of_controller=L01_Settling,
#         proxy_admin=L01_Settling,
#     )

#     # %{ ids.L02_Resources = deploy_contract("./contracts/settling_game/L02_Resources.cairo", []).contract_address %}
#     # %{ ids.L03_Buildings = deploy_contract("./contracts/settling_game/L03_Buildings.cairo", []).contract_address %}
#     # %{ ids.L04_Calculator = deploy_contract("./contracts/settling_game/L04_Calculator.cairo", []).contract_address %}

#     # wonders.write(contract_a_address)

#     return ()
# end
