%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, sqrt
from starkware.cairo.common.pow import pow

from contracts.settling_game.modules.travel.library import Travel, PRECISION

from contracts.settling_game.utils.constants import SECONDS_PER_KM
from contracts.settling_game.utils.game_structs import Point

const offset = 1800000

const TEST_X1 = (307471) + offset

const TEST_Y1 = (-96200) + offset

const TEST_X2 = (685471) + offset

const TEST_Y2 = (419800) + offset

@external
func test_calculate_distance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (distance) = Travel.calculate_distance(Point(TEST_X1, TEST_Y1), Point(TEST_X2, TEST_Y2))

    let (x) = pow(TEST_X2 - TEST_X1, 2)
    let (y) = pow(TEST_Y2 - TEST_Y1, 2)

    let (sqr_distance) = sqrt(x + y)

    let (d, _) = unsigned_div_rem(sqr_distance, PRECISION)

    assert d = distance
    %{ print('Distance:', ids.distance) %}
    return ()
end

@external
func test_time{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (distance) = Travel.calculate_distance(Point(TEST_X1, TEST_Y1), Point(TEST_X2, TEST_Y2))

    let (time) = Travel.calculate_time(distance)

    assert time = distance * SECONDS_PER_KM
    %{ print('Time:', ids.time) %}
    return ()
end
