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
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.game_structs import RealmBuildings, ModuleIds

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
    Proxy_set_implementation,
    Proxy_get_implementation,
    Proxy_set_admin,
    Proxy_get_admin,
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
func calculateHappiness{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    tokenId : Uint256
) -> (happiness : felt):
    alloc_locals

    let (local culture : felt) = calculateCulture(tokenId)
    let (local population : felt) = calculatePopulation(tokenId)
    let (local food : felt) = calculateFood(tokenId)

    let happiness = (culture - (population / 100)) + (food - (population / 100))

    return (happiness=100)
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

    let culture = 25 + (current_buildings.Amphitheater * 2) + (current_buildings.Guild * 5) + (current_buildings.Castle * 5) + (current_buildings.Fairgrounds * 5) + (current_buildings.Architect * 1) + (current_buildings.TradeOffice * 1) + (current_buildings.ParadeGrounds * 1) + (current_buildings.School * 3)
    return (culture=culture)
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

    let population = 1000 + (RealmBuildings.Housing * 75) + (RealmBuildings.Hamlet * 35) + (RealmBuildings.Farms * 10)
    return (population=population)
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

    let castleImpact = RealmBuildings.Castle * 1
    let fairgroundsImpact = RealmBuildings.Fairgrounds * 5
    let grandMarketImpact = RealmBuildings.GrandMarket * 5
    let guildImpact = RealmBuildings.Guild * 1
    let officerAcademyImpact = RealmBuildings.OfficerAcademy * 1
    let royalReserveImpact = RealmBuildings.RoyalReserve * 5
    let amphitheaterImpact = RealmBuildings.Amphitheater * 1
    let archerTowerImpact = RealmBuildings.ArcherTower * 1
    let barracksImpact = RealmBuildings.Barracks * 1
    let dockImpact = RealmBuildings.Dock * 1
    let farmImpact = RealmBuildings.Farms * 1
    let fishMongerImpact = RealmBuildings.Fishmonger * 2
    let granaryImpact = RealmBuildings.Granary * 3
    let tradeOfficeImpact = RealmBuildings.TradeOffice * 1
    let hamletImpact = RealmBuildings.Hamlet * 1
    let housingImpact = RealmBuildings.Housing * 1
    let mageTowerImpact = RealmBuildings.MageTower * 1
    let paradeGroundsImpact = RealmBuildings.ParadeGrounds * 1
    let schoolImpact = RealmBuildings.School * 1

    let food = 25 - castleImpact + fairgroundsImpact + grandMarketImpact - guildImpact - officerAcademyImpact + royalReserveImpact - amphitheaterImpact - archerTowerImpact - barracksImpact - dockImpact + farmImpact + fishMongerImpact + granaryImpact - tradeOfficeImpact + hamletImpact - housingImpact - mageTowerImpact - paradeGroundsImpact - schoolImpact

    return (food=food)
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
        contract_address=controller, module_id=ModuleIds.S01_Settling
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
