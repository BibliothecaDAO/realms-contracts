%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from tests.protostar.loot.setup.interfaces import IAdventurer, ILoot, ILords, IRealms
from tests.protostar.loot.setup.setup import Contracts, deploy_all

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() 
{
    alloc_locals;

    let addresses: Contracts = deploy_all();

    %{
        context.account_1 = ids.addresses.account_1
        context.adventurer = ids.addresses.adventurer
        context.loot = ids.addresses.loot
    %}
    return ();
}

@external
func test_mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_1_address;
    local loot_address;

    %{
        ids.account_1_address = context.account_1
        ids.loot_address = context.loot
    %}

    ILoot.mint(loot_address, account_1_address);

    // assert

    return ();    
}

@external
func test_update_adventurer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local account_1_address;
    local loot_address;
    local adventurer_address;

    %{
        ids.account_1_address = context.account_1
        ids.loot_address = context.loot
        ids.adventurer_address = context.adventurer
    %}

    ILoot.mint(loot_address, account_1_address);

    %{
        stop_prank_loot = start_prank(ids.adventurer_address, ids.loot_address)
    %}

    ILoot.updateAdventurer(loot_address, Uint256(1,0), 2);

    let (item) = ILoot.getItemByTokenId(loot_address, Uint256(1,0));

    assert item.Adventurer = 2;

    return ();
}