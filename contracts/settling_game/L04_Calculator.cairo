%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.general import scale
from contracts.settling_game.utils.game_structs import (
    RealmBuildings, RealmBuildingCostIds, RealmBuildingCostValues, ModuleIds)

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721
from contracts.settling_game.interfaces.imodules import IModuleController, IL03_Buildings

# #### Module 4A #####
#                   #
# Calculator Logic  #
#                   #
#####################
# This module focus is to calculate the values of the internal multipliers so other modules can use them. The aim is to have this as the core calculator controller that contains no state. It is pure math.

@storage_var
func controller_address() -> (address : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    # Store the address of the only fixed contract in the system.
    controller_address.write(address_of_controller)
    return ()
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

@external
func calculateCulture{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (culture : felt):
    let (controller) = controller_address.read()

    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings)

    let (current_buildings : RealmBuildings) = IL03_Buildings.fetch_buildings_by_type(
        buildings_logic_address, tokenId)

    let culture = 25 + (current_buildings.Amphitheater) + (current_buildings.Guild * 5) + (current_buildings.Castle * 5) + (current_buildings.Fairgrounds * 5)
    return (culture=culture)
end

@external
func calculatePopulation{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (population : felt):
    let (controller) = controller_address.read()

    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings)

    let (current_buildings : RealmBuildings) = IL03_Buildings.fetch_buildings_by_type(
        buildings_logic_address, tokenId)

    let population = 1000 + (RealmBuildings.Housing * 100)
    return (population=population)
end

@external
func calculateFood{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (food : felt):
    let (controller) = controller_address.read()

    let (buildings_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L03_Buildings)

    let (current_buildings : RealmBuildings) = IL03_Buildings.fetch_buildings_by_type(
        buildings_logic_address, tokenId)

    # food = 25 + (# of farms) + (2 * # of granaries) + (6 * # of fairgrounds) + (6 * # of royal reserves) + (6 * # of grand markets) - (# of city structures) - (# of troops)

    # TODO @milan add in # of troops
    let food = 25 + (RealmBuildings.Farms) + (RealmBuildings.Granary) + (RealmBuildings.Fairgrounds * 5) + (RealmBuildings.RoyalReserve * 5) - (20)
    return (food=food)
end

@external
func calculateTribute{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (tribute : felt):
    # calculate number of buildings realm has

    return (tribute=100)
end
