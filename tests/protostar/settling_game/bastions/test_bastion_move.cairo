%lang starknet
// starkware
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_contract_address

// settling game
from contracts.settling_game.modules.bastions.constants import MovingTimes
from contracts.settling_game.modules.bastions.bastions import bastion_move, get_move_block_time
from contracts.settling_game.modules.travel.travel import set_coordinates, get_coordinates
from contracts.settling_game.modules.combat.interface import ICombat
from contracts.settling_game.ModuleController import (
    get_module_address,
    get_external_contract_address,
    has_write_access,
    set_write_access,
)
from contracts.settling_game.utils.general import unpack_data
from contracts.settling_game.tokens.S_Realms_ERC721_Mintable import ownerOf
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.tokens.Realms_ERC721_Mintable import fetch_realm_data
from contracts.settling_game.modules.combat.library import Combat
from contracts.settling_game.utils.game_structs import (
    TravelInformation,
    ExternalContractIds,
    Point,
    ModuleIds,
)

from tests.protostar.settling_game.bastions.setup import setup
// mockups
from tests.protostar.settling_game.bastions.mockups.CombatMockup import (
    get_realm_army_combat_data,
    initiate_combat_approved_module,
    build_army_without_health,
    build_army_with_health,
    army_data_by_id,
)
from tests.protostar.settling_game.bastions.mockups.TravelMockup import forbid_travel, allow_travel

const X = 3;
const Y = 4;

const ARMY_ID_1 = 1;
const ARMY_ID_2 = 2;

const ORDER_OF_GIANTS = 2;
const ORDER_OF_RAGE = 10;
const ORDER_OF_FURY = 11;

// ORDER OF GIANTS
const REALM_ID_1 = 1;
const REALM_DATA_1 = 40564819207303341694527483217926;  // realm 1: order of giants

const REALM_ID_2 = 2;
const REALM_DATA_2 = 40564819207303340854496404575491;  // realm 20: order of giants

// ORDER OF RAGE
const REALM_ID_3 = 3;
const REALM_DATA_3 = 202824096036516993033911502441218;  // realm 3: order of rage

const REALM_ID_4 = 4;
const REALM_DATA_4 = 202824096041331521743613694971653;  // realm 107: order of rage

// ORDER OF FURY
const REALM_ID_5 = 5;
const REALM_DATA_5 = 223106505663891104000887212282119;  // realm 102: order of fury

const REALM_ID_6 = 6;
const REALM_DATA_6 = 223106505640169024313176976593412;  // realm 114: order of fury

const BONUS_TYPE = 11;

// 2 minutes
const TOWER_COOLDOWN_PERIOD = 2;
// 2 hours => 120 blocks
const CENTRAL_SQUARE_COOLDOWN_PERIOD = 120;

// staging are
const STAGING_AREA_ID = 0;

// towers
const TOWER_1_ID = 1;
const TOWER_2_ID = 2;
const TOWER_3_ID = 3;
const TOWER_4_ID = 4;

// central square
const CENTRAL_SQUARE_ID = 5;

@external
func __setup__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    setup();
    return ();
}

@external
func test_bastion_move_invalid_location_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: invalid locatio") %}
    // MOVE
    bastion_move(Point(X, Y), 6, Uint256(REALM_ID_1, 0), ARMY_ID_1);

    return ();
}

@external
func test_bastion_move_no_bastion_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: No bastion as this location") %}
    // MOVE
    bastion_move(Point(0, 0), TOWER_1_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);

    return ();
}

@external
func test_bastion_move_wrong_coordinates_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="TRAVEL: You are not at this destination") %}

    // MOVE
    bastion_move(Point(X, Y), TOWER_1_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}

@external
func test_bastion_move_same_location_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    // change location of the army to be on bastion location
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: army is already on this location") %}

    // MOVE
    bastion_move(Point(X, Y), STAGING_AREA_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}

