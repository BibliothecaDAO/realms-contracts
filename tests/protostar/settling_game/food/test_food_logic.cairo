%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from tests.protostar.settling_game.setup.helpers import get_resources, get_owners, settle_realm
from tests.protostar.settling_game.setup.interfaces import Realms, ResourcesToken
from tests.protostar.settling_game.setup.setup import deploy_account, deploy_module, deploy_controller, time_warp

from contracts.settling_game.utils.game_structs import ModuleIds
from contracts.settling_game.modules.resources.interface import IResources
from contracts.settling_game.modules.settling.interface import ISettling

from contracts.token.constants import (
    IERC1155_ID,
    IERC1155_METADATA_ID,
    IERC1155_RECEIVER_ID,
    IACCOUNT_ID,
    ON_ERC1155_RECEIVED_SELECTOR,
    ON_ERC1155_BATCH_RECEIVED_SELECTOR,
)

const PK = 11111;
const PK2 = 22222;

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local realms_1_data;
    local realms_2_data;

    let (local account_1_address) = deploy_account(PK);
    let (local account_2_address) = deploy_account(PK2);
    let (local controller_address) = deploy_controller(account_1_address, account_1_address);
    let (local food_address) = deploy_module(
        ModuleIds.L10_Food, controller_address, account_1_address
    );
    let (local resources_address) = deploy_module(
        ModuleIds.Resources, controller_address, account_1_address
    );
    let (local resources_token_address) = deploy_module(
        ModuleIds.Resources_Token, controller_address, account_1_address
    );
    let (local realms_address) = deploy_module(
        ModuleIds.Realms_Token, controller_address, account_1_address
    );
    let (local s_realms_address) = deploy_module(
        ModuleIds.S_Realms_Token, controller_address, account_1_address
    );
    let (local settling_address) = deploy_module(
        ModuleIds.Settling, controller_address, account_1_address
    );
    let (local goblintown_address) = deploy_module(
        ModuleIds.GoblinTown, controller_address, account_1_address
    );
    let (local buildings_address) = deploy_module(
        ModuleIds.Buildings, controller_address, account_1_address
    );
    let (local calculator_address) = deploy_module(
        ModuleIds.Calculator, controller_address, account_1_address
    );
    let (local combat_address) = deploy_module(
        ModuleIds.L06_Combat, controller_address, account_1_address
    );

    %{
        from tests.protostar.utils import utils
        stop_prank_realms = start_prank(ids.account_1_address, target_contract_address=ids.realms_address)
        stop_prank_settling = start_prank(ids.account_1_address, target_contract_address=ids.settling_address)
        context.account_1_address = ids.account_1_address
        context.account_2_address = ids.account_2_address
        context.resources_address = ids.resources_address
        context.resources_token_address = ids.resources_token_address
        context.realms_address = ids.realms_address
        context.settling_address = ids.settling_address
        context.combat_address = ids.combat_address
        ids.realms_1_data = utils.pack_realm(utils.build_realm_order(4, 5, 2, 1, 4, 2, 8, 13, 6, 0, 0, 0, 0, 4))
        ids.realms_2_data = utils.pack_realm(utils.build_realm_order(4, 5, 2, 1, 4, 2, 8, 13, 6, 0, 0, 0, 1, 4))
    %}
    Realms.set_realm_data(realms_address, Uint256(1, 0), 'Test 1', realms_1_data);
    Realms.set_realm_data(realms_address, Uint256(2, 0), 'Test 2', realms_2_data);
    settle_realm(realms_address, settling_address, account_1_address, Uint256(1, 0));
    settle_realm(realms_address, settling_address, account_1_address, Uint256(2, 0));
    %{
        stop_prank_realms()
        stop_prank_settling()
    %}

    return ();
}
