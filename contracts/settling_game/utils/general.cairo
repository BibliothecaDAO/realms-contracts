%lang starknet

from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.pow import pow
# Computes the unique hash of a list of felts.
func list_to_hash{pedersen_ptr : HashBuiltin*, range_check_ptr}(list : felt*, list_len : felt) -> (
        hash : felt):
    let (list_hash : HashState*) = hash_init()
    let (list_hash : HashState*) = hash_update{hash_ptr=pedersen_ptr}(list_hash, list, list_len)
    return (list_hash.current_hash)
end

# Generic mapping from one range to another.
func scale{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(
        val_in : felt, in_low : felt, in_high : felt, out_low : felt, out_high : felt) -> (
        val_out : felt):
    # val_out = ((val_in - in_low) / (in_high - in_low))
    #           * (out_high - out_low) + out_low
    let a = (val_in - in_low) * (out_high - out_low)
    let b = in_high - in_low
    let (c, _) = unsigned_div_rem(a, b)
    let val_out = c + out_low
    return (val_out)
end

# upack data
# parse data, index, mask_size
func unpack_data{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(data : felt, index : felt, mask_size : felt) -> (score : felt):
    alloc_locals

    local syscall_ptr : felt* = syscall_ptr
    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
    # 1. Create a 8-bit mask at and to the left of the index
    # E.g., 000111100 = 2**2 + 2**3 + 2**4 + 2**5
    # E.g.,  2**(i) + 2**(i+1) + 2**(i+2) + 2**(i+3) = (2**i)(15)
    let (power) = pow(2, index)
    # 1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256 + 512 + 1024 + 2048 = 15
    let mask = mask_size * power

    # 2. Apply mask using bitwise operation: mask AND data.
    let (masked) = bitwise_and(mask, data)

    # 3. Shift element right by dividing by the order of the mask.
    let (result, _) = unsigned_div_rem(masked, power)

    return (score=result)
end

# func pack_realm_building_data{
#         syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
#         range_check_ptr}(data : felt, index : felt, updated_value : felt) -> (value : felt):
#     alloc_locals

#     let (local num_1) = unpack_data(data, 0, 255)
#     let (local num_2) = unpack_data(data, 8, 255)
#     let (local num_3) = unpack_data(data, 16, 255)
#     let (local num_4) = unpack_data(data, 24, 255)
#     let (local num_5) = unpack_data(data, 32, 255)
#     let (local num_6) = unpack_data(data, 40, 255)
#     let (local num_7) = unpack_data(data, 48, 255)
#     let (local num_8) = unpack_data(data, 56, 255)

#     let t1 = 0
    
#     # Shifting via multiplication
#     if index == 0:
#         # tempvar s = updated_value
#         tempvar t1 = (num_1 + 1) * SHIFT_5_1
#     else:
#         tempvar t1 = num_1 * SHIFT_5_1
#     end

#     if index == 8:
#         tempvar s = updated_value
#         # tempvar t2 = num_2 + s * SHIFT_5_2
#     else:
#         # tempvar t2 = num_2 * SHIFT_5_2
#     end

#     if index == 16:
#         tempvar t3 = (num_3 + updated_value) * SHIFT_5_3
#     else:
#         tempvar t3 = num_3 * SHIFT_5_3
#     end

#     if index == 24:
#         tempvar t4 = (num_4 + updated_value) * SHIFT_5_4
#     else:
#         tempvar t4 = num_4 * SHIFT_5_4
#     end

#     if index == 32:
#         tempvar t5 = (num_5 + updated_value) * SHIFT_5_5
#     else:
#         tempvar t5 = num_5 * SHIFT_5_5
#     end

#     if index == 40:
#         tempvar t6 = (num_6 + updated_value) * SHIFT_5_6
#     else:
#         tempvar t6 = num_6 * SHIFT_5_6
#     end

#     if index == 48:
#         tempvar t7 = (num_7 + updated_value) * SHIFT_5_7
#     else:
#         tempvar t7 = num_7 * SHIFT_5_7
#     end 
                            
#     if index == 56:
#         tempvar t8 = (num_8 + updated_value) * SHIFT_5_8
#     else:
#         tempvar t8 = num_8 * SHIFT_5_8
#     end

#     tempvar num =  t1        

#     return (value=num)
# end
