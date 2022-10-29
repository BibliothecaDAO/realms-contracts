%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from contracts.loot.constants.beast import BeastConstants, BeastUtils

@external
func test_beast_rank{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (phoenix_rank) = BeastUtils.get_rank_from_id(BeastConstants.BeastIds.Phoenix);
    assert phoenix_rank = BeastConstants.BeastRank.Phoenix;

    let (orc_rank) = BeastUtils.get_rank_from_id(BeastConstants.BeastIds.Orc);
    assert orc_rank = BeastConstants.BeastRank.Orc;

    let (rat_rank) = BeastUtils.get_rank_from_id(BeastConstants.BeastIds.Rat);
    assert rat_rank = BeastConstants.BeastRank.Rat;

    return ();
}

@external
func test_beast_type{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (phoenix_type) = BeastUtils.get_type_from_id(BeastConstants.BeastIds.Phoenix);
    assert phoenix_type = BeastConstants.BeastType.Phoenix;

    let (orc_type) = BeastUtils.get_type_from_id(BeastConstants.BeastIds.Orc);
    assert orc_type = BeastConstants.BeastType.Orc;

    let (rat_type) = BeastUtils.get_type_from_id(BeastConstants.BeastIds.Rat);
    assert rat_type = BeastConstants.BeastType.Rat;

    return ();
}