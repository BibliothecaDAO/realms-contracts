# -----------------------------------
#   CALCULATOR LOGIC
#   This modules focus is to calculate the values of the internal
#   multipliers so other modules can use them. The aim is to have this
#   as the core calculator controller that contains no state.
#   It is pure math.
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, sqrt
from starkware.cairo.common.math_cmp import is_nn_le, is_nn, is_le
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.pow import pow

const SECONDS_PER_KM = 1600

namespace Coordinates:
    func calculate_distance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        x_1 : felt, y_1 : felt, x_2 : felt, y_2 : felt
    ) -> (distance : felt):
        alloc_locals
        # d = √((x2-x1)2 + (y2-y1)2)

        let (x) = pow(x_2 - x_1, 2)
        let (y) = pow(y_2 - y_1, 2)

        let (distance) = sqrt(x + y)

        return (distance)
    end

    func calculate_time{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        distance : felt
    ) -> (time : felt):
        alloc_locals

        return (distance * SECONDS_PER_KM)
    end
end
