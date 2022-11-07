%lang starknet

from starkware.cairo.common.uint256 import Uint256, uint256_add

from contracts.loot.metadata import Uri
from contracts.loot.constants.adventurer import AdventurerState
from contracts.loot.constants.item import ItemIds
from contracts.settling_game.utils.game_structs import ExternalContractIds

@contract_interface
namespace Controller {
    func initializer(arbiter: felt, proxy_admin: felt) {
    }
    func set_address_for_external_contract(external_contract_id: felt, contract: felt) {
    }
}

@contract_interface
namespace Realms {
    func initializer(name: felt, symbol: felt, proxy_admin: felt) {
    }
    func set_realm_data(tokenId: Uint256, _realm_name: felt, _realm_data: felt) {
    }
}

@contract_interface
namespace Lords {
    func initializer(
        name: felt,
        symbol: felt,
        decimals: felt,
        initial_supply: Uint256,
        recipient: felt,
        proxy_admin: felt,
    ) {
    }
}

@contract_interface
namespace Adventurer {
    func initializer(
        name: felt,
        symbol: felt,
        proxy_admin: felt,
        xoroshiro_address_: felt,
        item_address_: felt,
        bag_address_: felt,
        lords_address_: felt,
        address_of_controller: felt,
    ) {
    }
    func mint(to: felt) {
    }
    func birth(id: Uint256, race: felt, home_realm: felt, name: felt, order: felt) {
    }
    func tokenURI(tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
    }
}

const FAKE_OWNER_ADDR = 20;

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local controller_address;
    local adventurer_address;
    local realms_address;
    local lords_address;

    %{
        declared = declare("./contracts/settling_game/ModuleController.cairo")
        ids.controller_address = deploy_contract("./contracts/settling_game/proxy/PROXY_LOGIC.cairo",
            [declared.class_hash]
        ).contract_address
        declared = declare("./contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo")
        ids.realms_address = deploy_contract("./contracts/settling_game/proxy/PROXY_LOGIC.cairo",
            [declared.class_hash]
        ).contract_address
        context.realms_address = ids.realms_address
        declared = declare("./contracts/loot/adventurer/Adventurer.cairo")
        ids.adventurer_address = deploy_contract("./contracts/settling_game/proxy/PROXY_LOGIC.cairo",
            [declared.class_hash]
        ).contract_address
        context.adventurer_address = ids.adventurer_address
        declared = declare("./contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo")
        ids.lords_address = deploy_contract("./contracts/settling_game/proxy/PROXY_LOGIC.cairo",
            [declared.class_hash]
        ).contract_address
        context.lords_address = ids.lords_address
        stop_prank_realms = start_prank(ids.FAKE_OWNER_ADDR, ids.realms_address)
        stop_prank_controller = start_prank(ids.FAKE_OWNER_ADDR, ids.controller_address)
        stop_prank_lords = start_prank(ids.FAKE_OWNER_ADDR, ids.lords_address)
    %}
    Controller.initializer(controller_address, FAKE_OWNER_ADDR, FAKE_OWNER_ADDR);
    Controller.set_address_for_external_contract(
        controller_address, ExternalContractIds.Realms, realms_address
    );
    Controller.set_address_for_external_contract(
        controller_address, ExternalContractIds.Lords, lords_address
    );
    Realms.initializer(realms_address, 1, 1, FAKE_OWNER_ADDR);
    Realms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    Adventurer.initializer(
        adventurer_address, 1, 1, FAKE_OWNER_ADDR, 1, 1, 1, lords_address, controller_address
    );
    Lords.initializer(lords_address, 1, 1, 18, Uint256(1000, 0), FAKE_OWNER_ADDR, FAKE_OWNER_ADDR);
    %{
        stop_prank_realms()
        stop_prank_controller()
        stop_prank_lords()
    %}
    return ();
}

@external
func test_metadata{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local adventurer_address;
    local realms_address;

    %{
        ids.adventurer_address = context.adventurer_address
        ids.realms_address = context.realms_address
        stop_prank = start_prank(ids.FAKE_OWNER_ADDR, ids.adventurer_address)
    %}
    let id = Uint256(1, 0);
    Adventurer.mint(adventurer_address, FAKE_OWNER_ADDR);
    Adventurer.birth(adventurer_address, id, 4, 10, 'Test', 8);
    let (data_len, data) = Adventurer.tokenURI(adventurer_address, id);

    %{
        array = []
        for i in range(ids.data_len):
            path = memory[ids.data+i]
            array.append(path.to_bytes(31, "big").decode())
        string_data = ''.join(array).replace('\x00', '')
        print(string_data)
    %}

    return ();
}
