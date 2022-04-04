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
    TRUE, FALSE, GENESIS_TIMESTAMP, VAULT_LENGTH_SECONDS)

from contracts.settling_game.interfaces.imodules import (
    IModuleController, IS01_Settling, IL03_Buildings)

from contracts.settling_game.utils.library import (
    MODULE_controller_address, MODULE_only_approved, MODULE_initializer)

# ____MODULE_L04___CONTRACT_LOGIC

# This modules focus is to calculate the values of the internal
# multipliers so other modules can use them. The aim is to have this
# as the core calculator controller that contains no state.
# It is pure math.

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    # Store the address of the only fixed contract in the system.
    MODULE_initializer(address_of_controller)
    return ()
end

@view
func calculate_epoch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        epoch : felt):
    let (controller) = MODULE_controller_address()

    let (genesis_time_stamp) = IModuleController.get_genesis(contract_address=controller)

    let (block_timestamp) = get_block_timestamp()

    let (epoch, _) = unsigned_div_rem(block_timestamp - genesis_time_stamp, VAULT_LENGTH_SECONDS)
    return (epoch=epoch)
end

@view
func calculateHappiness{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (happiness : felt):
    alloc_locals
    # calculate number of buildings realm has
    # happiness = (culture-(population/100)) + (food-(population/100))
    let (local culture : felt) = calculateCulture(tokenId)
    let (local population : felt) = calculatePopulation(tokenId)
    let (local food : felt) = calculateFood(tokenId)

    let happiness = (culture - (population / 100)) + (food - (population / 100))
    return (happiness=happiness)
end

@view
func calculateCulture{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (culture : felt):
    let (controller) = MODULE_controller_address()

    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings)

    let (current_buildings : RealmBuildings) = IL03_Buildings.fetch_buildings_by_type(
        buildings_logic_address, tokenId)

    let culture = 25 + (current_buildings.Amphitheater) + (current_buildings.Guild * 5) + (current_buildings.Castle * 5) + (current_buildings.Fairgrounds * 5)
    return (culture=culture)
end

@view
func calculatePopulation{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (population : felt):
    let (controller) = MODULE_controller_address()

    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings)

    let (current_buildings : RealmBuildings) = IL03_Buildings.fetch_buildings_by_type(
        buildings_logic_address, tokenId)

    let population = 1000 + (RealmBuildings.Housing * 100)
    return (population=population)
end

@view
func calculateFood{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (food : felt):
    let (controller) = MODULE_controller_address()

    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings)

    let (current_buildings : RealmBuildings) = IL03_Buildings.fetch_buildings_by_type(
        buildings_logic_address, tokenId)

    # food = 25 + (# of farms) + (2 * # of granaries) + (6 * # of fairgrounds) + (6 * # of royal reserves) + (6 * # of grand markets) - (# of city structures) - (# of troops)

    # TODO @milan add in # of troops
    let food = 25 + (RealmBuildings.Farms) + (RealmBuildings.Granary) + (RealmBuildings.Fairgrounds * 5) + (RealmBuildings.RoyalReserve * 5) - (20)
    return (food=food)
end

@view
func calculateTribute{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (tribute : felt):
    # calculate number of buildings realm has

    return (tribute=100)
end

@view
func calculate_wonder_tax{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        tax_percentage : felt):
    alloc_locals

    let (controller) = MODULE_controller_address()

    let (settle_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S01_Settling)

    let (realms_settled) = IS01_Settling.get_total_realms_settled(
        contract_address=settle_state_address)

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