@external
func test_bastion_move_already_moving_army_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    const ARRIVAL_BLOCK = 10;

    // change location of the army to be on bastion location
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // make army currently moving
    %{
        store(context.self_address, "bastion_army_location", 
                   [ ids.ARRIVAL_BLOCK, ids.STAGING_AREA_ID], [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: army is currently moving") %}

    // MOVE
    bastion_move(Point(X, Y), TOWER_1_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}

// When an order not holding the central square tries to move to the central square,
// it needs to hold all 4 towers, if not it should fails
@external
func test_bastion_move_central_square_not_defending_order_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    const ARRIVAL_BLOCK = 10;
    %{ stop_roll = roll(10) %}

    // change location of the army to be on bastion location
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // make army currently moving
    %{
        store(context.self_address, "bastion_army_location", 
                   [ids.ARRIVAL_BLOCK, ids.STAGING_AREA_ID], [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: Need to conquer all towers") %}

    // MOVE
    bastion_move(Point(X, Y), CENTRAL_SQUARE_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}

// When the central square defending order does not have towers anymore,
// armies cannot go to the central square anymore
@external
func test_bastion_defending_order_move_central_square_no_towers_are_conquered_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    // change location of the army to be on bastion location
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // make army currently moving
    %{
        store(context.self_address, "bastion_army_location", 
                   [ 0, ids.STAGING_AREA_ID], [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // giants has central square, fury has all the towers
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_1_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_2_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_3_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_4_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.CENTRAL_SQUARE_ID]) %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: Central square defending order needs to have at least one tower") %}

    // MOVE
    bastion_move(Point(X, Y), CENTRAL_SQUARE_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}

@external
func test_bastion_defending_order_move_central_square_one_tower_is_unconquered_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    const ARRIVAL_BLOCK = 10;
    %{ stop_roll = roll(10) %}

    // change location of the army to be on bastion location
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // make army currently moving
    %{
        store(context.self_address, "bastion_army_location", 
                   [ ids.ARRIVAL_BLOCK, ids.STAGING_AREA_ID], [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // conquer 3 of the towers, last tower still not conquered
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_1_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_2_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_3_ID]) %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: Need to conquer all towers") %}

    // MOVE
    bastion_move(Point(X, Y), CENTRAL_SQUARE_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}

@external
func test_bastion_move_from_tower_to_non_adjacent_tower_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    // change location of the army to be on bastion location
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // put army on tower 1
    %{
        store(context.self_address, "bastion_army_location", 
                   [ 0, ids.TOWER_1_ID], [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: Can only move from tower to adjacent tower") %}

    // MOVE
    bastion_move(Point(X, Y), TOWER_3_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}

@external
func test_bastion_move_should_replace_if_current_movers_at_index{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    // change location of the army to be on bastion location
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_2])
    %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}

    // MOVE
    bastion_move(Point(X, Y), TOWER_1_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    // expect event
    %{
        expect_events({"name": "BastionArmyMoved", "data": 
                           [ids.X, ids.Y, ids.STAGING_AREA_ID, ids.TOWER_1_ID, ids.REALM_ID_1, 0, ids.ARMY_ID_1]})
    %}

    // should be at index 25, because current block = 0 and it takes 25 blocks to arrive
    // to tower from staging area
    const INDEX = 25;
    %{
        current_movers = load(context.self_address, "current_movers", "MoverData", 
                                  [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_GIANTS, ids.INDEX])
        assert current_movers == [25, 1]
    %}

    // roll to 35 so that new moving army replaces the old moving army on same index
    %{ stop_roll = roll(35) %}

    // MOVE
    bastion_move(Point(X, Y), TOWER_1_ID, Uint256(REALM_ID_1, 0), ARMY_ID_2);

    // expect event
    %{
        expect_events({"name": "BastionArmyMoved", "data": 
                           [ids.X, ids.Y, ids.STAGING_AREA_ID, ids.TOWER_1_ID, ids.REALM_ID_1, 0, ids.ARMY_ID_2]})
    %}

    // verify replacement in current movers
    %{
        current_movers = load(context.self_address, "current_movers", "MoverData", 
                                  [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_GIANTS, ids.INDEX])
        assert current_movers == [35 + 25, 1]
    %}

    // assert that the new army settled the old army by increasing location_count by 1
    %{
        location_count = load(context.self_address, "bastion_location_order_count", "felt", 
                                  [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_GIANTS])[0]

        assert location_count == 1
    %}

    return ();
}

@external
func test_bastion_move_central_square_all_towers_conquered{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    const ARRIVAL_BLOCK = 10;
    %{ stop_roll = roll(10) %}

    // change location of the army to be on bastion location
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // make army currently moving
    %{
        store(context.self_address, "bastion_army_location", 
                   [ids.ARRIVAL_BLOCK, ids.STAGING_AREA_ID], [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // conquer all 4 towers
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_1_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_2_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_3_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_4_ID]) %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}

    // MOVE
    bastion_move(Point(X, Y), CENTRAL_SQUARE_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);

    // expect event
    %{
        expect_events({"name": "BastionArmyMoved", "data": 
                           [ids.X, ids.Y, ids.STAGING_AREA_ID, ids.CENTRAL_SQUARE_ID, ids.REALM_ID_1, 0, ids.ARMY_ID_1]})
    %}
    return ();
}

@external
func test_bastion_move_verify_moving_times{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    const ARRIVAL_BLOCK = 10;
    %{ stop_roll = roll(10) %}

    //
    // STAGING TO CENTRAL SQUARE
    //

    // conquer all 4 towers
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_1_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_2_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_3_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_4_ID]) %}

    // attacking central square
    let (time) = get_move_block_time(
        Point(X, Y), STAGING_AREA_ID, CENTRAL_SQUARE_ID, ORDER_OF_GIANTS
    );
    %{ assert ids.time == 35 %}

    let (time) = get_move_block_time(
        Point(X, Y), CENTRAL_SQUARE_ID, STAGING_AREA_ID, ORDER_OF_GIANTS
    );
    %{ assert ids.time == 35 %}

    // defending cetnral square
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.CENTRAL_SQUARE_ID]) %}

    let (time) = get_move_block_time(
        Point(X, Y), STAGING_AREA_ID, CENTRAL_SQUARE_ID, ORDER_OF_GIANTS
    );
    %{ assert ids.time == 35 %}

    let (time) = get_move_block_time(
        Point(X, Y), CENTRAL_SQUARE_ID, STAGING_AREA_ID, ORDER_OF_GIANTS
    );
    %{ assert ids.time == 35 %}

    //
    // STAGING TO TOWER
    //
    // same order
    let (time) = get_move_block_time(Point(X, Y), STAGING_AREA_ID, TOWER_1_ID, ORDER_OF_GIANTS);
    %{ assert ids.time == 25 %}

    let (time) = get_move_block_time(Point(X, Y), TOWER_1_ID, STAGING_AREA_ID, ORDER_OF_GIANTS);
    %{ assert ids.time == 25 %}

    // different order
    let (time) = get_move_block_time(Point(X, Y), STAGING_AREA_ID, TOWER_1_ID, ORDER_OF_FURY);
    %{ assert ids.time == 25 %}

    let (time) = get_move_block_time(Point(X, Y), TOWER_1_ID, STAGING_AREA_ID, ORDER_OF_FURY);
    %{ assert ids.time == 25 %}

    //
    // TOWER TO CENTRAL SQUARE
    //

    // same order for tower and central square
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_1_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.CENTRAL_SQUARE_ID]) %}

    let (time) = get_move_block_time(Point(X, Y), CENTRAL_SQUARE_ID, TOWER_1_ID, ORDER_OF_GIANTS);
    %{ assert ids.time == 25 %}

    let (time) = get_move_block_time(Point(X, Y), CENTRAL_SQUARE_ID, TOWER_1_ID, ORDER_OF_FURY);
    %{ assert ids.time == 10 %}

    let (time) = get_move_block_time(Point(X, Y), TOWER_1_ID, CENTRAL_SQUARE_ID, ORDER_OF_FURY);
    %{ assert ids.time == 10 %}

    // different order for tower and central square
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_1_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.CENTRAL_SQUARE_ID]) %}

    // order of giants
    let (time) = get_move_block_time(Point(X, Y), CENTRAL_SQUARE_ID, TOWER_1_ID, ORDER_OF_GIANTS);
    %{ assert ids.time == 25 %}

    let (time) = get_move_block_time(Point(X, Y), TOWER_1_ID, CENTRAL_SQUARE_ID, ORDER_OF_GIANTS);
    %{ assert ids.time == 25 %}

    // order of fury
    let (time) = get_move_block_time(Point(X, Y), CENTRAL_SQUARE_ID, TOWER_1_ID, ORDER_OF_FURY);
    %{ assert ids.time == 10 %}

    // need to conquer all 4 to go from defending tower to attacking central square
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_1_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_2_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_3_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_4_ID]) %}
    let (time) = get_move_block_time(Point(X, Y), TOWER_1_ID, CENTRAL_SQUARE_ID, ORDER_OF_FURY);
    %{ assert ids.time == 10 %}

    //
    // TOWER TO TOWER
    //
    // same order for both tower
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_1_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_2_ID]) %}

    // defending
    let (time) = get_move_block_time(Point(X, Y), TOWER_1_ID, TOWER_2_ID, ORDER_OF_FURY);
    %{ assert ids.time == 10 %}

    let (time) = get_move_block_time(Point(X, Y), TOWER_2_ID, TOWER_1_ID, ORDER_OF_FURY);
    %{ assert ids.time == 10 %}

    // attacking
    let (time) = get_move_block_time(Point(X, Y), TOWER_1_ID, TOWER_2_ID, ORDER_OF_GIANTS);
    %{ assert ids.time == 25 %}

    let (time) = get_move_block_time(Point(X, Y), TOWER_2_ID, TOWER_1_ID, ORDER_OF_GIANTS);
    %{ assert ids.time == 25 %}

    // different order for both tower
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_1_ID]) %}
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_2_ID]) %}

    // from attacking place to defending place
    let (time) = get_move_block_time(Point(X, Y), TOWER_1_ID, TOWER_2_ID, ORDER_OF_GIANTS);
    %{ assert ids.time == 25 %}

    // from defending place to attacking place
    let (time) = get_move_block_time(Point(X, Y), TOWER_1_ID, TOWER_2_ID, ORDER_OF_FURY);
    %{ assert ids.time == 25 %}

    return ();
}
