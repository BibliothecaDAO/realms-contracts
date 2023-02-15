%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.modules.bastions.bastions import attack_bastion
from contracts.settling_game.modules.travel.travel import set_coordinates
from contracts.settling_game.modules.combat.interface import ICombat
from contracts.settling_game.ModuleController import (
    get_module_address,
    get_external_contract_address,
)
from contracts.settling_game.tokens.Realms_ERC721_Mintable import fetch_realm_data
from contracts.settling_game.utils.constants import CCombat
from tests.protostar.settling_game.bastions.mockups.CombatMockup import (
    get_realm_army_combat_data,
    initiate_combat_approved_module,
    build_army_without_health,
    build_army_with_health,
    army_data_by_id,
)
from contracts.settling_game.modules.combat.library import Combat
from contracts.settling_game.utils.game_structs import (
    TravelInformation,
    ExternalContractIds,
    Point,
    ModuleIds,
)
from contracts.settling_game.utils.general import unpack_data

from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_number,
)

// @dev Tests that are not made here because reponsability of combat
// @dev => Testing that attacker is owner of the realm_id/army_id
// @dev => Testing that attacker cannot attack bastion that has same defending order as him
// @dev => Testing that you cannot attack a bastion if you are not on the same coordinates as bastion:
// @dev    If you attack a defender that is listed on the bastion defense and combat fails because of coordinates
// @dev    it means that you are not on the bastion coordinates

const X = 3;
const Y = 4;

const DEFENDING_REALM_ID_1 = 1;
const DEFENDING_ARMY_ID_1 = 1;
const DEFENDING_REALM_DATA_1 = 40564819207303341694527483217926;  // realm 1: order of giants

const DEFENDING_REALM_ID_2 = 2;
const DEFENDING_ARMY_ID_2 = 1;
const DEFENDING_REALM_DATA_2 = 40564819207303340854496404575491;  // realm 20: order of giants

const ATTACKING_REALM_ID_1 = 3;
const ATTACKING_ARMY_ID_1 = 1;
const ATTACKING_REALM_DATA_1 = 202824096036516993033911502441218;  // realm 3: order of rage

const BONUS_TYPE = 11;
const COOLOFF_PERIOD = 10;

@external
func __setup__{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    alloc_locals;

    // set block number to 0
    %{ stop_roll = roll(0) %}

    let (local self_address) = get_contract_address();

    // put at least one bastion in the storage
    %{ store(ids.self_address, "bastions", [ids.BONUS_TYPE, 0, 0], [ids.X, ids.Y]) %}
    %{ store(ids.self_address, "bastion_cooloff", [ids.COOLOFF_PERIOD]) %}

    // Module Controller
    // module address
    %{ store(ids.self_address, "module_controller_address", [ids.self_address]) %}
    %{ store(ids.self_address, "address_of_module_id", [ids.self_address], [ids.ModuleIds.Travel]) %}
    %{ store(ids.self_address, "address_of_module_id", [ids.self_address], [ids.ModuleIds.L06_Combat]) %}
    %{ store(ids.self_address, "address_of_module_id", [ids.self_address], [ids.ModuleIds.Realms_Token]) %}
    // external contract address
    %{ store(ids.self_address, "external_contract_table", [ids.self_address], [ids.ExternalContractIds.Realms]) %}
    %{ store(ids.self_address, "external_contract_table", [ids.self_address], [ids.ExternalContractIds.S_Realms]) %}

    // Realms
    // set realms data
    %{ store(ids.self_address, "realm_data", [ids.DEFENDING_REALM_DATA_1], [ids.DEFENDING_REALM_ID_1, 0]) %}
    %{ store(ids.self_address, "realm_data", [ids.DEFENDING_REALM_DATA_2], [ids.DEFENDING_REALM_ID_2, 0]) %}
    %{ store(ids.self_address, "realm_data", [ids.ATTACKING_REALM_DATA_1], [ids.ATTACKING_REALM_ID_1, 0]) %}

    // Defender Army data
    let (army_without_health_unpacked) = build_army_without_health();
    let (army_without_health_packed) = Combat.pack_army(army_without_health_unpacked);
    %{ store(ids.self_address, "army_data_by_id", [ids.army_without_health_packed, 0, 0, 0, 0], [ids.DEFENDING_ARMY_ID_1, ids.DEFENDING_REALM_ID_1]) %}

    return ();
}

