%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn

from contracts.settling_game.modules.coordinates.library import Coordinates

from contracts.settling_game.utils.constants import FARM_LENGTH, GENESIS_TIMESTAMP
from contracts.settling_game.utils.game_structs import RealmData, RealmBuildingsIds, FoodBuildings

const TEST_X1 = 2
const TEST_Y1 = 2
const TEST_X2 = 2
const TEST_Y2 = 100

@external
func test_calculate_distance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (distance) = Coordinates.calculate_distance(TEST_X1, TEST_Y1, TEST_X2, TEST_Y2)

    %{ print('Distance:', ids.distance) %}

    return ()
end

@external
func test_time{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (distance) = Coordinates.calculate_distance(TEST_X1, TEST_Y1, TEST_X2, TEST_Y2)

    let (time) = Coordinates.calculate_time(distance)

    %{ print('Time:', ids.time) %}

    return ()
end
