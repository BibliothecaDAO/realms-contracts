%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, sqrt
from starkware.cairo.common.pow import pow

from contracts.settling_game.modules.coordinates.library import Coordinates, PRECISION

from contracts.settling_game.utils.constants import SECONDS_PER_KM
from contracts.settling_game.utils.game_structs import Point

const TEST_X1 = -287471
const TEST_Y1 = -189200
const TEST_X2 = -1140133
const TEST_Y2 = -5246

@external
func test_calculate_distance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (distance) = Coordinates.calculate_distance(
        Point(TEST_X1, TEST_Y1), Point(TEST_X2, TEST_Y2)
    )

    let (x) = pow(TEST_X2 - TEST_X1, 2)
    let (y) = pow(TEST_Y2 - TEST_Y1, 2)

    let (sqr_distance) = sqrt(x + y)

    let (d, _) = unsigned_div_rem(sqr_distance, PRECISION)

    assert d = distance

    return ()
end

@external
func test_time{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (distance) = Coordinates.calculate_distance(
        Point(TEST_X1, TEST_Y1), Point(TEST_X2, TEST_Y2)
    )

    let (time) = Coordinates.calculate_time(distance)

    assert time = distance * SECONDS_PER_KM

    return ()
end

@external
func test_radial{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (distance) = Coordinates.to_radial(TEST_X1)

    %{ print('Realm Happiness:', ids.distance) %}

    return ()
end
