%lang starknet

// starkware
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_contract_address, get_block_number

// settling game
from contracts.settling_game.modules.bastions.constants import MovingTimes
from contracts.settling_game.modules.bastions.bastions import bastion_attack
from contracts.settling_game.modules.travel.travel import (
    set_coordinates,
    forbid_travel,
    allow_travel,
)
from contracts.settling_game.modules.combat.interface import ICombat
from contracts.settling_game.ModuleController import (
    get_module_address,
    get_external_contract_address,
    has_write_access,
)
from contracts.settling_game.tokens.Realms_ERC721_Mintable import fetch_realm_data
from contracts.settling_game.utils.constants import CCombat
from contracts.settling_game.modules.combat.library import Combat
from contracts.settling_game.utils.game_structs import (
    TravelInformation,
    ExternalContractIds,
    Point,
    ModuleIds,
)
from contracts.settling_game.utils.general import unpack_data

from tests.protostar.settling_game.bastions.setup import setup

// mockups
from tests.protostar.settling_game.bastions.mockups.CombatMockup import (
    get_realm_army_combat_data,
    initiate_combat_approved_module,
    build_army_without_health_packed,
    build_army_with_health_packed,
    army_data_by_id,
)

// @dev Tests that are not made here because reponsability of combat
// @dev => Testing that attacker is owner of the realm_id/army_id
// @dev => Testing that attacker cannot attack bastion that has same defending order as him
// @dev => Testing that you cannot attack a bastion if you are not on the same coordinates as bastion:
// @dev    If you attack a defender that is listed on the bastion defense and combat fails because of coordinates
// @dev    it means that you are not on the bastion coordinates

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
func test_bastion_attack_no_bastion_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    %{ expect_revert(error_message="Bastions: No bastion on these coordinates") %}
    // ATTACK
    bastion_attack(
        point=Point(0, 0),
        attacking_realm_id=Uint256(REALM_ID_1, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_3, 0),
        defending_army_id=ARMY_ID_1,
    );

    return ();
}

@external
func test_bastion_attack_in_staging_area_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    %{ expect_revert(error_message="Bastions: Defending army is in staging area") %}
    // ATTACK
    bastion_attack(
        point=Point(X, Y),
        attacking_realm_id=Uint256(REALM_ID_1, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_3, 0),
        defending_army_id=ARMY_ID_1,
    );

    return ();
}

@external
func test_bastion_attack_moving_defender_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    let (current_block) = get_block_number();
    // placing defender on tower 1 with later arrival block
    %{
        store(context.self_address, "bastion_army_location", 
           [ids.current_block + ids.MovingTimes.DistanceStagingAreaTower, ids.TOWER_1_ID], 
           [ids.REALM_ID_3, 0, ids.ARMY_ID_1])
    %}
    %{ expect_revert(error_message="Bastions: Defending army has not arrived yet") %}
    // ATTACK
    bastion_attack(
        point=Point(X, Y),
        attacking_realm_id=Uint256(REALM_ID_1, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_3, 0),
        defending_army_id=ARMY_ID_1,
    );

    return ();
}

@external
func test_bastion_attack_attacker_and_defender_on_different_location_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    let (current_block) = get_block_number();
    // placing defender on tower 1
    %{
        store(context.self_address, "bastion_army_location", 
           [ids.current_block, ids.TOWER_1_ID], 
           [ids.REALM_ID_3, 0, ids.ARMY_ID_1])
    %}
    %{ expect_revert(error_message="Bastions: Attacker and defender not on the same location") %}
    // ATTACK
    bastion_attack(
        point=Point(X, Y),
        attacking_realm_id=Uint256(REALM_ID_1, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_3, 0),
        defending_army_id=ARMY_ID_1,
    );

    return ();
}

@external
func test_bastion_attack_moving_attacker_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    let (current_block) = get_block_number();
    // placing defender on tower 1
    %{
        store(context.self_address, "bastion_army_location", 
           [ids.current_block + ids.MovingTimes.DistanceStagingAreaTower, ids.TOWER_1_ID], 
           [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}
    %{
        store(context.self_address, "bastion_army_location", 
           [ids.current_block, ids.TOWER_1_ID], 
           [ids.REALM_ID_3, 0, ids.ARMY_ID_1])
    %}
    %{ expect_revert(error_message="Bastions: Attacking army has not arrived yet") %}
    // ATTACK
    bastion_attack(
        point=Point(X, Y),
        attacking_realm_id=Uint256(REALM_ID_1, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_3, 0),
        defending_army_id=ARMY_ID_1,
    );

    return ();
}

@external
func test_bastion_attack_defending_order_within_cooldown_period_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    let (current_block) = get_block_number();
    // placing defender and attacker on tower 1
    %{
        store(context.self_address, "bastion_army_location", 
           [ ids.current_block,ids.TOWER_1_ID], 
           [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}
    %{
        store(context.self_address, "bastion_army_location", 
           [ids.current_block, ids.TOWER_1_ID], 
           [ids.REALM_ID_3, 0, ids.ARMY_ID_1])
    %}

    // add defending order
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_RAGE], [ids.X, ids.Y, ids.TOWER_1_ID]) %}

    // add cooldown
    %{
        store(context.self_address, "bastion_location_cooldown_end", [ids.TOWER_COOLDOWN_PERIOD], 
                   [ids.X, ids.Y, ids.TOWER_1_ID])
    %}

    %{ expect_revert(error_message="Bastion: the cooldown period has not passed yet") %}
    // ATTACK
    bastion_attack(
        point=Point(X, Y),
        attacking_realm_id=Uint256(REALM_ID_1, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_3, 0),
        defending_army_id=ARMY_ID_1,
    );
    return ();
}

