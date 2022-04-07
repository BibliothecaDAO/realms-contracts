%lang starknet

from starkware.cairo.common.math import unsigned_div_rem

# Convenience function that converts a felt into (row,col)
# Row, col are 0-indexed
func unpack_position{syscall_ptr : felt*, range_check_ptr}(
    grid_dimension : felt, position : felt
) -> (row : felt, col : felt):
    # Divide position by grid dimension and get remainder
    # Ex. position 7, dim 4 is 7 / 4, returns quotient 1, remainder 3
    let (row, col) = unsigned_div_rem(position, grid_dimension)

    return (row=row, col=col)
end

# Convenience function to convert a 0-indexed (row,col) into a single felt
func pack_position{syscall_ptr : felt*, range_check_ptr}(
    grid_dimension : felt, row : felt, col : felt
) -> (position : felt):
    # Multiply row by grid dimension, then add remainder
    tempvar multiple = row * grid_dimension
    return (position=multiple + col)
end
