%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.loot.constants.adventurer import AdventurerState, AdventurerStatus
from contracts.loot.constants.beast import Beast
from contracts.loot.beast.library import BeastLib
from contracts.loot.constants.item import (
    Item, 
    ItemIds, 
    ItemType, 
    ItemMaterial, 
    ItemSlot
)
from contracts.loot.constants.rankings import ItemRank
from contracts.loot.loot.stats.combat import CombatStats
from tests.protostar.loot.setup.interfaces import ILoot, IRealms, IAdventurer, IBeast, ILords
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
        context.xoroshiro = ids.addresses.xoroshiro
        context.realms = ids.addresses.realms
        context.adventurer = ids.addresses.adventurer
        context.loot = ids.addresses.loot
        context.beast = ids.addresses.beast
        context.lords = ids.addresses.lords
        stop_prank_realms = start_prank(ids.addresses.account_1, ids.addresses.realms)
        stop_prank_adventurer = start_prank(ids.addresses.account_1, ids.addresses.adventurer)
        stop_prank_lords = start_prank(ids.addresses.account_1, ids.addresses.lords)
        stop_prank_loot = start_prank(ids.addresses.adventurer, ids.addresses.loot)
    %}

    ILords.approve(addresses.lords, addresses.adventurer, Uint256(100000000000000000000, 0));
    IRealms.set_realm_data(addresses.realms, Uint256(13, 0), 'Test Realm', 1);

    %{
        stop_prank_lords()
    %}
    IAdventurer.mint(addresses.adventurer, addresses.account_1, 4, 10, 'Test', 8, 1, 1);
    ILoot.mint(addresses.loot, addresses.account_1, Uint256(1,0));
    %{
        stop_prank_loot()
        stop_prank_loot = start_prank(ids.addresses.account_1, ids.addresses.loot)
    %}

    ILoot.set_item_by_id(addresses.loot, Uint256(1,0), ItemIds.Wand, 10, 0, 0, 0);
    %{
        stop_prank_loot()
    %}
    IAdventurer.equip_item(addresses.adventurer, Uint256(1,0), Uint256(1,0));
    %{
        stop_prank_realms()
        stop_prank_adventurer()
    %}
    return ();
}

@external
func test_create{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local account_1_address;
    local xoroshiro_address;
    local adventurer_address;
    local beast_address;

    %{
        ids.account_1_address = context.account_1
        ids.xoroshiro_address = context.xoroshiro
        ids.adventurer_address = context.adventurer
        ids.beast_address = context.beast
        stop_prank_beast = start_prank(ids.adventurer_address, ids.beast_address)
        stop_mock = mock_call(ids.xoroshiro_address, 'next', [0])
    %}

    let (beast_id) = IBeast.create(beast_address, Uint256(1,0));

    let (beast) = IBeast.get_beast_by_id(beast_address, beast_id);

    assert beast.Id = 1;
    assert beast.Health = 100;
    assert beast.AttackType = 103;
    assert beast.ArmorType = 203;
    assert beast.Rank = 1;
    assert beast.Prefix_1 = 1;
    assert beast.Prefix_2 = 1;
    assert beast.Adventurer = 1;
    assert beast.XP = 0;
    assert beast.Level = 1;
    assert beast.SlainOnDate = 0;

    return ();
}