@external
func test_attack_bastion_no_defender_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    %{ expect_revert(error_message="Bastion: Defending army not present on the bastion defenses") %}
    // ATTACK
    attack_bastion(
        point=Point(X, Y),
        attacking_army_id=ATTACKING_ARMY_ID_1,
        attacking_realm_id=Uint256(ATTACKING_REALM_ID_1, 0),
        defending_realm_id=Uint256(DEFENDING_REALM_ID_1, 0),
        defending_army_id=DEFENDING_ARMY_ID_1,
    );

    return ();
}

@external
func test_attack_bastion_within_cooloff_period_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    alloc_locals;
    let (self_address) = get_contract_address();

    // add cooloff period of 10 blocks
    %{ store(ids.self_address, "bastions", [ids.BONUS_TYPE, 10, 0], [ids.X, ids.Y]) %}

    // add defender to bastion
    %{ store(ids.self_address, "bastion_defenders", [1], [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1]) %}
    %{ store(ids.self_address, "bastion_defender_count", [1], [ids.X, ids.Y, 1]) %}

    %{ expect_revert(error_message="Bastion: the cooloff period has not passed yet") %}

    // ATTACK
    attack_bastion(
        point=Point(X, Y),
        attacking_army_id=ATTACKING_ARMY_ID_1,
        attacking_realm_id=Uint256(ATTACKING_REALM_ID_1, 0),
        defending_realm_id=Uint256(DEFENDING_REALM_ID_1, 0),
        defending_army_id=DEFENDING_ARMY_ID_1,
    );
    return ();
}

