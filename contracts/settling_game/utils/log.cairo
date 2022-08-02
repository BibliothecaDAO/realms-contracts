%builtins output range_check

from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.math import assert_250_bit
from starkware.cairo.common.math_cmp import is_nn

# Get log base(target) -> say base = 2 and target = 32 then log2(32) = 5. This will give the floor for any decimal value
func findLog{output_ptr : felt*, range_check_ptr : felt}(base : felt, target : felt) -> (
    exp : felt
):
    if target == 1:
        return (0)
    end
    return findPowLargerWithBetterScaling(base, 1, 2, target)
end

# Find the next value = base ^ exp such that value is not greater than target
func findPowLargerWithBetterScaling{output_ptr : felt*, range_check_ptr : felt}(
    base : felt, exp : felt, currVal : felt, target : felt
) -> (exp : felt):
    alloc_locals

    # This handles exact match for base ^ exponent + 1 = target
    let (isNotEqual) = is_not_zero(currVal * base - target)
    if isNotEqual == 0:
        return (exp + 1)
    end

    # This checks for the flooring scenario, if base ^ exponent + 1 > target then get the current exponent
    let (isNn1) = is_nn(currVal * base - target)
    if isNn1 == 1:
        return (exp)
    end

    # Getting the next power of the base on this iteration, this only works for numbers under 2 ^ 125 otherwise we will go over 2^250
    local newVal = currVal * currVal
    assert_250_bit(newVal)

    # This handles flooring scenario
    let (isLe) = is_le(newVal, target)
    if isLe == 1:
        return findPowLargerWithBetterScaling(base, exp + exp, newVal, target)
    else:
        return findPowLargerWithBetterScaling(base, exp + 1, currVal * 2, target)
    end
end
