%lang starknet

from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.loot.loot.metadata import Uri
from contracts.loot.constants.adventurer import AdventurerState
from contracts.loot.constants.item import Item, ItemIds
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
namespace Loot {
    func initializer(
        name: felt, 
        symbol: felt, 
        proxy_admin: felt, 
        xoroshiro_address_: felt,
        controller_address: felt
    ) {
    }
    func mint(to: felt) {
    }
    func setItemById(
        tokenId: Uint256,
        item: Item
    ) {
    }
    func getItemByTokenId(tokenId: Uint256) -> (item: Item) {
    }
    func tokenURI(tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
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
    func mint(to: felt, race: felt, home_realm: felt, name: felt, order: felt) {
    }
    func equipItem(tokenId: Uint256, itemTokenId: Uint256) -> (success: felt) {
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
    local loot_address;
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
        declared = declare("./contracts/loot/loot/Loot.cairo")
        ids.loot_address = deploy_contract("./contracts/settling_game/proxy/PROXY_LOGIC.cairo",
            [declared.class_hash]
        ).contract_address
        context.loot_address = ids.loot_address
        declared = declare("./contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo")
        ids.lords_address = deploy_contract("./contracts/settling_game/proxy/PROXY_LOGIC.cairo",
            [declared.class_hash]
        ).contract_address
        context.lords_address = ids.lords_address
        stop_prank_realms = start_prank(ids.FAKE_OWNER_ADDR, ids.realms_address)
        stop_prank_controller = start_prank(ids.FAKE_OWNER_ADDR, ids.controller_address)
        stop_prank_adventurer = start_prank(ids.FAKE_OWNER_ADDR, ids.adventurer_address)
        stop_prank_loot = start_prank(ids.FAKE_OWNER_ADDR, ids.loot_address)
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
        adventurer_address, 1, 1, FAKE_OWNER_ADDR, 1, loot_address, 1, lords_address, controller_address
    );
    Controller.set_address_for_external_contract(
        controller_address, ExternalContractIds.Adventurer, adventurer_address
    );    
    Loot.initializer(loot_address, 1, 1, FAKE_OWNER_ADDR, 1, controller_address);
    Controller.set_address_for_external_contract(
        controller_address, ExternalContractIds.Loot, loot_address
    );
    Lords.initializer(lords_address, 1, 1, 18, Uint256(1000, 0), FAKE_OWNER_ADDR, FAKE_OWNER_ADDR);

    // Store item ids and equip to adventurer

    let (timestamp) = get_block_timestamp();

    let weapon_id: Item = Item(ItemIds.Wand, 0, 0, 0, 0, 0, 0, 0, 40, timestamp, 100, 0, 0); // Wand

    %{
        stop_mock = mock_call(1, 'next', [1])
    %}
    // Mint a token
    Loot.mint(loot_address, FAKE_OWNER_ADDR);
    %{
        stop_mock()
    %}

    // Set tokens to ids above for testing
    Loot.setItemById(loot_address, Uint256(0,0), weapon_id);

    // Mint adventurer with random params
    Adventurer.mint(adventurer_address, FAKE_OWNER_ADDR, 4, 10, 'Test', 8);

    Adventurer.equipItem(adventurer_address, Uint256(1,0), Uint256(0,0));

    %{
        stop_prank_realms()
        stop_prank_controller()
        stop_prank_adventurer()
        stop_prank_loot()
        stop_prank_lords()
    %}
    return ();
}

@external
func test_metadata{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local adventurer_address;
    local realms_address;
    local loot_address;

    %{
        ids.adventurer_address = context.adventurer_address
        ids.realms_address = context.realms_address
        ids.loot_address = context.loot_address
        stop_prank = start_prank(ids.FAKE_OWNER_ADDR, ids.adventurer_address)
    %}
    let (data_len, data) = Loot.tokenURI(loot_address, Uint256(0,0));

    %{
        array = []
        for i in range(ids.data_len):
            path = memory[ids.data+i]
            array.append(path.to_bytes(31, "big").decode())
        string_data = ''.join(array).replace('\x00', '')
        assert string_data == 'data:application/json,{"description":"Loot","name":"Agony Bane Wand Of Power","image":"https://d23fdhqc1jb9no.cloudfront.net/Item/12.webp","attributes":[{"trait_type":"Slot","value":"Weapon"},{"trait_type":"Type","value":"Magic Weapon"},{"trait_type":"Material","value":"Oak Hard Wood"},{"trait_type":"Rank","value":"4"},{"trait_type":"Greatness","value":"40"},{"trait_type":"Created Block","value":"0"},{"trait_type":"XP","value":"100"},{"trait_type":"Adventurer","value":"Test"},{"trait_type":"Bag","value":"0"},]}'
    %}

    return ();
}
