# ____MODULE_L04___CONTRACT_LOGIC
#   This modules focus is to calculate the values of the internal
#   multipliers so other modules can use them. The aim is to have this
#   as the core calculator controller that contains no state.
#   It is pure math.
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le, is_nn, is_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.game_structs import RealmBuildings, ModuleIds, BuildingsFood, BuildingsPopulation, BuildingsCulture

from contracts.settling_game.utils.constants import (
    TRUE,
    FALSE,
    GENESIS_TIMESTAMP,
    VAULT_LENGTH_SECONDS,
)

from contracts.settling_game.interfaces.imodules import (
    IModuleController,
    IS01_Settling,
    IL03_Buildings,
)

from contracts.settling_game.utils.library import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
)

from openzeppelin.upgrades.library import (
    Proxy_initializer,
    Proxy_only_admin,
    Proxy_set_implementation
)
@external
func initializer{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        address_of_controller : felt,
        proxy_admin : felt
    ):
    MODULE_initializer(address_of_controller)
    Proxy_initializer(proxy_admin)
    return ()
end

@external
func upgrade{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(new_implementation: felt):
    Proxy_only_admin()
    Proxy_set_implementation(new_implementation)
    return ()
end

@view
func calculate_epoch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    epoch : felt
):
    let (controller) = MODULE_controller_address()

    let (genesis_time_stamp) = IModuleController.get_genesis(contract_address=controller)

    let (block_timestamp) = get_block_timestamp()

    let (epoch, _) = unsigned_div_rem(block_timestamp - genesis_time_stamp, VAULT_LENGTH_SECONDS)
    return (epoch=epoch)
end

