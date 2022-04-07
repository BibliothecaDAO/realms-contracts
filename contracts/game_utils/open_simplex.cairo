# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.bitwise import bitwise_and, bitwise_operations, bitwise_or, bitwise_xor
from starkware.cairo.common.math import signed_div_rem
from starkware.cairo.common.math_cmp import (
    is_not_zero,
    is_nn,
    is_le,
    is_nn_le,
    is_in_range,
    is_le_felt,
)

const STRETCH_CONSTANT_2D = -211324865405187
const SQUISH_CONSTANT_2D = 366025403784439
const NORM_CONSTANT_2D = 47

const RANGE_CHECK_BOUND = 2 ** 127
const SCALE_FP = 10 ** 15

# Define a storage variable.
@storage_var
func permut(i : felt) -> (res : felt):
end

@storage_var
func permut_length() -> (res : felt):
end

@storage_var
func gradient_2d(i : felt) -> (res : (felt, felt)):
end

@storage_var
func gradient_2d_length() -> (res : felt):
end

@storage_var
func owner() -> (res : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    permut_length.write(256)
    gradient_2d_length.write(8)
    gradient_2d.write(0, (5, 2))
    gradient_2d.write(1, (2, 5))
    gradient_2d.write(2, (-5, 2))
    gradient_2d.write(3, (-2, 5))
    gradient_2d.write(4, (5, -2))
    gradient_2d.write(5, (2, -5))
    gradient_2d.write(6, (-5, -2))
    gradient_2d.write(7, (-2, -5))
    return ()
end

@view
func get_perm{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(index : felt) -> (
    res : felt
):
    let (res) = permut.read(index)
    return (res)
end

@external
func init{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _permut_len : felt, _permut : felt*
):
    recurse_add_permut(_permut_len, _permut, 0)
    return ()
end

@external
func noise_2d{
    bitwise_ptr : BitwiseBuiltin*, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(x : felt, y : felt) -> (res : felt):
    alloc_locals
    let d_x = (x * SCALE_FP)
    let d_y = (y * SCALE_FP)

    let d_stretch_offset = STRETCH_CONSTANT_2D * (x + y)
    let d_xs = d_stretch_offset + d_x
    let d_ys = d_stretch_offset + d_y

    let (xsb, _) = signed_div_rem(d_xs, SCALE_FP, RANGE_CHECK_BOUND)
    let (ysb, _) = signed_div_rem(d_ys, SCALE_FP, RANGE_CHECK_BOUND)

    let d_squish_offset = STRETCH_CONSTANT_2D * (xsb + ysb)
    let d_xb = d_squish_offset + (d_xs * SCALE_FP)
    let d_yb = d_squish_offset + (d_ys * SCALE_FP)

    let d_xins = d_xs - (xsb * SCALE_FP)
    let d_yins = d_ys - (ysb * SCALE_FP)

    let d_in_sum = d_xins + d_yins

    let d_dx0 = d_x - d_xb
    let d_dy0 = d_y - d_yb

    let d_value = 0

    let d_dx1 = d_dx0 - (1 * SCALE_FP) - SQUISH_CONSTANT_2D
    let d_dy1 = d_dy0 - (0 * SCALE_FP) - SQUISH_CONSTANT_2D
    let (d_dx1pow2, _) = signed_div_rem(d_dx1 * d_dx1, SCALE_FP, RANGE_CHECK_BOUND)
    let (d_dy1pow2, _) = signed_div_rem(d_dy1 * d_dy1, SCALE_FP, RANGE_CHECK_BOUND)
    let d_attn1 = (2 * SCALE_FP) - d_dx1pow2 - d_dy1pow2
    let (d_attn1gt0) = is_not_zero(d_attn1)
    if d_attn1gt0 == 1:
        let (local d_attn1pow2, _) = signed_div_rem(d_attn1 * d_attn1, SCALE_FP, RANGE_CHECK_BOUND)
        let (local d_attn1pow2pow2, _) = signed_div_rem(
            d_attn1pow2 * d_attn1pow2, SCALE_FP, RANGE_CHECK_BOUND
        )
        let (local d_extrapolated) = d_extrapolate(xsb + 1, ysb + 0, d_dx1, d_dy1)
        let (local d_attn1pow2pow2mulextrapolate, _) = signed_div_rem(
            d_attn1pow2pow2 * d_extrapolated, SCALE_FP, RANGE_CHECK_BOUND
        )
        d_value = d_value + d_attn1pow2pow2mulextrapolate
        tempvar range_check_ptr = range_check_ptr
        tempvar bitwise_ptr = bitwise_ptr
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        tempvar range_check_ptr = range_check_ptr
        tempvar bitwise_ptr = bitwise_ptr
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    let d_dx2 = d_dx0 - (0 * SCALE_FP) - SQUISH_CONSTANT_2D
    let d_dy2 = d_dy0 - (1 * SCALE_FP) - SQUISH_CONSTANT_2D
    let (d_dx2pow2, _) = signed_div_rem(d_dx2 * d_dx2, SCALE_FP, RANGE_CHECK_BOUND)
    let (d_dy2pow2, _) = signed_div_rem(d_dy2 * d_dy2, SCALE_FP, RANGE_CHECK_BOUND)
    let d_attn2 = (2 * SCALE_FP) - d_dx2pow2 - d_dy2pow2
    let (d_attn2gt0) = is_not_zero(d_attn1)
    if d_attn2gt0 == 1:
        let (d_attn2pow2, _) = signed_div_rem(d_attn2 * d_attn2, SCALE_FP, RANGE_CHECK_BOUND)
        let (d_attn2pow2pow2, _) = signed_div_rem(
            d_attn2pow2 * d_attn2pow2, SCALE_FP, RANGE_CHECK_BOUND
        )
        let (d_extrapolated) = d_extrapolate(xsb + 0, ysb + 1, d_dx2, d_dy2)
        let (d_attn2pow2pow2mulextrapolate, _) = signed_div_rem(
            d_attn2pow2pow2 * d_extrapolated, SCALE_FP, RANGE_CHECK_BOUND
        )
        d_value = d_value + d_attn2pow2pow2mulextrapolate
        tempvar range_check_ptr = range_check_ptr
        tempvar bitwise_ptr = bitwise_ptr
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        tempvar range_check_ptr = range_check_ptr
        tempvar bitwise_ptr = bitwise_ptr
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end
    tempvar bitwise_ptr = bitwise_ptr
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr

    tempvar xsv_ext = 0
    tempvar ysv_ext = 0
    tempvar d_dx_ext = 0
    tempvar d_dy_ext = 0
    let (d_in_sumltscale) = is_le_felt(d_in_sum, SCALE_FP)
    if d_in_sumltscale == 1:
        let d_zins = (1 * SCALE_FP) - d_in_sum
        let (b_is_le_xinszins) = is_le(d_xins + 1, d_zins)
        let (b_is_le_yinszins) = is_le(d_yins + 1, d_zins)
        let (b_and_inssum) = is_not_zero(b_is_le_xinszins + b_is_le_yinszins)
        let (d_yltxins) = is_le(d_yins + 1, d_xins)
        if b_and_inssum == 1:
            if d_yltxins == 1:
                xsv_ext = xsb + 1
                ysv_ext = ysb - 1
                d_dx_ext = d_dx0 - (1 * SCALE_FP)
                d_dy_ext = d_dy0 + (1 * SCALE_FP)
            else:
                xsv_ext = xsb - 1
                ysv_ext = ysb + 1
                d_dx_ext = d_dx0 + (1 * SCALE_FP)
                d_dy_ext = d_dy0 - (1 * SCALE_FP)
            end
        else:
            xsv_ext = xsb + 1
            ysv_ext = ysb + 1
            d_dx_ext = d_dx0 - (1 * SCALE_FP) - (2 * SQUISH_CONSTANT_2D)
            d_dy_ext = d_dy0 - (1 * SCALE_FP) - (2 * SQUISH_CONSTANT_2D)
        end
        tempvar range_check_ptr = range_check_ptr
    else:
        let d_zins = (2 * SCALE_FP) - d_in_sum
        let (b_is_le_xinszins) = is_le(d_xins + 1, d_zins)
        let (b_is_le_yinszins) = is_le(d_yins + 1, d_zins)
        let (b_and_inssum) = is_not_zero(b_is_le_xinszins + b_is_le_yinszins)
        let (d_yltxins) = is_le(d_yins + 1, d_xins)
        if b_and_inssum == 1:
            if d_yltxins == 1:
                xsv_ext = xsb + 2
                ysv_ext = ysb + 0
                d_dx_ext = d_dx0 - (2 * SCALE_FP) - (2 * SQUISH_CONSTANT_2D)
                d_dy_ext = d_dy0 + (0 * SCALE_FP) - (2 * SQUISH_CONSTANT_2D)
            else:
                xsv_ext = xsb + 0
                ysv_ext = ysb + 2
                d_dx_ext = d_dx0 + (0 * SCALE_FP) - (2 * SQUISH_CONSTANT_2D)
                d_dy_ext = d_dy0 - (2 * SCALE_FP) - (2 * SQUISH_CONSTANT_2D)
            end
        else:
            d_dx_ext = d_dx0
            d_dy_ext = d_dy0
            xsv_ext = xsb
            ysv_ext = ysb
        end
        xsb = xsb + 1
        ysb = ysb + 1
        d_dx0 = d_dx0 - (1 * SCALE_FP) - (2 * SQUISH_CONSTANT_2D)
        d_dy0 = d_dy0 - (1 * SCALE_FP) - (2 * SQUISH_CONSTANT_2D)
        tempvar range_check_ptr = range_check_ptr
    end

    let (d_dx0pow2, _) = signed_div_rem(d_dx0 * d_dx0, SCALE_FP, RANGE_CHECK_BOUND)
    let (d_dy0pow2, _) = signed_div_rem(d_dy0 * d_dy0, SCALE_FP, RANGE_CHECK_BOUND)
    let d_attn0 = (2 * SCALE_FP) - d_dx0pow2 - d_dy0pow2
    let (d_attn0gt0) = is_not_zero(d_attn0)
    if d_attn0gt0 == 1:
        let (d_attn0pow2, _) = signed_div_rem(d_attn0 * d_attn0, SCALE_FP, RANGE_CHECK_BOUND)
        let (d_extrapolated) = d_extrapolate(xsb, ysb, d_dx0, d_dy0)
        let (d_attn0pow2mulextrapolate, _) = signed_div_rem(
            d_attn0pow2 * d_extrapolated, SCALE_FP, RANGE_CHECK_BOUND
        )
        d_value = d_value + d_attn0pow2mulextrapolate
        tempvar range_check_ptr = range_check_ptr
        tempvar bitwise_ptr = bitwise_ptr
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        tempvar range_check_ptr = range_check_ptr
        tempvar bitwise_ptr = bitwise_ptr
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    let (d_dx_extpow2, _) = signed_div_rem(d_dx_ext * d_dx_ext, SCALE_FP, RANGE_CHECK_BOUND)
    let (d_dy_extpow2, _) = signed_div_rem(d_dy_ext * d_dy_ext, SCALE_FP, RANGE_CHECK_BOUND)
    let d_attn_ext = (2 * SCALE_FP) - d_dx_extpow2 - d_dy_extpow2
    let (d_attn_extgt0) = is_not_zero(d_attn_ext)
    if d_attn_extgt0 == 1:
        let (d_attn_extpow2, _) = signed_div_rem(
            d_attn_ext * d_attn_ext, SCALE_FP, RANGE_CHECK_BOUND
        )
        let (d_extrapolated) = d_extrapolate(xsb, ysb, d_dx_ext, d_dy_ext)
        let (d_attn_extpow2mulextrapolate, _) = signed_div_rem(
            d_attn_extpow2 * d_extrapolated, SCALE_FP, RANGE_CHECK_BOUND
        )
        d_value = d_value + d_attn_extpow2mulextrapolate
        tempvar range_check_ptr = range_check_ptr
        tempvar bitwise_ptr = bitwise_ptr
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        tempvar range_check_ptr = range_check_ptr
        tempvar bitwise_ptr = bitwise_ptr
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    let (result, _) = signed_div_rem(d_value, NORM_CONSTANT_2D, RANGE_CHECK_BOUND)
    return (result)
end

func d_extrapolate{
    bitwise_ptr : BitwiseBuiltin*, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(xsb : felt, ysb : felt, d_dx : felt, d_dy : felt) -> (res : felt):
    alloc_locals
    let (local and1) = bitwise_and(xsb, 0xFF)
    let (local permut1) = permut.read(and1 + ysb)
    let (local and2) = bitwise_and(permut1, 0xFF)
    let (local permut2) = permut.read(and2)
    let (local index) = bitwise_and(permut2, 0x0E)

    let (local grad2d) = gradient_2d.read(index)
    return (d_dx * grad2d[0] + d_dy * grad2d[1])
end

func recurse_add_permut{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _permut_len : felt, _permut : felt*, index : felt
):
    let (length) = permut_length.read()
    if index + 1 == length:
        return ()
    end
    permut.write(index, _permut[index])
    return recurse_add_permut(_permut_len, _permut, index + 1)
end

func recurse_add_gradient_2d{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _grad_x_len : felt, _grad_x : felt*, _grad_y_len : felt, _grad_y : felt*, index : felt
):
    alloc_locals
    let (local length) = gradient_2d_length.read()
    if index + 1 == length:
        return ()
    end
    gradient_2d.write(index, (_grad_x[index], _grad_y[index]))
    return recurse_add_gradient_2d(_grad_x_len, _grad_x, _grad_y_len, _grad_y, index + 1)
end
