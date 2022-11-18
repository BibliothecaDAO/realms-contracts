%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.loot.constants.beast import Beast
from contracts.loot.constants.item import Item, ItemIds

from tests.protostar.loot.setup.interfaces import ILoot, IRealms, IAdventurer, IBeast
from tests.protostar.loot.setup.setup import Contracts, deploy_all
from tests.protostar.loot.test_structs import (
    TestAdventurerState,
    get_adventurer_state,
    TestUtils,
    TEST_WEAPON_TOKEN_ID,
    TEST_DAMAGE_HEALTH_REMAINING,
    TEST_DAMAGE_OVERKILL,
)

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let addresses: Contracts = deploy_all();

    %{
        context.account_1 = ids.addresses.account_1
        context.realms = ids.addresses.realms
        context.adventurer = ids.addresses.adventurer
        context.loot = ids.addresses.loot
        context.beast = ids.addresses.beast
        context.lords = ids.addresses.lords
    %}
    let (timestamp) = get_block_timestamp();
    let weapon_id: Item = Item(ItemIds.Wand, 0, 0, 0, 0, 0, 0, 0, 0, timestamp, 0, 0, 0); // Wand
    ILoot.mint(addresses.loot, addresses.account_1);
    ILoot.setItemById(addresses.loot, Uint256(1,0), weapon_id);
    IRealms.set_realm_data(addresses.realms, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(addresses.adventurer, addresses.account_1, 4, 10, 'Test', 8);
    IAdventurer.equipItem(addresses.adventurer, Uint256(1,0), Uint256(1,0));
    return ();
}

@external
func test_attack_beast{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    
    local beast_address;

    %{
        ids.beast_address = context.beast
        stop_mock = mock_call(ids.beast, 'calculate_damage_to_beast', [50])
    %}

    let (adventurer) = get_adventurer_state();
    let (beast) = TestUtils.create_beast(1, 0);

    IBeast.attack_beast(beast_address, adventurer, beast);

    assert beast.Health = beast.Health - TEST_DAMAGE_HEALTH_REMAINING;

    return ();
}