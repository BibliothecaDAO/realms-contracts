%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_eq
)

from contracts.utils.constants import FALSE, TRUE

@view
func find_value{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        arr_index: felt,
        arr_len: felt,
        arr: felt*,
        value: felt
        ) -> (index: felt):
    if arr_index == arr_len:
        with_attr error_message("Find Value: Value not found"):
            assert 1 = 0
        end
    end      
    if arr[arr_index] == value:
        return (index=arr_index)
    end

    find_value(arr_index + 1, arr_len, arr, value)

    return (index=arr_index)
end

@view
func find_uint256_value{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        arr_index: felt,
        arr_len: felt,
        arr: Uint256*,
        value: Uint256
        ) -> (index: felt):
    if arr_index == arr_len:
        with_attr error_message("Find Value: Value not found"):
            assert 1 = 0
        end
    end      
    let (check) = uint256_eq(arr[arr_index], value)
    if check == TRUE:
        return (index=arr_index)
    end

    find_uint256_value(arr_index + 1, arr_len, arr, value)
    
    return (index=arr_index)
end