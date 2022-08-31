%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn

from contracts.settling_game.modules.coordinates.library import Coordinates

from contracts.settling_game.utils.constants import FARM_LENGTH, GENESIS_TIMESTAMP
from contracts.settling_game.utils.game_structs import (
    RealmData,
    RealmBuildingsIds,
    FoodBuildings,
    Point,
)

const TEST_X1 = 287471
const TEST_Y1 = -189200
const TEST_X2 = 1140133
const TEST_Y2 = 5246

@external
func test_calculate_distance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (distance) = Coordinates.calculate_distance(
        Point(TEST_X1, TEST_Y1), Point(TEST_X2, TEST_Y2)
    )

    %{ print('Distance:', ids.distance) %}

    return ()
end

@external
func test_time{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (distance) = Coordinates.calculate_distance(
        Point(TEST_X1, TEST_Y1), Point(TEST_X2, TEST_Y2)
    )

    let (time) = Coordinates.calculate_time(distance)

    %{ print('Time:', ids.time) %}

    return ()
end

namespace TEST_REALM_1:
    const regions = 10
    const cities = 4
    const harbours = 4
    const rivers = 4
    const resource_number = 4
    const resource_1 = 1
    const resource_2 = 2
    const resource_3 = 3
    const resource_4 = 4
    const resource_5 = 0
    const resource_6 = 0
    const resource_7 = 0
    const wonder = 0
    const order = 2
    const point_x = 150
    const point_y = 2
end
