%lang starknet
// starkware
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_contract_address

// settling game
from contracts.settling_game.modules.bastions.constants import MovingTimes
from contracts.settling_game.modules.bastions.bastions import (
    bastion_move,
    get_move_block_time,
    bastion_take_location,
)
from contracts.settling_game.modules.combat.library import Combat
from contracts.settling_game.modules.travel.travel import (
    set_coordinates,
    get_coordinates,
    forbid_travel,
    allow_travel,
)
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
func test_bastion_take_location_invalid_location_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: invalid location") %}

    // TAKE LOCATION
    bastion_take_location(Point(X, Y), 0, Uint256(REALM_ID_1, 0), ARMY_ID_1);

    return ();
}

@external
func test_bastion_take_location_no_bastion_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: No bastion as this location") %}

    // TAKE LOCATION
    bastion_take_location(Point(0, 0), TOWER_1_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);

    return ();
}

@external
func test_bastion_take_location_wrong_coordinates_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="TRAVEL: You are not at this destination") %}

    // TAKE LOCATION
    bastion_take_location(Point(X, Y), TOWER_1_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}

@external
func test_bastion_take_location_wrong_location_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    // change location of the army to be on bastion location
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: army is not at right location") %}

    // TAKE LOCATION
    bastion_take_location(Point(X, Y), TOWER_1_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}

@external
func test_bastion_take_location_cooldown_not_passed_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    // put army on right coordinates
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // put army on right bastion location
    %{ store(context.self_address, "bastion_army_location", [0, ids.TOWER_1_ID], [ids.REALM_ID_1, 0, ids.ARMY_ID_1]) %}

    // put realm order as defending order
    %{
        store(context.self_address, "bastion_location_defending_order", 
                       [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_1_ID])
    %}

    // set cooldown end after current block
    %{
        store(context.self_address, "bastion_location_cooldown_end", 
                       [10], [ids.X, ids.Y, ids.TOWER_1_ID])
    %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastion: the cooldown period has not passed yet") %}

    // TAKE LOCATION
    bastion_take_location(Point(X, Y), TOWER_1_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}

@external
func test_bastion_take_location_order_already_defending_order_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    // put army on right coordinates
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // put army on right bastion location
    %{ store(context.self_address, "bastion_army_location", [0, ids.TOWER_1_ID], [ids.REALM_ID_1, 0, ids.ARMY_ID_1]) %}

    // put realm order as defending order
    %{
        store(context.self_address, "bastion_location_defending_order", 
                       [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_1_ID])
    %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: Army order is already defending order") %}

    // TAKE LOCATION
    bastion_take_location(Point(X, Y), TOWER_1_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}

@external
func test_bastion_take_location_still_defenders_in_location_count_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    // put army on right coordinates
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // put army on right bastion location
    %{ store(context.self_address, "bastion_army_location", [0, ids.TOWER_1_ID], [ids.REALM_ID_1, 0, ids.ARMY_ID_1]) %}

    // put order of fury as defending order
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_1_ID]) %}

    // put some settled defenders by increasing the location order count
    %{ store(context.self_address, "bastion_location_order_count", [1], [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_FURY]) %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: There are still settled defenders in the location") %}

    // TAKE LOCATION
    bastion_take_location(Point(X, Y), TOWER_1_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}

@external
func test_bastion_take_location_still_defenders_in_current_movers_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    // put army on right coordinates
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // put army on right bastion location
    %{ store(context.self_address, "bastion_army_location", [0, ids.TOWER_1_ID], [ids.REALM_ID_1, 0, ids.ARMY_ID_1]) %}

    // put order of fury as defending order
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_1_ID]) %}

    // put some unsettled defenders by adding them to the current movers
    %{ store(context.self_address, "current_movers", [0, 10], [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_FURY, 0]) %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}
    %{ expect_revert(error_message="Bastions: There are still unsettled defenders in the location") %}

    // TAKE LOCATION
    bastion_take_location(Point(X, Y), TOWER_1_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}

@external
func test_bastion_take_location{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> () {
    // put army on right coordinates
    %{
        store(context.self_address, "coordinates", [ids.X, ids.Y], 
                   [ids.ExternalContractIds.S_Realms, ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}

    // put army on right bastion location
    %{ store(context.self_address, "bastion_army_location", [0, ids.TOWER_1_ID], [ids.REALM_ID_1, 0, ids.ARMY_ID_1]) %}

    %{ stop_prank_callable = start_prank(caller_address=context.self_address) %}

    // TAKE LOCATION
    bastion_take_location(Point(X, Y), TOWER_1_ID, Uint256(REALM_ID_1, 0), ARMY_ID_1);
    return ();
}
