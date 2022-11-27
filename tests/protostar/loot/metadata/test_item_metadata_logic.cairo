%lang starknet

from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.loot.loot.metadata import LootUri
from contracts.loot.constants.adventurer import AdventurerState
from contracts.loot.constants.item import Item, ItemIds
from contracts.loot.loot.stats.item import ItemStats
from contracts.settling_game.utils.game_structs import ExternalContractIds

from tests.protostar.loot.setup.interfaces import IAdventurer, ILoot, ILords, IRealms
from tests.protostar.loot.setup.setup import Contracts, deploy_all

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    let addresses: Contracts = deploy_all();

    %{
        context.account_1 = ids.addresses.account_1
        context.loot = ids.addresses.loot
        context.lords = ids.addresses.lords
        stop_prank_realms = start_prank(ids.addresses.account_1, ids.addresses.realms)
        stop_prank_adventurer = start_prank(ids.addresses.account_1, ids.addresses.adventurer)
        stop_prank_loot = start_prank(ids.addresses.account_1, ids.addresses.loot)
        stop_prank_lords = start_prank(ids.addresses.account_1, ids.addresses.lords)
    %}
    IRealms.set_realm_data(addresses.realms, Uint256(10, 0), 'Test Realm', 1); 
    // Store item ids and equip to adventurer

    let (timestamp) = get_block_timestamp();

    %{
        stop_mock = mock_call(1, 'next', [1])
    %}
    // Mint a token
    ILoot.mint(addresses.loot, addresses.account_1);
    %{
        stop_mock()
    %}

    // Set tokens to ids above for testing
    ILoot.setItemById(addresses.loot, Uint256(1,0), ItemIds.Wand, 15, 100, 0, 0);

    ILords.approve(addresses.lords, addresses.adventurer, Uint256(100,0));

    %{
        stop_prank_lords()
        stop_prank_lords = start_prank(ids.addresses.adventurer, ids.addresses.lords)
    %}

    // Mint adventurer with random params
    IAdventurer.mint(addresses.adventurer, addresses.account_1, 4, 10, 'Test', 8, 1, 1);

    %{
        stop_prank_loot()
    %}
    IAdventurer.equip_item(addresses.adventurer, Uint256(1,0), Uint256(1,0));

    %{
        stop_prank_realms()
        stop_prank_adventurer()
        stop_prank_lords()
    %}
    return ();
}

@external
func test_metadata{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local loot_address;

    %{
        ids.loot_address = context.loot
    %}
    let (data_len, data) = ILoot.tokenURI(loot_address, Uint256(1,0));

    %{
        array = []
        for i in range(ids.data_len):
            path = memory[ids.data+i]
            array.append(path.to_bytes(31, "big").decode())
        string_data = ''.join(array).replace('\x00', '')
        print(string_data)
        # assert string_data == 'data:application/json,{"description":"Loot","name":"War Belt","image":"https://d23fdhqc1jb9no.cloudfront.net/Item/88.webp","attributes":[{"trait_type":"Slot","value":"Waist"},{"trait_type":"Type","value":"Metal Armor"},{"trait_type":"Material","value":"Generic Metal"},{"trait_type":"Rank","value":"2"},{"trait_type":"Greatness","value":"0"},{"trait_type":"Created Block","value":"0"},{"trait_type":"XP","value":"0"},{"trait_type":"Adventurer","value":"Test"},{"trait_type":"Bag","value":"0"},]}'
    %}

    return ();
}