@view
func calculate_happiness{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (happiness : felt):
    alloc_locals

    let (local culture : felt) = calculateCulture(tokenId)
    let (local population : felt) = calculatePopulation(tokenId)
    let (local food : felt) = calculateFood(tokenId)

    let pop_calc = population / 10

    let culture_calc = culture - pop_calc

    let food_calc = food - pop_calc

    let (assert_check) = is_nn(100 + culture_calc + food_calc)
    
    # %{ print(ids.happiness) %}
    if assert_check == 0:
        return (100)
    end

    let happiness = 100 + culture_calc + food_calc

    let (is_lessthan_threshold) = is_le(happiness, 50)

    let (is_greaterthan_threshold) = is_le(150, happiness)

    if is_lessthan_threshold == 1:
        return (50)
    end

    if is_greaterthan_threshold == 1:
        return (150)
    end

    return (happiness=happiness)
end

@view
func calculateCulture{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (culture : felt):
    let (controller) = MODULE_controller_address()

    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings
    )

    let (current_buildings : RealmBuildings) = IL03_Buildings.fetch_buildings_by_type(
        buildings_logic_address, tokenId
    )

    let CastleCulture = BuildingsCulture.Castle * current_buildings.Castle
    let FairgroundsCulture = BuildingsCulture.Fairgrounds * current_buildings.Fairgrounds
    let RoyalReserveCulture = BuildingsCulture.RoyalReserve * current_buildings.RoyalReserve
    let GrandMarketCulture = BuildingsCulture.GrandMarket * current_buildings.GrandMarket
    let GuildCulture = BuildingsCulture.Guild * current_buildings.Guild
    let OfficerAcademyCulture = BuildingsCulture.OfficerAcademy * current_buildings.OfficerAcademy
    let GranaryCulture = BuildingsCulture.Granary * current_buildings.Granary
    let HousingCulture = BuildingsCulture.Housing * current_buildings.Housing
    let AmphitheaterCulture = BuildingsCulture.Amphitheater * current_buildings.Amphitheater
    let ArcherTowerCulture = BuildingsCulture.ArcherTower * current_buildings.ArcherTower
    let SchoolCulture = BuildingsCulture.School * current_buildings.School
    let MageTowerCulture = BuildingsCulture.MageTower * current_buildings.MageTower
    let TradeOfficeCulture = BuildingsCulture.TradeOffice * current_buildings.TradeOffice
    let ArchitectCulture = BuildingsCulture.Architect * current_buildings.Architect
    let ParadeGroundsCulture= BuildingsCulture.ParadeGrounds * current_buildings.ParadeGrounds
    let BarracksCulture = BuildingsCulture.Barracks * current_buildings.Barracks
    let DockCulture = BuildingsCulture.Dock * current_buildings.Dock
    let FishmongerCulture= BuildingsCulture.Fishmonger * current_buildings.Fishmonger
    let FarmsCulture = BuildingsCulture.Farms * current_buildings.Farms
    let HamletCulture = BuildingsCulture.Hamlet * current_buildings.Hamlet

    let totalCulture = 10 + CastleCulture + FairgroundsCulture + RoyalReserveCulture + GrandMarketCulture + GuildCulture + OfficerAcademyCulture + GranaryCulture +HousingCulture + AmphitheaterCulture + ArcherTowerCulture + SchoolCulture + MageTowerCulture + TradeOfficeCulture + ArchitectCulture + ParadeGroundsCulture + BarracksCulture + DockCulture + FishmongerCulture + FarmsCulture + HamletCulture

    return (culture=totalCulture)
end

@view
func calculatePopulation{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (population : felt):
    let (controller) = MODULE_controller_address()

    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings
    )

    let (current_buildings : RealmBuildings) = IL03_Buildings.fetch_buildings_by_type(
        buildings_logic_address, tokenId
    )

    let CastlePop= BuildingsPopulation.Castle * current_buildings.Castle
    let FairgroundsPop = BuildingsPopulation.Fairgrounds * current_buildings.Fairgrounds
    let RoyalReservePop = BuildingsPopulation.RoyalReserve * current_buildings.RoyalReserve
    let GrandMarketPop = BuildingsPopulation.GrandMarket * current_buildings.GrandMarket
    let GuildPop = BuildingsPopulation.Guild * current_buildings.Guild
    let OfficerAcademyPop = BuildingsPopulation.OfficerAcademy * current_buildings.OfficerAcademy
    let GranaryPop = BuildingsPopulation.Granary * current_buildings.Granary
    let HousingPop = BuildingsPopulation.Housing * current_buildings.Housing
    let AmphitheaterPop = BuildingsPopulation.Amphitheater * current_buildings.Amphitheater
    let ArcherTowerPop = BuildingsPopulation.ArcherTower * current_buildings.ArcherTower
    let SchoolPop = BuildingsPopulation.School * current_buildings.School
    let MageTowerPop = BuildingsPopulation.MageTower * current_buildings.MageTower
    let TradeOfficePop = BuildingsPopulation.TradeOffice * current_buildings.TradeOffice
    let ArchitectPop = BuildingsPopulation.Architect * current_buildings.Architect
    let ParadeGroundsPop = BuildingsPopulation.ParadeGrounds * current_buildings.ParadeGrounds
    let BarracksPop = BuildingsPopulation.Barracks * current_buildings.Barracks
    let DockPop = BuildingsPopulation.Dock * current_buildings.Dock
    let FishmongerPop= BuildingsPopulation.Fishmonger * current_buildings.Fishmonger
    let FarmsPop = BuildingsPopulation.Farms * current_buildings.Farms
    let HamletPop = BuildingsPopulation.Hamlet * current_buildings.Hamlet

    let totalPopulation = 100 + CastlePop + FairgroundsPop + RoyalReservePop + GrandMarketPop + GuildPop + OfficerAcademyPop + GranaryPop + HousingPop + AmphitheaterPop + ArcherTowerPop + SchoolPop + MageTowerPop + TradeOfficePop + ArchitectPop + ParadeGroundsPop + BarracksPop + DockPop + FishmongerPop + FarmsPop + HamletPop

    return (population=totalPopulation)
end

@view
func calculateFood{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (food : felt):
    let (controller) = MODULE_controller_address()

    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings
    )

    let (current_buildings : RealmBuildings) = IL03_Buildings.fetch_buildings_by_type(
        buildings_logic_address, tokenId
    )

    let CastleFood = BuildingsFood.Castle * current_buildings.Castle
    let FairgroundsFood = BuildingsFood.Fairgrounds * current_buildings.Fairgrounds
    let RoyalReserveFood = BuildingsFood.RoyalReserve * current_buildings.RoyalReserve
    let GrandMarketFood = BuildingsFood.GrandMarket * current_buildings.GrandMarket
    let GuildFood = BuildingsFood.Guild * current_buildings.Guild
    let OfficerAcademyFood = BuildingsFood.OfficerAcademy * current_buildings.OfficerAcademy
    let GranaryFood = BuildingsFood.Granary * current_buildings.Granary
    let HousingFood = BuildingsFood.Housing * current_buildings.Housing
    let AmphitheaterFood = BuildingsFood.Amphitheater * current_buildings.Amphitheater
    let ArcherTowerFood = BuildingsFood.ArcherTower * current_buildings.ArcherTower
    let SchoolFood = BuildingsFood.School * current_buildings.School
    let MageTowerFood = BuildingsFood.MageTower * current_buildings.MageTower
    let TradeOfficeFood = BuildingsFood.TradeOffice * current_buildings.TradeOffice
    let ArchitectFood = BuildingsFood.Architect * current_buildings.Architect
    let ParadeGroundsFood = BuildingsFood.ParadeGrounds * current_buildings.ParadeGrounds
    let BarracksFood = BuildingsFood.Barracks * current_buildings.Barracks
    let DockFood = BuildingsFood.Dock * current_buildings.Dock
    let FishmongerFood = BuildingsFood.Fishmonger * current_buildings.Fishmonger
    let FarmsFood = BuildingsFood.Farms * current_buildings.Farms
    let HamletFood = BuildingsFood.Hamlet * current_buildings.Hamlet

    let totalFood = 10 + CastleFood + FairgroundsFood + RoyalReserveFood + GrandMarketFood + GuildFood + OfficerAcademyFood + GranaryFood +HousingFood + AmphitheaterFood + ArcherTowerFood + SchoolFood + MageTowerFood + TradeOfficeFood + ArchitectFood + ParadeGroundsFood + BarracksFood + DockFood + FishmongerFood + FarmsFood + HamletFood

    return (food=totalFood)
end

@view
func calculateTribute{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (tribute : felt):
    # calculate number of buildings realm has

    return (tribute=100)
end

@view
func calculate_wonder_tax{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    tax_percentage : felt
):
    alloc_locals

    let (controller) = MODULE_controller_address()

    let (settle_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L01_Settling
    )

    let (realms_settled) = IS01_Settling.get_total_realms_settled(
        contract_address=settle_state_address
    )

    let (less_than_tenth_settled) = is_nn_le(realms_settled, 1600)

    if less_than_tenth_settled == 1:
        return (tax_percentage=25)
    else:
        # TODO:
        # hardcode a max %
        # use basis points
        let (tax, _) = unsigned_div_rem(8000 * 5, realms_settled)
        return (tax_percentage=tax)
    end
end
