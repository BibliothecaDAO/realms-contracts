%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from contracts.loot.beast.stats.beast import BeastStats
from contracts.loot.beast.library import BeastLib
from contracts.loot.constants.beast import (
    Beast,
    BeastStatic,
    BeastDynamic,
    BeastIds, 
    BeastRank, 
    BeastType
)
from tests.protostar.loot.test_structs import (
    TestUtils,
    TEST_DAMAGE_HEALTH_REMAINING,
    TEST_DAMAGE_OVERKILL,
)

@external
func test_beast_rank{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (phoenix_rank) = BeastStats.get_rank_from_id(BeastIds.Phoenix);
    assert phoenix_rank = BeastRank.Phoenix;

    let (orc_rank) = BeastStats.get_rank_from_id(BeastIds.Orc);
    assert orc_rank = BeastRank.Orc;

    let (rat_rank) = BeastStats.get_rank_from_id(BeastIds.Rat);
    assert rat_rank = BeastRank.Rat;

    return ();
}

@external
func test_beast_type{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (phoenix_type) = BeastStats.get_type_from_id(BeastIds.Phoenix);
    assert phoenix_type = BeastType.Phoenix;

    let (orc_type) = BeastStats.get_type_from_id(BeastIds.Orc);
    assert orc_type = BeastType.Orc;

    let (rat_type) = BeastStats.get_type_from_id(BeastIds.Rat);
    assert rat_type = BeastType.Rat;

    return ();
}

@external
func test_pack{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let beast_static = BeastStatic(
        1,
        1,
        1,
        1,
        0,
        0
    );

    let beast_dynamic = BeastDynamic(
        100,
        5,
        0,
        0
    );

    let (packed_beast) = BeastLib.pack(beast_dynamic);

    let (unpacked_beast: BeastDynamic) = BeastLib.unpack(packed_beast);

    assert unpacked_beast.Health = 100;
    assert unpacked_beast.Rank = 5;
    assert unpacked_beast.Adventurer = 0;
    assert unpacked_beast.XP = 0;

    return ();
}

@external
func test_cast{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (beast_static, beast_dynamic) = TestUtils.create_beast(1);

    let (packed_beast) = BeastLib.pack(beast_dynamic);

    let (beast: BeastDynamic) = BeastLib.unpack(packed_beast);

    let (c) = BeastLib.cast_state(1, 50, beast);

    %{ print('Health', ids.c.Health) %}

    return ();
}

@external
func test_deduct_health{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}() {
    alloc_locals;
    
    let (beast_static, beast_dynamic) = TestUtils.create_beast(1);

    let (packed_beast) = BeastLib.pack(beast_dynamic);

    let (beast: BeastDynamic) = BeastLib.unpack(packed_beast);

    let (c) = BeastLib.deduct_health(TEST_DAMAGE_HEALTH_REMAINING, beast);

    assert c.Health = beast.Health - TEST_DAMAGE_HEALTH_REMAINING;

    let (c) = BeastLib.deduct_health(TEST_DAMAGE_OVERKILL, beast);

    assert c.Health = 0;
    
    return ();
}