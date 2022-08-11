%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    uint256_lt,
    uint256_eq,
    uint256_mul
)

@view
func array_sum{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(
        arr_len: felt,
        arr: felt*
    ) -> (sum: felt):
    if arr_len == 0:
        return (sum=0)
    end

    let (sum_of_rest) = array_sum(arr_len=arr_len - 1, arr=arr + 1)
    return (sum=[arr] + sum_of_rest)
end

@view
func array_product{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(
        arr_len: felt,
        arr: felt*
    ) -> (product: felt):
    if arr_len == 0:
        return (product=1)
    end

    let (product_of_rest) = array_product(arr_len=arr_len - 1, arr=arr + 1)
    return (product=[arr] * product_of_rest)
end

@view
func uint256_array_sum{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(
        arr_len: felt,
        arr: Uint256*
    ) -> (sum: Uint256):
    if arr_len == 0:
        return (sum=Uint256(0,0))
    end

    let (sum_of_rest) = uint256_array_sum(arr_len=arr_len - 1, arr=arr + 1)
    let (sum, _) = uint256_add([arr], sum_of_rest)
    return (sum=sum)
end

@view
func uint256_array_product{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
    }(
        arr_len: felt,
        arr: Uint256*
    ) -> (product: Uint256):
    if arr_len == 0:
        return (product=Uint256(1,0))
    end

    let (product_of_rest) = uint256_array_product(arr_len=arr_len - 1, arr=arr + 1)
    let (product, _) = uint256_mul([arr], product_of_rest)
    return (product=product)
end