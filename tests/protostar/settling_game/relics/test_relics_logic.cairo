%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.settling_game.utils.game_structs import RealmData, ModuleIds

from tests.protostar.settling_game.setup.setup import deploy_account, deploy_controller, deploy_module
from tests.protostar.settling_game.setup.interfaces import Realms, Relics

const PK = 11111;

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local realms_1_data;
    local realms_2_data;
    local realms_3_data;
    local realms_4_data;

    let realm_name = 'Test';

    let (local account_address) = deploy_account(PK);
    let (local controller_address) = deploy_controller(account_address, account_address);
    let (local realms_address) = deploy_module(
        ModuleIds.Realms_Token, controller_address, account_address
    );
    let (local relics_address) = deploy_module(
        ModuleIds.Relics, controller_address, account_address
    );
    let (local combat_address) = deploy_module(
        ModuleIds.L06_Combat, controller_address, account_address
    );

    %{
        from tests.protostar.utils import utils
        # bitwise mapping functions, set default data with custom order
        ids.realms_1_data = utils.pack_realm(utils.build_realm_data(0,0,0,0,0,0,0,0,0,0,0,0,0,1))
        ids.realms_2_data = utils.pack_realm(utils.build_realm_data(0,0,0,0,0,0,0,0,0,0,0,0,0,2))
        ids.realms_3_data = utils.pack_realm(utils.build_realm_data(0,0,0,0,0,0,0,0,0,0,0,0,0,1))
        ids.realms_4_data = utils.pack_realm(utils.build_realm_data(0,0,0,0,0,0,0,0,0,0,0,0,0,1))
        context.account_address = ids.account_address
        context.controller_address = ids.controller_address
        context.realms_address = ids.realms_address
        context.relics_address = ids.relics_address
        context.combat_address = ids.combat_address
        stop_prank_callable = start_prank(ids.account_address, ids.realms_address)
    %}
    Realms.set_realm_data(realms_address, Uint256(1, 0), realm_name, realms_1_data);
    Realms.set_realm_data(realms_address, Uint256(2, 0), realm_name, realms_2_data);
    Realms.set_realm_data(realms_address, Uint256(3, 0), realm_name, realms_3_data);
    Realms.set_realm_data(realms_address, Uint256(4, 0), realm_name, realms_4_data);

    %{
        stop_prank_callable()
    %}

    return ();
}

@external
func test_set_relic_holder{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    local account_address;
    local relics_address;
    local realms_address;
    local combat_address;
    %{
        ids.account_address = context.account_address
        ids.relics_address = context.relics_address
        ids.realms_address = context.realms_address
        ids.combat_address = context.combat_address
        stop_prank_callable = start_prank(ids.combat_address, ids.relics_address)
    %}
    Relics.set_relic_holder(relics_address, Uint256(2, 0), Uint256(1, 0));
    let (owner_id) = Relics.get_current_relic_holder(relics_address, Uint256(1, 0));
    assert owner_id = Uint256(2, 0);
    %{
        stop_prank_callable()
    %}
    return ();
}

@external
func test_claim_order_relic{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    local account_address;
    local relics_address;
    local realms_address;
    local combat_address;
    %{
        ids.account_address = context.account_address
        ids.relics_address = context.relics_address
        ids.realms_address = context.realms_address
        ids.combat_address = context.combat_address
        stop_prank_callable = start_prank(ids.combat_address, ids.relics_address)
    %}
    Relics.set_relic_holder(relics_address, Uint256(2, 0), Uint256(1, 0));
    Relics.set_relic_holder(relics_address, Uint256(2, 0), Uint256(4, 0));
    // this returns fellow order relics to orginal owners
    Relics.set_relic_holder(relics_address, Uint256(3, 0), Uint256(2, 0));
    let (owner_id_1) = Relics.get_current_relic_holder(relics_address, Uint256(1, 0));
    let (owner_id_4) = Relics.get_current_relic_holder(relics_address, Uint256(4, 0));
    // check relic of same order was returned
    assert owner_id_1 = Uint256(1, 0);
    assert owner_id_4 = Uint256(4, 0);
    %{
        stop_prank_callable()
    %}
    return ();
}

@external
func test_return_relics{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_address;
    local relics_address;
    local realms_address;
    local combat_address;
    %{
        ids.account_address = context.account_address
        ids.relics_address = context.relics_address
        ids.realms_address = context.realms_address
        ids.combat_address = context.combat_address
        stop_prank_callable = start_prank(ids.combat_address, ids.relics_address)
    %}
    Relics.set_relic_holder(relics_address, Uint256(2, 0), Uint256(1, 0));
    Relics.set_relic_holder(relics_address, Uint256(2, 0), Uint256(3, 0));
    // function called by unsettle function
    Relics.return_relics(relics_address, Uint256(2, 0));
    // check relic has been returned to original owner
    let (owner_id_1) = Relics.get_current_relic_holder(relics_address, Uint256(1, 0));
    let (owner_id_3) = Relics.get_current_relic_holder(relics_address, Uint256(3, 0));
    assert owner_id_1 = Uint256(1, 0);
    assert owner_id_3 = Uint256(3, 0);
    %{
        stop_prank_callable()
    %}
    return ();
}

@external
func test_stress_test{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_address;
    local relics_address;
    local realms_address;
    local combat_address;
    %{
        ids.account_address = context.account_address
        ids.relics_address = context.relics_address
        ids.realms_address = context.realms_address
        ids.combat_address = context.combat_address
        stop_prank_callable = start_prank(ids.combat_address, ids.relics_address)
    %}
    Relics.set_relic_holder(relics_address, Uint256(1, 0), Uint256(2, 0));
    Relics.set_relic_holder(relics_address, Uint256(2, 0), Uint256(1, 0));
    Relics.set_relic_holder(relics_address, Uint256(3, 0), Uint256(2, 0));
    Relics.return_relics(relics_address, Uint256(3, 0));
    Relics.set_relic_holder(relics_address, Uint256(1, 0), Uint256(2, 0));
    let (owner_id_1) = Relics.get_current_relic_holder(relics_address, Uint256(1, 0));
    let (owner_id_2) = Relics.get_current_relic_holder(relics_address, Uint256(2, 0));
    let (owner_id_3) = Relics.get_current_relic_holder(relics_address, Uint256(3, 0));
    assert owner_id_1 = Uint256(1, 0);
    assert owner_id_2 = Uint256(1, 0);

    %{
        # get relic count for realm 2, expect 0
        owner_2_relics_len = load(ids.relics_address, "owned_relics_len", "felt", key=[2, 0])
        assert owner_2_relics_len[0] == 0
        stop_prank_callable()
    %}

    return ();
}
