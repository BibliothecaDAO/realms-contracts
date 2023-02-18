%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256

from tests.protostar.loot.setup.interfaces import IAdventurer, ILoot, ILords, IRealms
from tests.protostar.loot.setup.setup import Contracts, deploy_all

from contracts.loot.constants.item import ItemIds

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let addresses: Contracts = deploy_all();

    %{
        context.account_1 = ids.addresses.account_1
        context.adventurer = ids.addresses.adventurer
        context.loot = ids.addresses.loot
        context.realms = ids.addresses.realms
        stop_prank_lords = start_prank(ids.addresses.account_1, ids.addresses.lords)
    %}

    ILords.approve(addresses.lords, addresses.adventurer, Uint256(100000000000000000000, 0));

    %{ stop_prank_lords() %}

    return ();
}

@external
func test_mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_1_address;
    local loot_address;
    local adventurer_address;
    local realms_address;

    %{
        ids.account_1_address = context.account_1
        ids.loot_address = context.loot
        ids.adventurer_address = context.adventurer
        ids.realms_address = context.realms
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
        stop_prank_loot = start_prank(ids.adventurer_address, ids.loot_address)
    %}

    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);

    ILoot.mint(loot_address, account_1_address, Uint256(1, 0));

    let (item) = ILoot.get_item_by_token_id(loot_address, Uint256(1, 0));

    assert_not_zero(item.Id);

    return ();
}

@external
func test_mint_starter_weapon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_1_address;
    local loot_address;
    local adventurer_address;
    local realms_address;

    %{
        ids.account_1_address = context.account_1
        ids.loot_address = context.loot
        ids.adventurer_address = context.adventurer
        ids.realms_address = context.realms
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
        stop_prank_loot = start_prank(ids.adventurer_address, ids.loot_address)
    %}


    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);

    // Mint a starter item for the adventurer (book)
    ILoot.mint_starter_weapon(loot_address, account_1_address, ItemIds.Book, Uint256(1, 0));

    // Get item from the contract
    let (item) = ILoot.get_item_by_token_id(loot_address, Uint256(1, 0));

    // Verify it is indeed a book
    assert item.Id = ItemIds.Book;

    return ();
}

@external
func test_set_item{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local account_1_address;
    local loot_address;
    local adventurer_address;
    local realms_address;

    %{
        ids.account_1_address = context.account_1
        ids.loot_address = context.loot
        ids.adventurer_address = context.adventurer
        ids.realms_address = context.realms
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
        stop_prank_loot = start_prank(ids.adventurer_address, ids.loot_address)
    %}

    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);

    ILoot.mint(loot_address, account_1_address, Uint256(1, 0));

    %{
        stop_prank_loot()
        stop_prank_loot = start_prank(ids.account_1_address, ids.loot_address)
    %}

    ILoot.set_item_by_id(loot_address, Uint256(1, 0), 20, 5, 100, 1, 30);

    let (item) = ILoot.get_item_by_token_id(loot_address, Uint256(1, 0));

    assert item.Id = 20;
    assert item.Greatness = 5;
    assert item.XP = 100;
    assert item.Adventurer = 1;
    assert item.Bag = 30;

    return ();
}

@external
func test_update_adventurer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    local account_1_address;
    local loot_address;
    local adventurer_address;
    local realms_address;

    %{
        ids.account_1_address = context.account_1
        ids.loot_address = context.loot
        ids.adventurer_address = context.adventurer
        ids.realms_address = context.realms
        stop_prank_realms = start_prank(ids.account_1_address, ids.realms_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
        stop_prank_loot = start_prank(ids.adventurer_address, ids.loot_address)
    %}

    IRealms.set_realm_data(realms_address, Uint256(13, 0), 'Test Realm', 1);
    IAdventurer.mint(adventurer_address, account_1_address, 4, 10, 'Test', 8, 1, 1);

    ILoot.mint(loot_address, account_1_address, Uint256(1, 0));

    %{ 
        stop_prank_loot()
        stop_prank_loot = start_prank(ids.adventurer_address, ids.loot_address) 
    %}

    ILoot.update_adventurer(loot_address, Uint256(1, 0), 2);

    let (item) = ILoot.get_item_by_token_id(loot_address, Uint256(1, 0));

    assert item.Adventurer = 2;

    return ();
}

