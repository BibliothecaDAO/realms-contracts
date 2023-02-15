%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, sqrt
from starkware.cairo.common.pow import pow
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.settling_game.modules.travel.library import Travel, PRECISION
from contracts.settling_game.modules.travel.travel import assert_can_travel

from contracts.settling_game.utils.constants import SECONDS_PER_KM
from contracts.settling_game.utils.game_structs import Point

const offset = 1800000;

const TEST_X1 = (307471) + offset;

const TEST_Y1 = (-96200) + offset;

const TEST_X2 = (685471) + offset;

const TEST_Y2 = (419800) + offset;

const TRAVELLER_CONTRACT_ID = 1;
const TRAVELLER_TOKEN_ID = 1;
const TRAVELLER_NESTED_ID = 1;

@external
func test_travel_when_forbid_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    let (self_address) = get_contract_address();
    %{ store(ids.self_address, "cannot_travel", [1], [ids.TRAVELLER_CONTRACT_ID, ids.TRAVELLER_TOKEN_ID, ids.TRAVELLER_NESTED_ID]) %}
    %{ expect_revert() %}
    assert_can_travel(TRAVELLER_CONTRACT_ID, TRAVELLER_TOKEN_ID, TRAVELLER_NESTED_ID);
    return ();
}

@external
func test_travel_when_allowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> () {
    assert_can_travel(TRAVELLER_CONTRACT_ID, TRAVELLER_TOKEN_ID, TRAVELLER_NESTED_ID);
    return ();
}

@external
func test_calculate_distance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (distance) = Travel.calculate_distance(Point(TEST_X1, TEST_Y1), Point(TEST_X2, TEST_Y2));

    let (x) = pow(TEST_X2 - TEST_X1, 2);
    let (y) = pow(TEST_Y2 - TEST_Y1, 2);

    let sqr_distance = sqrt(x + y);

    let (d, _) = unsigned_div_rem(sqr_distance, PRECISION);

    assert d = distance;
    %{ print('Distance:', ids.distance) %}
    return ();
}

@external
func test_time{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (distance) = Travel.calculate_distance(Point(TEST_X1, TEST_Y1), Point(TEST_X2, TEST_Y2));

    let (time) = Travel.calculate_time(distance);

    assert time = distance * SECONDS_PER_KM;
    %{ print('Time:', ids.time) %}
    return ();
}