@external
func test_not_kill{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    
    local account_1_address;
    local xoroshiro_address;
    local adventurer_address;
    local beast_address;

    %{
        ids.account_1_address = context.account_1
        ids.xoroshiro_address = context.xoroshiro
        ids.adventurer_address = context.adventurer
        ids.beast_address = context.beast
        # 1%4 = 1, therefore DiscoveryType beast
        stop_mock = mock_call(ids.xoroshiro_address, 'next', [1])
        # now we are timsing by timestamp we also need this 
        stop_roll_adventurer = roll(1, ids.adventurer_address)
        stop_roll_beast = roll(1, ids.beast_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
        from tests.protostar.loot.utils import utils
        # need to store adventurer level to greater than 1 to avoid starter beast
        p1, p2, p3, p4 = utils.pack_adventurer(utils.build_adventurer_level(2))
        store(ids.adventurer_address, "adventurer_dynamic", [p1, p2, p3, p4], key=[1,0])
    %}
    // discover beast

    let adventurer_token_id_1 = Uint256(1,0);
    let beast_token_id_1 = Uint256(1,0);
    
    IAdventurer.explore(adventurer_address, adventurer_token_id_1);

    let (local adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, adventurer_token_id_1);

    %{ 
        stop_roll_adventurer()
        stop_roll_beast = roll(1, ids.beast_address)
        stop_mock()
        stop_prank_adventurer()
        stop_prank_beast = start_prank(ids.account_1_address, ids.beast_address)
    %}

    IBeast.attack(beast_address, beast_token_id_1);

    let (updated_beast) = IBeast.get_beast_by_id(beast_address,beast_token_id_1);

    assert updated_beast.Id = 2;
    assert updated_beast.Level = 2;
    // since we have overwritten adventurer (made level 2 and so removed wand) we will do no damage
    assert updated_beast.Health = 100;

    let (updated_adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, adventurer_token_id_1);

    // adventurer took 24 damage from the beasts counter attack
    assert updated_adventurer.Health = 76;

    // TODO LH: verify neither beast nor adventurer gained xp

    return ();
}

@external
func test_kill{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    
    local account_1_address;
    local xoroshiro_address;
    local adventurer_address;
    local beast_address;
    local loot_address;

    %{
        ids.account_1_address = context.account_1
        ids.xoroshiro_address = context.xoroshiro
        ids.adventurer_address = context.adventurer
        ids.beast_address = context.beast
        ids.loot_address = context.loot
        # 1%4 = 1, therefore DiscoveryType beast
        stop_mock = mock_call(ids.xoroshiro_address, 'next', [1])
        # now we are timsing by timestamp we also need this 
        stop_roll_adventurer = roll(1, ids.adventurer_address)
        stop_roll_beast = roll(1, ids.beast_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
        stop_prank_loot = start_prank(ids.account_1_address, ids.loot_address)
    %}
    // discover beast
    let adventurer_token_id = Uint256(1,0);
    IAdventurer.explore(adventurer_address, adventurer_token_id);

    %{ 
        stop_mock()
        stop_prank_adventurer()
    %}

    let loot_token_id = Uint256(1,0);
    ILoot.set_item_by_id(loot_address, loot_token_id, ItemIds.Katana, 20, 0, 0, 0);

    %{
        stop_prank_loot()
        stop_prank_beast = start_prank(ids.account_1_address, ids.beast_address)
    %}

    let beast_token_id = Uint256(1,0);
    IBeast.attack(beast_address, beast_token_id);

    let (local updated_beast) = IBeast.get_beast_by_id(beast_address, beast_token_id);

    let (local adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, adventurer_token_id);

    // Beast should be dead
    assert updated_beast.Health = 0;

    // Since it was a one-hit kill, adventurer didn't take damage
    assert adventurer.Health = 100;

    // check our adventurer earned xp for the kill
    let (expected_xp) = CombatStats.calculate_xp_earned(updated_beast.Rank, updated_beast.Level);
    // Since we used a new adventurer, this should be the only xp they have gained
    assert adventurer.XP = 10;

    return ();
}

@external
func test_ambushed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    
    local account_1_address;
    local xoroshiro_address;
    local adventurer_address;
    local beast_address;

    %{
        ids.account_1_address = context.account_1
        ids.xoroshiro_address = context.xoroshiro
        ids.adventurer_address = context.adventurer
        ids.beast_address = context.beast
        # 1%4 = 1, therefore DiscoveryType beast
        stop_mock = mock_call(ids.xoroshiro_address, 'next', [1])
        # now we are timsing by timestamp we also need this 
        stop_roll_adventurer = roll(1, ids.adventurer_address)
        stop_roll_beast = roll(1, ids.beast_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}
    // discover beast

    IAdventurer.explore(adventurer_address, Uint256(1,0));

    %{ 
        stop_mock()
        stop_prank_adventurer()
        # 2%4 = 2, therefore not fleeing
        stop_mock_flee_random = mock_call(ids.xoroshiro_address, 'next', [2])
        # now we are timsing by timestamp we also need this 
        stop_roll = roll(1, ids.adventurer_address)
        stop_prank_beast = start_prank(ids.account_1_address, ids.beast_address)
    %}

    IBeast.flee(beast_address, Uint256(1,0));

    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1,0));

    assert adventurer.Status = AdventurerStatus.Battle;

    return ();
}

@external
func test_flee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    
    local account_1_address;
    local xoroshiro_address;
    local adventurer_address;
    local beast_address;

    %{
        ids.account_1_address = context.account_1
        ids.xoroshiro_address = context.xoroshiro
        ids.adventurer_address = context.adventurer
        ids.beast_address = context.beast
        # 1%4 = 1, therefore DiscoveryType beast
        stop_mock = mock_call(ids.xoroshiro_address, 'next', [1])
        # now we are timsing by timestamp we also need this
        stop_roll_adventurer = roll(1, ids.adventurer_address)
        stop_roll_beast = roll(1, ids.beast_address)
        stop_prank_adventurer = start_prank(ids.account_1_address, ids.adventurer_address)
    %}
    // discover beast

    IAdventurer.explore(adventurer_address, Uint256(1,0));

    %{ 
        stop_mock()
        stop_prank_adventurer()
        stop_prank_beast = start_prank(ids.account_1_address, ids.beast_address)
        # 3%4 = 3, therefore fleeing
        stop_mock_flee_random = mock_call(ids.xoroshiro_address, 'next', [3])
        # now we are timsing by timestamp we also need this
        stop_roll = roll(1, ids.beast_address)
    %}

    IBeast.flee(beast_address, Uint256(1,0));

    let (adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(1,0));

    assert adventurer.Status = AdventurerStatus.Idle;

    return ();
}

@external
func test_increase_xp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    
    local account_1_address;
    local xoroshiro_address;
    local beast_address;
    local adventurer_address;

    %{
        ids.account_1_address = context.account_1
        ids.xoroshiro_address = context.xoroshiro
        ids.beast_address = context.beast
        ids.adventurer_address = context.adventurer
        stop_roll_beast = roll(1, ids.beast_address)
        stop_prank_adventurer = start_prank(ids.adventurer_address, ids.beast_address)
    %}

    let beast_token_id = Uint256(1,0);
    let (beast_id) = IBeast.create(beast_address, beast_token_id);
    let (beast) = IBeast.get_beast_by_id(beast_address, beast_token_id);
    let (_, beast_dynamic) = BeastLib.split_data(beast);

    // Give our level 1 beast 10 XP (started with 1XP)
    let (returned_beast_plus_10xp) = IBeast.increase_xp(beast_address, beast_token_id, beast_dynamic, 10);
    let (onchain_beast_plus_10xp) = IBeast.get_beast_by_id(beast_address, beast_token_id);

    // verify it's now level 2 with 11xp
    // both in the returned beast and on-chain
    assert returned_beast_plus_10xp.XP = 10;
    assert returned_beast_plus_10xp.Level = 2;
    assert onchain_beast_plus_10xp.XP = returned_beast_plus_10xp.XP;
    assert onchain_beast_plus_10xp.Level = returned_beast_plus_10xp.Level;

    return ();
}