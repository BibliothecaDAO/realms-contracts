%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from contracts.settling_game.utils.general import unpack_data

@view
func test_unpack_data{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        data : felt, index : felt, mask_size : felt) -> (score : felt):
    let (score) = unpack_data(data, index, mask_size)
    return (score)
end
