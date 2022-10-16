%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.settling_game.utils.game_structs import RealmData

from contracts.metadata.metadata import Uri

const FAKE_OWNER_ADDR = 20;
const MODULE_CONTROLLER_ADDR = 120325194214501;

@contract_interface
namespace Realms {
    func initializer(name: felt, symbol: felt, proxy_admin: felt) {
    }

    func mint(to: felt, tokenId: Uint256) {
    }

    func approve(to: felt, tokenId: Uint256) {
    }

    func set_realm_data(tokenId: Uint256, _realm_data: felt) {
    }

    func tokenURI(tokenId: Uint256) -> (tokenUri_len: felt, tokenUri: felt*) {
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
    // hint needed for bit mapping later
    %{
        import os, sys
        sys.path.append(os.path.abspath(os.path.dirname(".")))
    %}

    // deploy needed conracts and initialize
    local Realms_token_address;
    local S_Realms_token_address;
    local Settling_address;
    local Module_controller_address;
    %{
        context.Realms_token_address = deploy_contract("./contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo", []).contract_address
        ids.Realms_token_address = context.Realms_token_address
        context.S_Realms_token_address = deploy_contract("./contracts/settling_game/tokens/S_Realms_ERC721_Mintable.cairo", []).contract_address
        ids.S_Realms_token_address = context.S_Realms_token_address
        context.Settling_address = deploy_contract("./contracts/settling_game/modules/settling/Settling.cairo", []).contract_address
        ids.Settling_address = context.Settling_address
    %}
    Realms.initializer(Realms_token_address, 1, 1, 1);
    Settling.initializer(Settling_address, MODULE_CONTROLLER_ADDR, 1);

    return ();
}

@external
func test_set_metadata{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    local Realms_token_address;
    local realms_1_data;
    local realms_2_data;
    %{
        from tests.protostar.utils import utils
        ids.Realms_token_address = context.Realms_token_address
        # needed to fake module controller authoriztion
        stop_mock_1 = mock_call(ids.MODULE_CONTROLLER_ADDR, "get_external_contract_address", [ids.Realms_token_address])
        stop_mock_2 = mock_call(ids.MODULE_CONTROLLER_ADDR, "has_write_access", [1])
        # bitwise mapping functions, set default data with custom order
        ids.realms_1_data = utils.pack_realm(utils.build_realm_order(4, 5, 2, 1, 4, 2, 8, 13, 6, 0, 0, 0, 1, 4))
        ids.realms_2_data = utils.pack_realm(utils.build_realm_order(2, 3, 6, 4, 6, 1, 5, 2, 9, 14, 10, 0, 0, 10))
        # fake owner of realm contract
        store(ids.Realms_token_address, "Ownable_owner", [ids.FAKE_OWNER_ADDR])
        # fake caller to owner
        stop_prank_callable = start_prank(ids.FAKE_OWNER_ADDR, ids.Realms_token_address)
    %}
    Realms.set_realm_data(Realms_token_address, Uint256(1, 0), realms_1_data);
    Realms.set_realm_data(Realms_token_address, Uint256(2, 0), realms_2_data);
    let (data_len, data) = Realms.tokenURI(Realms_token_address, Uint256(1, 0));
    %{
        array = []
        for i in range(ids.data_len):
            path = memory[ids.data+i]
            array.append(path.to_bytes(31, "big").decode())
        print(''.join(array))
    %}
    return ();
}