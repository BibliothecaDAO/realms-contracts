%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from tests.protostar.setup.setup import deploy_module, deploy_controller, time_warp

from contracts.settling_game.utils.game_structs import ModuleIds
from contracts.settling_game.modules.resources.interface import IResources
from contracts.settling_game.modules.settling.interface import ISettling

const FAKE_OWNER_ADDRESS = 20;

@contract_interface
namespace IRealms {
    func mint(to: felt, amount: Uint256) {
    }
    func approve(to: felt, tokenId: Uint256) {
    }
}

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    let (local controller_address) = deploy_controller(FAKE_OWNER_ADDRESS, FAKE_OWNER_ADDRESS);
    let (local resources_address) = deploy_module(ModuleIds.Resources, controller_address, FAKE_OWNER_ADDRESS);
    let (local realms_address) = deploy_module(ModuleIds.Realms_Token, controller_address, FAKE_OWNER_ADDRESS);
    let (local s_realms_address) = deploy_module(ModuleIds.S_Realms_Token, controller_address, FAKE_OWNER_ADDRESS);
    let (local settling_address) = deploy_module(ModuleIds.Settling, controller_address, FAKE_OWNER_ADDRESS);
    let (local goblintown_address) = deploy_module(ModuleIds.GoblinTown, controller_address, FAKE_OWNER_ADDRESS);
    let (local buildings_address) = deploy_module(ModuleIds.Buildings, controller_address, FAKE_OWNER_ADDRESS);
    let (local food_address) = deploy_module(ModuleIds.L10_Food, controller_address, FAKE_OWNER_ADDRESS);
    let (local calculator_address) = deploy_module(ModuleIds.Calculator, controller_address, FAKE_OWNER_ADDRESS);

    let realms_token_id: Uint256 = Uint256(1, 0);

    %{ 
        stop_prank_realms = start_prank(ids.FAKE_OWNER_ADDRESS, target_contract_address=ids.realms_address)
        stop_prank_settling = start_prank(ids.FAKE_OWNER_ADDRESS, target_contract_address=ids.settling_address)
        context.controller_address = ids.controller_address
        context.resources_address = ids.resources_address
        context.realms_address = ids.realms_address
        context.s_realms_address = ids.s_realms_address
        context.goblintown_address = ids.goblintown_address
        context.buildings_address = ids.buildings_address
        # context.realms_token_id = reflect.realms_token_id.get()
    %}
    // IRealms.
    IRealms.mint(realms_address, FAKE_OWNER_ADDRESS, realms_token_id);
    IRealms.approve(realms_address, settling_address, realms_token_id);
    ISettling.settle(settling_address, realms_token_id);

    %{ stop_prank_realms() %}

    return ();
}

@external
func test_claim_resources{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;
    local resources_address;
    local realms_token_id: Uint256;

    let realms_token_id: Uint256 = Uint256(1, 0);
    %{
        ids.resources_address = context.resources_address
        stop_prank_settling = start_prank(ids.FAKE_OWNER_ADDRESS, target_contract_address=ids.resources_address)
        # ids.realms_token_id = context.realms_token_id
    %}
    time_warp(1000000, resources_address);
    IResources.claim_resources(resources_address, realms_token_id);
    
    return ();
}

// TODO:
// test_claim_resources
// test_pillage_resources
// test_wonder_claim