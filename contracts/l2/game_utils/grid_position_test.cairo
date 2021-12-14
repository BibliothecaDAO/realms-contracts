# Contract that just tests the utility contract
# Instantiated only in tests
# TODO: Remove/refactor if there's a better way

%lang starknet
%builtins pedersen range_check

from contracts.l2.game_utils.grid_position import (unpack_position, pack_position)

@external
func test_unpack_position{
        syscall_ptr : felt*,
        range_check_ptr
    }(
        grid_dimension : felt,
        position : felt
    ) -> (
        row : felt,
        col : felt
    ):
    return unpack_position( grid_dimension, position )
end

# Convenience function to convert a 0-indexed (row,col) into a single felt
@external
func test_pack_position{
        syscall_ptr : felt*,
        range_check_ptr
    }( 
        grid_dimension : felt,
        row : felt,
        col : felt
    ) -> (
        position : felt
    ):
    return pack_position( grid_dimension, row, col )
end