# ____MODULE_L04___CONTRACT_LOGIC
#   This modules focus is to calculate the values of the internal
#   multipliers so other modules can use them. The aim is to have this
#   as the core calculator controller that contains no state.
#   It is pure math.
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_nn_le, is_nn, is_le
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.utils.game_structs import (
    RealmBuildings,
    ModuleIds,
    BuildingsFood,
    BuildingsPopulation,
    BuildingsCulture,
    RealmCombatData,
)

from contracts.settling_game.utils.constants import VAULT_LENGTH_SECONDS, BASE_LORDS_PER_DAY

from contracts.settling_game.interfaces.imodules import (
    IModuleController,
    IL01_Settling,
    IL03_Buildings,
    IL06_Combat,
)

from contracts.settling_game.library.library_module import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
)

from contracts.settling_game.library.library_calculator import CALCULATOR

from openzeppelin.upgrades.library import (
    Proxy_initializer,
    Proxy_only_admin,
    Proxy_set_implementation,
)

from contracts.settling_game.library.library_combat import COMBAT

###############
# CONSTRUCTOR #
###############

@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt, proxy_admin : felt
):
    MODULE_initializer(address_of_controller)
    Proxy_initializer(proxy_admin)
    return ()
end

@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy_only_admin()
    Proxy_set_implementation(new_implementation)
    return ()
end

###############
# CALCULATORS #
###############

@view
func calculate_epoch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    epoch : felt
):
    # CALCULATE EPOCH
    let (controller) = MODULE_controller_address()
    let (genesis_time_stamp) = IModuleController.get_genesis(controller)
    let (block_timestamp) = get_block_timestamp()

    let (epoch, _) = unsigned_div_rem(block_timestamp - genesis_time_stamp, VAULT_LENGTH_SECONDS)
    return (epoch=epoch)
end

@view
func calculate_happiness{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (happiness : felt):
    alloc_locals

    # FETCH VALUES
    let (population) = calculate_population(token_id)
    let (food) = calculate_food(token_id)

    # GET HAPPINESS
    let (happiness) = CALCULATOR.get_happiness(population, food)

    return (happiness)
end

@view
func calculate_troop_population{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (troop_population : felt):
    alloc_locals

    # SUM TOTAL TROOP POPULATION
    # let (controller) = MODULE_controller_address()
    # let (combat_logic) = IModuleController.get_module_address(controller, ModuleIds.L06_Combat)
    # let (realm_combat_data : RealmCombatData) = IL06_Combat.get_realm_combat_data(
    #     combat_logic, token_id
    # )

    # let (attacking_population) = COMBAT.get_troop_population(realm_combat_data.attacking_squad)
    # let (defending_population) = COMBAT.get_troop_population(realm_combat_data.defending_squad)

    return (0)
end

@view
func calculate_population{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (population : felt):
    alloc_locals

    # SUM TOTAL POPULATION
    let (controller) = MODULE_controller_address()
    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings
    )
    let (current_buildings : RealmBuildings) = IL03_Buildings.get_effective_buildings(
        buildings_logic_address, token_id
    )

    let House = BuildingsPopulation.House * current_buildings.House
    let StoreHouse = BuildingsPopulation.StoreHouse * current_buildings.StoreHouse
    let Granary = BuildingsPopulation.Granary * current_buildings.Granary
    let Farm = BuildingsPopulation.Farm * current_buildings.Farm
    let FishingVillage = BuildingsPopulation.FishingVillage * current_buildings.FishingVillage
    let Barracks = BuildingsPopulation.Barracks * current_buildings.Barracks
    let MageTower = BuildingsPopulation.MageTower * current_buildings.MageTower
    let ArcherTower = BuildingsPopulation.ArcherTower * current_buildings.ArcherTower
    let Castle = BuildingsPopulation.Castle * current_buildings.Castle

    let population = House + StoreHouse + Granary + Farm + FishingVillage + Barracks + MageTower + ArcherTower + Castle

    # TROOP POPULATION
    let (troop_population) = calculate_troop_population(token_id)

    return (population - troop_population)
end

@view
func calculate_food{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (food : felt):
    alloc_locals

    # CALCULATE FOOD
    let (controller) = MODULE_controller_address()
    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings
    )
    let (current_buildings : RealmBuildings) = IL03_Buildings.get_effective_buildings(
        buildings_logic_address, token_id
    )

    let House = BuildingsFood.House * current_buildings.House
    let StoreHouse = BuildingsFood.StoreHouse * current_buildings.StoreHouse
    let Granary = BuildingsFood.Granary * current_buildings.Granary
    let Farm = BuildingsFood.Farm * current_buildings.Farm
    let FishingVillage = BuildingsFood.FishingVillage * current_buildings.FishingVillage
    let Barracks = BuildingsFood.Barracks * current_buildings.Barracks
    let MageTower = BuildingsFood.MageTower * current_buildings.MageTower
    let ArcherTower = BuildingsFood.ArcherTower * current_buildings.ArcherTower
    let Castle = BuildingsFood.Castle * current_buildings.Castle

    let food = House + StoreHouse + Granary + Farm + FishingVillage + Barracks + MageTower + ArcherTower + Castle

    let (troop_population) = calculate_troop_population(token_id)

    return (food - troop_population)
end

# TODO: Make LORDS decrease over time...
@view
func calculate_tribute{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    tribute : felt
):
    # TOD0: Decreasing supply curve of Lords
    # calculate number of buildings realm has

    return (tribute=BASE_LORDS_PER_DAY)
end

@view
func calculate_wonder_tax{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    tax_percentage : felt
):
    alloc_locals

    # CALCULATE WONDER TAX
    let (controller) = MODULE_controller_address()
    let (settle_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.L01_Settling
    )

    let (realms_settled) = IL01_Settling.get_total_realms_settled(settle_state_address)

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
