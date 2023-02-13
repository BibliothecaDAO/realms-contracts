%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from contracts.settling_game.utils.game_structs import Cost, Squad

const MODULE_CONTROLLER_ADDR = 120325194214501;
const FAKE_OWNER_ADDR = 20;

// custom interface with only the funcs used in the tests
@contract_interface
namespace IResources {
    func initializer(controller_addr, proxy_admin) {
    }

    func claim_resources(token_id: Uint256) {
    }

    func pillage_resources(token_id: Uint256, claimer) {
    }

    func wonder_claim(token_id: Uint256) {
    }
}

@contract_interface
namespace Realms {
    func initializer(name: felt, symbol: felt, proxy_admin: felt) {
    }

    func mint(to: felt, tokenId: Uint256) {
    }

    func approve(to: felt, tokenId: Uint256) {
    }
}

@contract_interface
namespace Settling {
    func initializer(address_of_controller: felt, proxy_admin: felt) {
    }

    func settle(token_id: Uint256) -> (success: felt) {
    }
}

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local Resources_address;
    local Realms_token_address;
    local S_Realms_token_address;
    local Settling_address;
    %{
        context.Resources_address = deploy_contract("./contracts/settling_game/modules/resources/Resources.cairo", []).contract_address
        ids.Resources_address = context.Resources_address
        context.Realms_token_address = deploy_contract("./contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo", []).contract_address
        ids.Realms_token_address = context.Realms_token_address
        context.S_Realms_token_address = deploy_contract("./contracts/settling_game/tokens/S_Realms_ERC721_Mintable.cairo", []).contract_address
        ids.S_Realms_token_address = context.S_Realms_token_address
        context.Settling_address = deploy_contract("./contracts/settling_game/modules/settling/Settling.cairo", []).contract_address
        ids.Settling_address = context.Settling_address
    %}
    IResources.initializer(Resources_address, MODULE_CONTROLLER_ADDR, 1);
    Realms.initializer(Realms_token_address, 1, 1, 1);
    Settling.initializer(Settling_address, MODULE_CONTROLLER_ADDR, 1);

    let realms_token_id = Uint256(1, 0);

    %{ stop_prank_callable = start_prank(ids.FAKE_OWNER_ADDR, target_contract_address=ids.Realms_token_address) %}

    Realms.mint(Realms_token_address, FAKE_OWNER_ADDR, realms_token_id);
    // let (caller) = get_caller_address()
    // assert FAKE_OWNER_ADDR = caller
    Realms.approve(Realms_token_address, Settling_address, realms_token_id);
    Settling.settle(Settling_address, realms_token_id);

    %{ stop_prank_callable() %}

    return ();
}

// TODO:
// test_claim_resources
// test_pillage_resources
// test_wonder_claim
