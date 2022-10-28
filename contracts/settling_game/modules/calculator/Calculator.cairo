// -----------------------------------
//   Module.Calculator
//   This modules focus is to calculate the values of the internal
//   multipliers so other modules can use them. The aim is to have this
//   as the core calculator controller that contains no state.
//   It is pure math.
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_nn_le, is_nn, is_le, is_not_zero
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.upgrades.library import Proxy
from openzeppelin.token.erc721.IERC721 import IERC721

from contracts.settling_game.utils.game_structs import (
    RealmBuildings,
    ModuleIds,
    BuildingsPopulation,
    RealmCombatData,
    ExternalContractIds,
)
from contracts.settling_game.modules.calculator.library import Calculator
from contracts.settling_game.utils.constants import (
    VAULT_LENGTH_SECONDS,
    BASE_LORDS_PER_DAY,
    DAY,
    CCalculator,
)
from contracts.settling_game.modules.settling.interface import ISettling
from contracts.settling_game.interfaces.imodules import IModuleController
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.modules.combat.interface import ICombat
from contracts.settling_game.modules.buildings.interface import IBuildings
from contracts.settling_game.modules.food.interface import IFood
from contracts.settling_game.modules.relics.interface import IRelics

// TODO: increase decay of buildings if unhappy
// TODO: stop workhut increases if unhappy - needs test

// -----------------------------------
// Initialize & upgrade
// -----------------------------------

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address_of_controller: felt, proxy_admin: felt
) {
    Module.initializer(address_of_controller);
    Proxy.initializer(proxy_admin);
    return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

// -----------------------------------
// Epoch and Day Calculator
// -----------------------------------

// @notice Calculates epoch of game. On deployment of game a timestamp is set, an epoch is the length of the vault.
// @returns epoch: of game as a felt.
@view
func calculate_epoch{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    epoch: felt
) {
    // CALCULATE EPOCH
    let (controller) = Module.controller_address();
    let (genesis_time_stamp) = IModuleController.get_genesis(controller);
    let (block_timestamp) = get_block_timestamp();

    let (epoch, _) = unsigned_div_rem(block_timestamp - genesis_time_stamp, VAULT_LENGTH_SECONDS);
    return (epoch=epoch);
}

// @notice Calculates day number in the game. Used for deterministic values.
// @returns day: of the game.
@view
func calculate_day_number{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    day: felt
) {
    let (controller) = Module.controller_address();
    let (genesis_time_stamp) = IModuleController.get_genesis(controller);
    let (block_timestamp) = get_block_timestamp();

    let (day, _) = unsigned_div_rem(block_timestamp - genesis_time_stamp, DAY);
    return (day,);
}

// -----------------------------------
// Happiness Calculators
// -----------------------------------

// @notice Checks if the Realm is Happy or Not.
// @returns is_happy: TRUE(1) for Happy, FALSE(0) if unhappy
@view
func is_realm_happy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (is_happy: felt) {
    // get actual happiness value
    let (happiness) = calculate_happiness(token_id);

    // check if happiness is over or equal to base happiness
    let is_happy = is_le(happiness, CCalculator.BASE_HAPPINESS);

    return (is_happy=is_happy);
}

// @notice Calculates the total happiness on the Realm. This is a big number 0 - 200.
// @param token_id: Realm ID
// @returns happiness: actual happiness value as a number.
@view
func calculate_happiness{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (happiness: felt) {
    alloc_locals;
    // random
    let (daily_randomness_value) = calculate_daily_randomness(token_id);

    let (controller) = Module.controller_address();

    // get available food - check if serfs are starving.
    let (food_addr) = IModuleController.get_module_address(controller, ModuleIds.L10_Food);
    let (available_food_in_store) = IFood.available_food_in_store(food_addr, token_id);
    let is_starving = is_le(available_food_in_store, 1);

    if (is_starving == TRUE) {
        tempvar no_food_loss = CCalculator.NO_FOOD_LOSS;
    } else {
        tempvar no_food_loss = 0;
    }

    // check if relic is owned - if not subtract
    let (relic_addr) = IModuleController.get_module_address(controller, ModuleIds.L09_Relics);
    let (is_relic_at_home) = IRelics.is_relic_at_home(relic_addr, token_id);

    if (is_relic_at_home == FALSE) {
        tempvar no_relic_loss = CCalculator.NO_RELIC_LOSS;
    } else {
        tempvar no_relic_loss = 0;
    }

    // does a Defending Army exist on a Realm? - if yes, add
    // 0 is for Defending Army ID
    let (combat_addr) = IModuleController.get_module_address(controller, ModuleIds.L06_Combat);
    let (defending_army) = ICombat.get_realm_army_combat_data(combat_addr, 0, token_id);
    let has_defending_army = is_not_zero(defending_army.packed);

    if (has_defending_army == FALSE) {
        tempvar no_defending_army_loss = CCalculator.NO_DEFENDING_ARMY_LOSS;
    } else {
        tempvar no_defending_army_loss = 0;
    }

    return (
        CCalculator.BASE_HAPPINESS + daily_randomness_value + no_defending_army_loss + no_food_loss + no_relic_loss,
    );
}

// -----------------------------------
// Population Calculators
// -----------------------------------

// @notice Calculates the population of all the Armies that exist on a Realm.
// @param token_id: Realm ID
// @returns population: of all the Armies on the Realm.
@view
func calculate_armies_population{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (population: felt) {
    let (controller) = Module.controller_address();
    let (combat) = IModuleController.get_module_address(controller, ModuleIds.L06_Combat);
    let (armies_population) = ICombat.get_population_of_armies(combat, token_id);

    return (population=armies_population);
}

// @notice Calculates the total population of the Realm. Armies + Buildings.
// @param token_id: Realm ID
// @returns population: of entire Realm
@view
func calculate_population{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (population: felt) {
    let (controller) = Module.controller_address();
    let (buildings_address) = IModuleController.get_module_address(controller, ModuleIds.Buildings);
    let (current_buildings: RealmBuildings) = IBuildings.get_effective_population_buildings(
        buildings_address, token_id
    );

    // Army Population
    let (army_population) = calculate_armies_population(token_id);

    // Realm Population
    let realm_population = Calculator.calculate_population(current_buildings);

    return (population=realm_population + army_population);
}

// TODO: We could move this to the controller??
// TOOD: The issue with this approach is that it is entirely deterministic to the game. You will be able to see
//        if the future what numbers will come up. This could be solved by adding a random number saved to the MC every 24hrs which is then used in the calc.
@view
func calculate_daily_randomness{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (random_number: felt) {
    let (controller) = Module.controller_address();
    let (address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms
    );
    let (owner) = IERC721.ownerOf(address, token_id);

    // Day number is the evolving value. When the days tick over a new number appears.
    // This avoids us having to do any writes. Can be upgraded to use random number in future. To make it
    // probabilistic we can set a new random number every day with yagi and use it. This way you can't predict it.
    let (day_number) = calculate_day_number();

    // returns ID of event - a number between 0 - NUMBER_OF_RANDOM_EVENTS
    let (_, random_number) = unsigned_div_rem(
        owner + token_id.low * day_number, CCalculator.NUMBER_OF_RANDOM_EVENTS
    );

    // get actual value using the random ID
    let get_randomness_value = Calculator.get_randomness_value(random_number);

    return (get_randomness_value,);
}
