%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from contracts.loot.beast.library import BeastLib
from contracts.loot.constants.beast import Beast
from tests.protostar.loot.test_structs import (
    TestUtils,
    TEST_DAMAGE_HEALTH_REMAINING,
    TEST_DAMAGE_OVERKILL,
)

@external
func test_pack{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let beast = Beast(1, 100, 1, 1, 1, 1, 0);

    let (packed_beast) = BeastLib.pack(beast);

    let (beast: Beast) = BeastLib.unpack(packed_beast);

    assert beast.Id = 1;
    assert beast.Health = 100;
    assert beast.Type = 1;
    assert beast.Rank = 1;
    assert beast.Prefix_1 = 1;
    assert beast.Prefix_2 = 1;
    assert beast.Greatness = 0;

    return ();
}

@external
func test_cast{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (beast) = TestUtils.create_beast(1, 0);

    let (packed_beast) = BeastLib.pack(beast);

    let (beast: Beast) = BeastLib.unpack(packed_beast);

    let (c) = BeastLib.cast_state(1, 50, beast);

    %{ print('Health', ids.c.Health) %}

    return ();
}

@external
func test_deduct_health{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}() {
    alloc_locals;
    
    let (state) = TestUtils.create_beast(1, 0);

    let (packed_beast) = BeastLib.pack(state);

    let (beast: Beast) = BeastLib.unpack(packed_beast);

    let (c) = BeastLib.deduct_health(TEST_DAMAGE_HEALTH_REMAINING, beast);

    assert c.Health = state.Health - TEST_DAMAGE_HEALTH_REMAINING;

    let (c) = BeastLib.deduct_health(TEST_DAMAGE_OVERKILL, beast);

    assert c.Health = 0;
    
    return ();
}