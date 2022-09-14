// MOVEMENT MODULE ###
//                   #
//   .oooO  Oooo.    #
//   ( Y )  ( Y )    #
//    \ (    ) /     #
//     \_)  (_/      #
//                   #
//####################

// - Checks movement logic

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_nn_le, is_in_range

from contracts.game_utils.grid_position import unpack_position

// Checks movement logic
// Returns 1 if the movement is allowed, 0 if not
// Reverts if movement logic not allowed
@external
func assert_move{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    grid_dimension: felt, player_position: felt, target_position: felt
) -> (res: felt) {
    alloc_locals;

    let (curr_row, curr_col) = unpack_position(grid_dimension, player_position);
    let (target_row, target_col) = unpack_position(grid_dimension, target_position);

    // Ensure target is within grid boundary
    let within_row = is_nn_le(target_row, grid_dimension - 1);
    let within_col = is_nn_le(target_col, grid_dimension - 1);
    assert within_row = 1;
    assert within_col = 1;

    // TODO: Ensure not moving to same position
    // If there is logic that uses the number of moves
    // then moving to same position might be cheating

    // Current rule is player can only move 1 step (left,right,up,down)
    if (curr_row == target_row) {
        // Rows are the same, so col must be 1 step away
        let in_range_col = is_in_range(target_col, curr_col - 1, curr_col + 1);
        assert in_range_col = 1;
        return (res=1);
    } else {
        if (curr_col == target_col) {
            // Cols are same, so row must be 1 step away
            let in_range_row = is_in_range(target_row, curr_row - 1, curr_row + 1);
            assert in_range_row = 1;
            return (res=1);
        }
    }

    // Force error
    assert 1 = 0;
    return (res=0);
}