@external
func test_attack_bastion_defeat_last_defender_and_become_defender{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();

    // add cooloff period of 10 blocks
    %{ store(ids.self_address, "bastions", [ids.BONUS_TYPE, 0, 0], [ids.X, ids.Y]) %}

    // add defender to bastion
    %{ store(ids.self_address, "bastion_defenders", [1], [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1]) %}
    %{ store(ids.self_address, "bastion_defender_count", [1], [ids.X, ids.Y, 1]) %}
    %{ store(ids.self_address, "bastion_defenders", [2], [ids.X, ids.Y, ids.DEFENDING_REALM_ID_2, 0, ids.DEFENDING_ARMY_ID_2]) %}
    %{ store(ids.self_address, "bastion_defender_count", [1], [ids.X, ids.Y, 2]) %}
    // set attacker to combat winner
    %{ store(ids.self_address, "combat_outcome", [ids.CCombat.COMBAT_OUTCOME_ATTACKER_WINS]) %}

    // attack defender on DL1
    attack_bastion(
        point=Point(X, Y),
        attacking_army_id=ATTACKING_ARMY_ID_1,
        attacking_realm_id=Uint256(ATTACKING_REALM_ID_1, 0),
        defending_realm_id=Uint256(DEFENDING_REALM_ID_1, 0),
        defending_army_id=DEFENDING_ARMY_ID_1,
    );

    // assert that attacker is not defender
    %{
        count_1 = load(ids.self_address, "bastion_defender_count", "felt", [ids.X, ids.Y, 1])[0]
        assert count_1 == 0, "should be 0 after defender defeated"
        count_2 = load(ids.self_address, "bastion_defender_count", "felt", [ids.X, ids.Y, 2])[0]
        assert count_2 == 1, "should be 1 because not yet defeated"
        attacker_defense_line = load(ids.self_address, "bastion_defenders", "felt", [ids.X, ids.Y, ids.ATTACKING_REALM_ID_1, 0, ids.ATTACKING_ARMY_ID_1])[0]
        assert attacker_defense_line == 0, "Attacker should not become defender yet"
    %}

    // attack defender on DL2
    attack_bastion(
        point=Point(X, Y),
        attacking_army_id=ATTACKING_ARMY_ID_1,
        attacking_realm_id=Uint256(ATTACKING_REALM_ID_1, 0),
        defending_realm_id=Uint256(DEFENDING_REALM_ID_2, 0),
        defending_army_id=DEFENDING_ARMY_ID_2,
    );

    // assert that attacker is defender on DL2
    %{
        count_1 = load(ids.self_address, "bastion_defender_count", "felt", [ids.X, ids.Y, 1])[0]
        assert count_1 == 0, "should be 0 after defender defeated"
        count_2 = load(ids.self_address, "bastion_defender_count", "felt", [ids.X, ids.Y, 2])[0]
        assert count_2 == 1, "should be 1 because attacker replaces defender"
        attacker_defense_line = load(ids.self_address, "bastion_defenders", "felt", [ids.X, ids.Y, ids.ATTACKING_REALM_ID_1, 0, ids.ATTACKING_ARMY_ID_1])[0]
        assert attacker_defense_line == 2, "attacker should become defender after defeating last defender"
    %}

    // assert that order has changed to attacker order (Rage = 15)
    %{
        bastion = load(ids.self_address, "bastions", "Bastion", [ids.X, ids.Y])
        # current block number is 0
        assert bastion[1] == 0 + ids.COOLOFF_PERIOD, "should start cooloff period after change in bastion order"
        assert bastion[2] == 10, "new order should be attacker order (order 10)"
    %}

    // events
    %{ expect_events({"name": "BastionDefended", "data": [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1, 0]}) %}
    %{ expect_events({"name": "BastionDefended", "data": [ids.X, ids.Y, ids.ATTACKING_REALM_ID_1, 0, ids.ATTACKING_ARMY_ID_1, 2]}) %}
    // order of defender is 10
    %{ expect_events({"name": "BastionChangedOrder", "data": [ids.X, ids.Y, 10]}) %}

    return ();
}

@external
func test_attack_bastion_win_combat_and_move_defender_from_DL1_to_DL2{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();
    %{ store(ids.self_address, "combat_outcome", [ids.CCombat.COMBAT_OUTCOME_ATTACKER_WINS]) %}
    // set defender on DL1
    %{ store(ids.self_address, "bastion_defenders", [1], [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1]) %}

    // army data with health
    let (army_with_health_unpacked) = build_army_with_health();
    let (army_with_health_packed) = Combat.pack_army(army_with_health_unpacked);
    %{ store(ids.self_address, "army_data_by_id", [ids.army_with_health_packed, 0, 0, 0, 0], [ids.DEFENDING_ARMY_ID_1, ids.DEFENDING_REALM_ID_1, 0]) %}

    // attack defender on DL1
    attack_bastion(
        point=Point(X, Y),
        attacking_army_id=ATTACKING_ARMY_ID_1,
        attacking_realm_id=Uint256(ATTACKING_REALM_ID_1, 0),
        defending_realm_id=Uint256(DEFENDING_REALM_ID_1, 0),
        defending_army_id=DEFENDING_ARMY_ID_1,
    );

    // assert defender is on DL2
    %{
        defenser_defense_line = load(ids.self_address, "bastion_defenders", "felt", [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1])[0]
        assert defenser_defense_line == 2, "defenser is moved from DL1 to DL2"
    %}

    // events
    %{ expect_events({"name": "BastionDefended", "data": [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1, 2]}) %}

    return ();
}

@external
func test_attack_bastion_lose_combat{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();
    %{ store(ids.self_address, "combat_outcome", [ids.CCombat.COMBAT_OUTCOME_ATTACKER_WINS]) %}
    %{ store(ids.self_address, "bastion_defenders", [1], [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1]) %}
    %{ store(ids.self_address, "bastion_defender_count", [1], [ids.X, ids.Y, 1]) %}
    return ();
}