@external
func test_bastion_attack_non_defending_order_within_cooldown_period{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    let (current_block) = get_block_number();
    // placing defender on tower 1
    %{
        store(context.self_address, "bastion_army_location", 
           [ ids.current_block,ids.TOWER_1_ID], 
           [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}
    %{
        store(context.self_address, "bastion_army_location", 
           [ids.current_block, ids.TOWER_1_ID], 
           [ids.REALM_ID_3, 0, ids.ARMY_ID_1])
    %}

    // add cooldown
    %{
        store(context.self_address, "bastion_location_cooldown_end", [ids.TOWER_COOLDOWN_PERIOD], 
                   [ids.X, ids.Y, ids.TOWER_1_ID])
    %}

    // ATTACK
    bastion_attack(
        point=Point(X, Y),
        attacking_realm_id=Uint256(REALM_ID_1, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_3, 0),
        defending_army_id=ARMY_ID_1,
    );
    return ();
}

@external
func test_bastion_attack_without_killing_defending_army{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    let (current_block) = get_block_number();

    // set block number to 10 so that both armies are arrived
    %{ stop_roll = roll(10) %}

    // set order of giants as defending order
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_1_ID]) %}

    // placing defender on tower 1
    %{
        store(context.self_address, "bastion_army_location", 
           [10, ids.TOWER_1_ID], 
           [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}
    %{
        store(context.self_address, "bastion_army_location", 
           [10, ids.TOWER_1_ID], 
           [ids.REALM_ID_3, 0, ids.ARMY_ID_1])
    %}

    // settle both armies by incrementing order location count by 1
    %{ store(context.self_address, "bastion_location_order_count", [1], [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_GIANTS]) %}

    // add health to defending army
    let (army_with_health_packed) = build_army_with_health_packed();
    %{ store(context.self_address, "army_data_by_id", [ids.army_with_health_packed, 0, 0, 0, 0], [ids.ARMY_ID_1, ids.REALM_ID_1, 0]) %}

    // ATTACK
    bastion_attack(
        point=Point(X, Y),
        attacking_realm_id=Uint256(REALM_ID_3, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_1, 0),
        defending_army_id=ARMY_ID_1,
    );
    // verify that defending order did not change
    %{
        defending_order = load(context.self_address, "bastion_location_defending_order", "felt", [ids.X, ids.Y, ids.TOWER_1_ID])[0]
        assert defending_order == ids.ORDER_OF_GIANTS
    %}
    return ();
}

@external
func test_bastion_attack_kill_defending_army_take_location{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    // set block number to 10 so that both armies are arrived
    %{ stop_roll = roll(10) %}

    // set order of giants as defending order
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_1_ID]) %}

    // placing defender and attacker on tower 1
    %{
        store(context.self_address, "bastion_army_location", 
           [10, ids.TOWER_1_ID], 
           [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}
    %{
        store(context.self_address, "bastion_army_location", 
           [10, ids.TOWER_1_ID], 
           [ids.REALM_ID_3, 0, ids.ARMY_ID_1])
    %}

    // settle both armies by incrementing order location count by 1
    %{ store(context.self_address, "bastion_location_order_count", [1], [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_GIANTS]) %}
    %{ store(context.self_address, "bastion_location_order_count", [1], [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_RAGE]) %}

    // add health to attacking army
    let (army_with_health_packed) = build_army_with_health_packed();
    %{ store(context.self_address, "army_data_by_id", [ids.army_with_health_packed, 0, 0, 0, 0], [ids.ARMY_ID_1, ids.REALM_ID_3, 0]) %}

    // ATTACK
    bastion_attack(
        point=Point(X, Y),
        attacking_realm_id=Uint256(REALM_ID_3, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_1, 0),
        defending_army_id=ARMY_ID_1,
    );
    // verify that defending order changed
    %{
        defending_order = load(context.self_address, "bastion_location_defending_order", "felt", [ids.X, ids.Y, ids.TOWER_1_ID])[0]
        assert defending_order == ids.ORDER_OF_RAGE
    %}

    let (current_block) = get_block_number();
    // verify cooldown
    %{
        cooldown_end = load(context.self_address, "bastion_location_cooldown_end", "felt", [ids.X, ids.Y, ids.TOWER_1_ID])[0]
        assert cooldown_end == ids.current_block + ids.TOWER_COOLDOWN_PERIOD
    %}

    // expect event
    %{
        expect_events({"name": "BastionLocationTaken", "data": 
                           [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_RAGE, ids.current_block + ids.TOWER_COOLDOWN_PERIOD]})
    %}

    return ();
}

@external
func test_bastion_attack_kill_attacking_and_defending_set_no_defending_order{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    // set block number to 10 so that both armies are arrived
    %{ stop_roll = roll(10) %}

    // set order of giants as defending order
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_1_ID]) %}

    // placing defender and attacker on tower 1
    %{
        store(context.self_address, "bastion_army_location", 
           [10, ids.TOWER_1_ID], 
           [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}
    %{
        store(context.self_address, "bastion_army_location", 
           [10, ids.TOWER_1_ID], 
           [ids.REALM_ID_3, 0, ids.ARMY_ID_1])
    %}

    // settle both armies by incrementing order location count by 1
    %{ store(context.self_address, "bastion_location_order_count", [1], [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_GIANTS]) %}
    %{ store(context.self_address, "bastion_location_order_count", [1], [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_RAGE]) %}

    // ATTACK
    bastion_attack(
        point=Point(X, Y),
        attacking_realm_id=Uint256(REALM_ID_3, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_1, 0),
        defending_army_id=ARMY_ID_1,
    );
    // verify that defending order is now null
    %{
        defending_order = load(context.self_address, "bastion_location_defending_order", "felt", [ids.X, ids.Y, ids.TOWER_1_ID])[0]
        assert defending_order == 0
    %}

    let (current_block) = get_block_number();
    // expect event
    %{
        expect_events({"name": "BastionLocationTaken", "data": 
                           [ids.X, ids.Y, ids.TOWER_1_ID, 0, ids.current_block + ids.TOWER_COOLDOWN_PERIOD]})
    %}
    return ();
}

// 3 armies defending the location, need to kill 3 to take it.
// first 2 armies are settled (in the location counter), the last one is stored in the current movers
@external
func test_bastion_attack_kill_defending_armies_until_location_is_taken{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    const ARRIVAL_BLOCK = 10;

    // set block number to 10 so that both armies are arrived
    %{ stop_roll = roll(ids.ARRIVAL_BLOCK) %}

    // set order of giants as defending order
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_GIANTS], [ids.X, ids.Y, ids.TOWER_1_ID]) %}

    // placing defender and attacker on tower 1
    // 2 armies for defender 1
    %{
        store(context.self_address, "bastion_army_location", 
           [ids.ARRIVAL_BLOCK, ids.TOWER_1_ID], 
           [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}
    %{
        store(context.self_address, "bastion_army_location", 
           [ids.ARRIVAL_BLOCK, ids.TOWER_1_ID], 
            [ids.REALM_ID_1, 0, ids.ARMY_ID_2])
    %}

    // 1 army for defender 2 (arrived 1 block earlier than the rest)
    %{
        store(context.self_address, "bastion_army_location", 
           [ids.ARRIVAL_BLOCK, ids.TOWER_1_ID], 
            [ids.REALM_ID_2, 0, ids.ARMY_ID_1])
    %}

    // 1 army for attacker
    %{
        store(context.self_address, "bastion_army_location", 
           [ids.ARRIVAL_BLOCK, ids.TOWER_1_ID], 
           [ids.REALM_ID_3, 0, ids.ARMY_ID_1])
    %}

    // store 2 defender armies in location count (already settled)
    %{ store(context.self_address, "bastion_location_order_count", [2], [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_GIANTS]) %}
    // store 1 defender army in current_movers (already arrived but not settled)
    %{
        store(context.self_address, "current_movers", 
                   [ids.ARRIVAL_BLOCK, 1], [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_GIANTS, ids.ARRIVAL_BLOCK])
    %}

    // add health to attacking army
    let (army_with_health_packed) = build_army_with_health_packed();
    %{ store(context.self_address, "army_data_by_id", [ids.army_with_health_packed, 0, 0, 0, 0], [ids.ARMY_ID_1, ids.REALM_ID_3, 0]) %}

    // ATTACK
    // kill the first defender
    bastion_attack(
        point=Point(X, Y),
        attacking_realm_id=Uint256(REALM_ID_3, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_1, 0),
        defending_army_id=ARMY_ID_1,
    );
    // verify that defending order did not change because still two defender left
    %{
        defending_order = load(context.self_address, "bastion_location_defending_order", "felt", [ids.X, ids.Y, ids.TOWER_1_ID])[0]
        assert defending_order == ids.ORDER_OF_GIANTS
    %}
    // verify that the defending_order_count is still the same because the killed army
    // was removed from current_movers first
    %{
        defending_order_count = load(context.self_address, "bastion_location_order_count", "felt", 
                                    [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_GIANTS])[0]
        assert defending_order_count == 2
    %}
    // verify army was removed from current movers
    %{
        current_movers = load(context.self_address, "current_movers", "MoverData", 
                                    [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_GIANTS, ids.ARRIVAL_BLOCK])
        assert current_movers == [ids.ARRIVAL_BLOCK, 0]
    %}

    // kill the second defender
    bastion_attack(
        point=Point(X, Y),
        attacking_realm_id=Uint256(REALM_ID_3, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_1, 0),
        defending_army_id=ARMY_ID_2,
    );
    // verify that defending order changed because no more defenders
    %{
        defending_order = load(context.self_address, "bastion_location_defending_order", "felt", [ids.X, ids.Y, ids.TOWER_1_ID])[0]
        assert defending_order == ids.ORDER_OF_GIANTS
    %}
    // verify that the defending_order_count is now 1
    %{
        defending_order_count = load(context.self_address, "bastion_location_order_count", "felt", 
                                    [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_GIANTS])[0]
        assert defending_order_count == 1
    %}

    // kill the third defender, in the current_movers because not settled yet
    // kill the second defender
    bastion_attack(
        point=Point(X, Y),
        attacking_realm_id=Uint256(REALM_ID_3, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_2, 0),
        defending_army_id=ARMY_ID_1,
    );
    // verify that defending order changed because no more defenders
    %{
        defending_order = load(context.self_address, "bastion_location_defending_order", "felt", [ids.X, ids.Y, ids.TOWER_1_ID])[0]
        assert defending_order == ids.ORDER_OF_RAGE
    %}
    // verify that the defending_order_count is now 0
    %{
        defending_order_count = load(context.self_address, "bastion_location_order_count", "felt", 
                                    [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_GIANTS])[0]
        assert defending_order_count == 0
    %}

    let (current_block) = get_block_number();
    // expect event
    %{
        expect_events({"name": "BastionLocationTaken", "data": 
                           [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_RAGE, ids.current_block + ids.TOWER_COOLDOWN_PERIOD]})
    %}

    return ();
}

// if last army of an order that is not the defending order is killed, no defending order change
@external
func test_bastion_attack_kill_non_defending_order_army_no_order_change{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    // set block number to 10 so that both armies are arrived
    %{ stop_roll = roll(10) %}

    // set order of giants as defending order
    %{ store(context.self_address, "bastion_location_defending_order", [ids.ORDER_OF_FURY], [ids.X, ids.Y, ids.TOWER_1_ID]) %}

    // placing defender and attacker on tower 1
    %{
        store(context.self_address, "bastion_army_location", 
           [10, ids.TOWER_1_ID], 
           [ids.REALM_ID_1, 0, ids.ARMY_ID_1])
    %}
    %{
        store(context.self_address, "bastion_army_location", 
           [10, ids.TOWER_1_ID], 
           [ids.REALM_ID_3, 0, ids.ARMY_ID_1])
    %}

    // settle both armies by incrementing order location count by 1
    %{ store(context.self_address, "bastion_location_order_count", [1], [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_GIANTS]) %}
    %{ store(context.self_address, "bastion_location_order_count", [1], [ids.X, ids.Y, ids.TOWER_1_ID, ids.ORDER_OF_RAGE]) %}

    // add health to attacking army
    let (army_with_health_packed) = build_army_with_health_packed();
    %{
        store(context.self_address, "army_data_by_id", 
                   [ids.army_with_health_packed, 0, 0, 0, 0], [ids.ARMY_ID_1, ids.REALM_ID_3, 0])
    %}

    // ATTACK
    bastion_attack(
        point=Point(X, Y),
        attacking_realm_id=Uint256(REALM_ID_3, 0),
        attacking_army_id=ARMY_ID_1,
        defending_realm_id=Uint256(REALM_ID_1, 0),
        defending_army_id=ARMY_ID_1,
    );
    // verify that defending order is now null
    %{
        defending_order = load(context.self_address, "bastion_location_defending_order", "felt", [ids.X, ids.Y, ids.TOWER_1_ID])[0]
        assert defending_order == ids.ORDER_OF_FURY
    %}
    return ();
}
