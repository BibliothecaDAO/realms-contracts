%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from tests.protostar.setup.setup import deploy_module

from contracts.settling_game.utils.game_structs import ModuleIds
from contracts.settling_game.modules.resources.interface import IResources
from contracts.settling_game.modules.settling.interface import ISettling

const MODULE_CONTROLLER_ADDR = 120325194214501;
const FAKE_OWNER_ADDR = 20;

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

    let (resources_address) = deploy_module(ModuleIds.Resources, MODULE_CONTROLLER_ADDR, FAKE_OWNER_ADDR);
    let (realms_address) = deploy_module(ModuleIds.Realms_Token, MODULE_CONTROLLER_ADDR, FAKE_OWNER_ADDR);
    let (s_realms_address) = deploy_module(ModuleIds.S_Realms_Token, MODULE_CONTROLLER_ADDR, FAKE_OWNER_ADDR);
    let (settling_address) = deploy_module(ModuleIds.Settling, MODULE_CONTROLLER_ADDR, FAKE_OWNER_ADDR);

    let realms_token_id = Uint256(1, 0);

    %{ stop_prank_callable = start_prank(ids.FAKE_OWNER_ADDR, target_contract_address=ids.realms_address) %}

    IRealms.mint(realms_address, FAKE_OWNER_ADDR, realms_token_id);
    // let (caller) = get_caller_address()
    // assert FAKE_OWNER_ADDR = caller
    IRealms.approve(realms_address, settling_address, realms_token_id);
    ISettling.settle(settling_address, realms_token_id);

    %{ stop_prank_callable() %}

    return ();
}

@external
func test_quick{syscall_ptr: felt*, range_check_ptr}() {
    assert 1 = 1;
    return ();
}

// TODO:
// test_claim_resources
// test_pillage_resources
// test_wonder_claim