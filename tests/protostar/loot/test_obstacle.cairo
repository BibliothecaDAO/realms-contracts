%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from contracts.loot.constants.obstacle import ObstacleConstants, ObstacleUtils

@external
func test_obstacle_rank{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (demonic_alter_rank) = ObstacleUtils.get_rank_from_id(ObstacleConstants.ObstacleIds.DemonicAlter);
    assert demonic_alter_rank = ObstacleConstants.ObstacleRank.DemonicAlter;

    let (swinging_logs_rank) = ObstacleUtils.get_rank_from_id(ObstacleConstants.ObstacleIds.SwingingLogs);
    assert swinging_logs_rank = ObstacleConstants.ObstacleRank.SwingingLogs;

    let (hidden_arrows_rank) = ObstacleUtils.get_rank_from_id(ObstacleConstants.ObstacleIds.HiddenArrow);
    assert hidden_arrows_rank = ObstacleConstants.ObstacleRank.HiddenArrow;

    return ();
}

@external
func test_obstacle_type{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let (demonic_alter_type) = ObstacleUtils.get_type_from_id(ObstacleConstants.ObstacleIds.DemonicAlter);
    assert demonic_alter_type = ObstacleConstants.ObstacleType.DemonicAlter;

    let (swinging_logs_type) = ObstacleUtils.get_type_from_id(ObstacleConstants.ObstacleIds.SwingingLogs);
    assert swinging_logs_type = ObstacleConstants.ObstacleType.SwingingLogs;

    let (hidden_arrows_type) = ObstacleUtils.get_type_from_id(ObstacleConstants.ObstacleIds.HiddenArrow);
    assert hidden_arrows_type = ObstacleConstants.ObstacleType.HiddenArrow;

    return ();
}