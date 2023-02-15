%lang starknet
// starkware
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_contract_address

// settling game
from contracts.settling_game.modules.bastions.bastions import (
    join_defense_bastion,
    leave_defense_bastion,
    bastion_defenders,
)
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
from contracts.settling_game.utils.game_structs import (
    TravelInformation,
    ExternalContractIds,
    Point,
    ModuleIds,
)

// testing imports
from tests.protostar.settling_game.bastions.mockups.CombatMockup import (
    get_realm_army_combat_data,
    initiate_combat_approved_module,
    build_army_without_health,
    build_army_with_health,
    army_data_by_id,
)
from tests.protostar.settling_game.bastions.mockups.TravelMockup import forbid_travel, allow_travel
from contracts.settling_game.modules.combat.library import Combat

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
    %{ store(ids.self_address, "address_of_module_id", [ids.self_address], [ids.ModuleIds.Bastions]) %}
    // external contract address
    %{ store(ids.self_address, "external_contract_table", [ids.self_address], [ids.ExternalContractIds.Realms]) %}
    %{ store(ids.self_address, "external_contract_table", [ids.self_address], [ids.ExternalContractIds.S_Realms]) %}
    // set proxy admin
    %{ store(ids.self_address, "Proxy_admin", [ids.self_address]) %}

    // Realms
    // set realms data
    %{ store(ids.self_address, "realm_data", [ids.DEFENDING_REALM_DATA_1], [ids.DEFENDING_REALM_ID_1, 0]) %}
    %{ store(ids.self_address, "realm_data", [ids.DEFENDING_REALM_DATA_2], [ids.DEFENDING_REALM_ID_2, 0]) %}
    %{ store(ids.self_address, "realm_data", [ids.ATTACKING_REALM_DATA_1], [ids.ATTACKING_REALM_ID_1, 0]) %}
    // define self_address owner of defending_realm_id_1
    %{ store(ids.self_address, "ERC721_owners", [ids.self_address], [ids.DEFENDING_REALM_ID_1, 0]) %}

    // Defender Army data
    let (army_without_health_unpacked) = build_army_without_health();
    let (army_without_health_packed) = Combat.pack_army(army_without_health_unpacked);
    %{ store(ids.self_address, "army_data_by_id", [ids.army_without_health_packed, 0, 0, 0, 0], [ids.DEFENDING_ARMY_ID_1, ids.DEFENDING_REALM_ID_1]) %}

    return ();
}

@external
func test_defend_bastion_invalid_defense_line_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();

    %{ stop_prank_callable = start_prank(caller_address=ids.self_address) %}
    %{ expect_revert(error_message="Bastions: invalid defense line") %}
    join_defense_bastion(Point(X, Y), 3, Uint256(DEFENDING_REALM_ID_1, 0), DEFENDING_ARMY_ID_1);

    return ();
}

@external
func test_defend_bastion_no_bastion_at_position_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();

    %{ stop_prank_callable = start_prank(caller_address=ids.self_address) %}
    %{ expect_revert(error_message="Bastions: No bastion as this location") %}
    // No bastion on point (1, 1)
    join_defense_bastion(Point(1, 1), 1, Uint256(DEFENDING_REALM_ID_1, 0), DEFENDING_ARMY_ID_1);
    return ();
}

@external
func test_defend_bastion_wrong_location_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();

    %{ stop_prank_callable = start_prank(caller_address=ids.self_address) %}
    %{ expect_revert(error_message="TRAVEL: You are not at this destination") %}
    join_defense_bastion(Point(X, Y), 1, Uint256(DEFENDING_REALM_ID_1, 0), DEFENDING_ARMY_ID_1);
    return ();
}

@external
func test_defend_bastion_already_defending_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();

    // change location of the army to be on bastion location
    %{ store(ids.self_address, "coordinates", [ids.X, ids.Y], [ids.ExternalContractIds.S_Realms, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1]) %}

    // defender already defending line 1
    %{ store(ids.self_address, "bastion_defenders", [1], [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1]) %}
    %{ store(ids.self_address, "bastion_defender_count", [1], [ids.X, ids.Y, 1]) %}

    %{ stop_prank_callable = start_prank(caller_address=ids.self_address) %}
    %{ expect_revert(error_message="Bastion: army is already defending on this line") %}
    join_defense_bastion(Point(X, Y), 1, Uint256(DEFENDING_REALM_ID_1, 0), DEFENDING_ARMY_ID_1);
    return ();
}

