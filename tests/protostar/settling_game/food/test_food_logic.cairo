%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from tests.protostar.settling_game.setup.helpers import get_resources, get_owners, settle_realm, mint_resources
from tests.protostar.settling_game.setup.interfaces import Realms, ResourcesToken, Food
from tests.protostar.settling_game.setup.setup import deploy_account, deploy_module, deploy_controller, time_warp

from contracts.settling_game.utils.game_structs import ModuleIds, RealmBuildingsIds, HarvestType
from contracts.settling_game.modules.resources.interface import IResources

from contracts.token.constants import (
    IERC1155_ID,
    IERC1155_METADATA_ID,
    IERC1155_RECEIVER_ID,
    IACCOUNT_ID,
    ON_ERC1155_RECEIVED_SELECTOR,
    ON_ERC1155_BATCH_RECEIVED_SELECTOR,
)

const PK = 11111;

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local realms_1_data;

    let (local account_address) = deploy_account(PK);
    let (local controller_address) = deploy_controller(account_address, account_address);
    let (local food_address) = deploy_module(
        ModuleIds.L10_Food, controller_address, account_address
    );
    let (local resources_token_address) = deploy_module(
        ModuleIds.Resources_Token, controller_address, account_address
    );
    let (local realms_address) = deploy_module(
        ModuleIds.Realms_Token, controller_address, account_address
    );
    let (local s_realms_address) = deploy_module(
        ModuleIds.S_Realms_Token, controller_address, account_address
    );
    let (local settling_address) = deploy_module(
        ModuleIds.Settling, controller_address, account_address
    );
    let (local buildings_address) = deploy_module(
        ModuleIds.Buildings, controller_address, account_address
    );
    let (local calculator_address) = deploy_module(
        ModuleIds.Calculator, controller_address, account_address
    );

    %{
        from tests.protostar.utils import utils
        stop_prank_realms = start_prank(ids.account_address, target_contract_address=ids.realms_address)
        stop_prank_settling = start_prank(ids.account_address, target_contract_address=ids.settling_address)
        context.account_address = ids.account_address
        context.resources_token_address = ids.resources_token_address
        context.realms_address = ids.realms_address
        context.settling_address = ids.settling_address
        context.food_address = ids.food_address
        print(ids.food_address)
        print(ids.resources_token_address)
        print(ids.s_realms_address)
        print(ids.account_address)
        ids.realms_1_data = utils.pack_realm(utils.build_realm_data(4, 5, 2, 1, 4, 2, 8, 13, 6, 0, 0, 0, 0, 4))
    %}
    Realms.set_realm_data(realms_address, Uint256(1, 0), 'Test 1', realms_1_data);
    settle_realm(realms_address, settling_address, account_address, Uint256(1, 0));
    %{
        stop_prank_realms()
        stop_prank_settling()
    %}

    return ();
}

@external
func test_create_farm{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local account_address;
    local resources_token_address;
    local settling_address;
    local food_address;

    let realms_token_id: Uint256 = Uint256(1, 0);
    %{
        ids.resources_token_address = context.resources_token_address
        ids.settling_address = context.settling_address
        ids.food_address = context.food_address
        ids.account_address = context.account_address
        stop_prank = start_prank(ids.account_address, target_contract_address=ids.food_address)
    %}
    mint_resources(resources_token_address, Uint256(1000, 0), account_address);
    Food.create(food_address, realms_token_id, 1, RealmBuildingsIds.Farm);
    let (accounts_len, accounts) = get_owners(account_address);
    let (token_ids: Uint256*) = get_resources();
    let (balances_len, balances: Uint256*) = ResourcesToken.balanceOfBatch(
        resources_token_address, accounts_len, accounts, 22, token_ids
    );
    %{
        # for i in range(22):
            # assert 19800000000000000000000 == memory[ids.balances._reference_value + 2*i]
            # assert 0 == memory[ids.balances._reference_value + 2*i + 1]
        stop_prank()
    %}
    return ();
}

@external
func test_harvest_farm{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local account_address;
    local resources_token_address;
    local settling_address;
    local food_address;

    let realms_token_id: Uint256 = Uint256(1, 0);
    %{
        ids.resources_token_address = context.resources_token_address
        ids.settling_address = context.settling_address
        ids.food_address = context.food_address
        ids.account_address = context.account_address
        stop_prank = start_prank(ids.account_address, target_contract_address=ids.food_address)
    %}
    mint_resources(resources_token_address, Uint256(1000, 0), account_address);
    Food.create(food_address, realms_token_id, 1, RealmBuildingsIds.Farm);
    time_warp(1000000, food_address);
    Food.harvest(food_address, realms_token_id, HarvestType.Export, RealmBuildingsIds.Farm);
    let (accounts_len, accounts) = get_owners(account_address);
    let (token_ids: Uint256*) = get_resources();
    let (balances_len, balances: Uint256*) = ResourcesToken.balanceOfBatch(
        resources_token_address, accounts_len, accounts, 22, token_ids
    );
    %{
        stop_prank()
    %}
    return ();
}

// TODO
// convert_food_tokens_to_store
// 
