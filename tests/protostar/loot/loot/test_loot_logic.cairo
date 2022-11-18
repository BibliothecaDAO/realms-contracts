%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

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

    return ();    
}