@external
func test_defend_bastion_different_order_should_fail{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();

    // change location of the army to be on bastion location
    %{ store(ids.self_address, "coordinates", [ids.X, ids.Y], [ids.ExternalContractIds.S_Realms, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1]) %}

    // set the defending order to something different than the players order and != 0
    %{ store(ids.self_address, "bastions", [ids.BONUS_TYPE, 0, 10], [ids.X, ids.Y]) %}

    %{ stop_prank_callable = start_prank(caller_address=ids.self_address) %}
    %{ expect_revert(error_message="Bastion: cannot defend on different order") %}
    join_defense_bastion(Point(X, Y), 1, Uint256(DEFENDING_REALM_ID_1, 0), DEFENDING_ARMY_ID_1);
    return ();
}

@external
func test_defend_bastion_join_defense_line{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();

    // change location of the army to be on bastion location
    %{ store(ids.self_address, "coordinates", [ids.X, ids.Y], [ids.ExternalContractIds.S_Realms, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1]) %}

    %{ stop_prank_callable = start_prank(caller_address=ids.self_address) %}
    join_defense_bastion(Point(X, Y), 1, Uint256(DEFENDING_REALM_ID_1, 0), DEFENDING_ARMY_ID_1);

    %{
        count_1 = load(ids.self_address, "bastion_defender_count", "felt", [ids.X, ids.Y, 1])[0]
        assert count_1 == 1
        defense_line = load(ids.self_address, "bastion_defenders", "felt", [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1])[0]
        assert defense_line == 1
        cannot_travel = load(ids.self_address, "cannot_travel", "felt", [ids.ExternalContractIds.S_Realms, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1])[0]
        assert cannot_travel == 1
    %}
    %{ expect_events({"name": "BastionDefended", "data": [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1, 1]}) %}
    // order of defender is 2
    %{ expect_events({"name": "BastionChangedOrder", "data": [ids.X, ids.Y, 2]}) %}

    return ();
}

@external
func test_defend_bastion_change_defense_line{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();

    // change location of the army to be on bastion location
    %{ store(ids.self_address, "coordinates", [ids.X, ids.Y], [ids.ExternalContractIds.S_Realms, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1]) %}

    // defender already defending line 1
    %{ store(ids.self_address, "bastion_defenders", [1], [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1]) %}
    %{ store(ids.self_address, "bastion_defender_count", [1], [ids.X, ids.Y, 1]) %}
    %{ store(ids.self_address, "cannot_travel", [1], [ids.ExternalContractIds.S_Realms, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1]) %}

    %{ stop_prank_callable = start_prank(caller_address=ids.self_address) %}
    join_defense_bastion(Point(X, Y), 2, Uint256(DEFENDING_REALM_ID_1, 0), DEFENDING_ARMY_ID_1);

    %{
        count_1 = load(ids.self_address, "bastion_defender_count", "felt", [ids.X, ids.Y, 1])[0]
        assert count_1 == 0
        count_2 = load(ids.self_address, "bastion_defender_count", "felt", [ids.X, ids.Y, 2])[0]
        assert count_2 == 1
        defense_line = load(ids.self_address, "bastion_defenders", "felt", [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1])[0]
        assert defense_line == 2
        cannot_travel = load(ids.self_address, "cannot_travel", "felt", [ids.ExternalContractIds.S_Realms, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1])[0]
        assert cannot_travel == 1
    %}
    %{ expect_events({"name": "BastionDefended", "data": [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1, 2]}) %}
    return ();
}

@external
func test_leave_defense{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let (local self_address) = get_contract_address();

    // change location of the army to be on bastion location
    %{ store(ids.self_address, "coordinates", [ids.X, ids.Y], [ids.ExternalContractIds.S_Realms, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1]) %}

    // defender already defending line 1
    %{ store(ids.self_address, "bastion_defenders", [1], [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1]) %}
    %{ store(ids.self_address, "bastion_defender_count", [1], [ids.X, ids.Y, 1]) %}

    %{ stop_prank_callable = start_prank(caller_address=ids.self_address) %}
    leave_defense_bastion(Point(X, Y), Uint256(DEFENDING_REALM_ID_1, 0), DEFENDING_ARMY_ID_1);

    %{
        count_1 = load(ids.self_address, "bastion_defender_count", "felt", [ids.X, ids.Y, 1])[0]
        assert count_1 == 0
        defense_line = load(ids.self_address, "bastion_defenders", "felt", [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1])[0]
        assert defense_line == 0
        cannot_travel = load(ids.self_address, "cannot_travel", "felt", [ids.ExternalContractIds.S_Realms, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1])[0]
        assert cannot_travel == 0
    %}
    %{ expect_events({"name": "BastionDefended", "data": [ids.X, ids.Y, ids.DEFENDING_REALM_ID_1, 0, ids.DEFENDING_ARMY_ID_1, 0]}) %}
    return ();
}
