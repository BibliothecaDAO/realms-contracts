%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.general import scale
from contracts.settling_game.utils.interfaces import IModuleController
from contracts.settling_game.utils.game_structs import (
    RealmBuildings, RealmBuildingCostIds, RealmBuildingCostValues)

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721

const HAPPINESS = 25
const AMPHITHEATER = 1
const CARPENTER = 1
const CASTLE = 1
const DOCK = 1
const EXPLORERS_GUILD = 1
const FAIRGROUNDS = 1
const FARMS = 1
const GRANARY = 1
const GRAND_MARKET = 1
const HOUSING = 1
const GUILD = 1
const LOGISTICS_OFFICE = 1
const OFFICER_ACADEMY = 1
const PARADE_GROUNDS = 1
const RESOURCE_FACILITY = 1
const ROYAL_RESERVE = 1
const SCHOOL = 1
const SYMPOSIUM = 1

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
    # Calculates culture based on the level of existing buildings
    # Idea to extend: surplus
    let culture = 25 + (AMPHITHEATER) + (GUILD * 5) + (CASTLE * 5) + (FAIRGROUNDS * 5)
    return (culture=culture)
end

@external
func calculatePopulation{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (population : felt):
    # calculate number of buildings realm has
    let population = 1000 + (HOUSING * 100)
    return (population=population)
end

@external
func calculateFood{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (food : felt):
    # food = 25 + (# of farms) + (2 * # of granaries) + (6 * # of fairgrounds) + (6 * # of royal reserves) + (6 * # of grand markets) - (# of city structures) - (# of troops)
    let food = 25 + (FARMS) + (GRANARY) + (FAIRGROUNDS * 5) + (ROYAL_RESERVE * 5) - (20)
    return (food=food)
end

@external
func calculateTribute{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256) -> (tribute : felt):
    # calculate number of buildings realm has

    return (tribute=100)
end
