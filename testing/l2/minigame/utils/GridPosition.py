# Grid contract tests need to pack/unpack x,y into single felt

def unpack_position(grid_dimension, position):
    div = position / grid_dimension
    rem = position % grid_dimension
    return (div,rem)

def pack_position(grid_dimension, row, col):
    return (grid_dimension * row + col)