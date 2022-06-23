# CALCULATOR LIBRARY
#   Helper functions for staking.
#
#
# MIT License

%lang starknet

from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256

namespace CALCULATOR:
    func get_happiness{syscall_ptr : felt*, range_check_ptr}(population : felt, food : felt) -> (
        happiness : felt
    ):
        alloc_locals
        # FETCH VALUES
        let (population_calculation, _) = unsigned_div_rem(population, 10)
        let food_calc = food - population_calculation

        # SANITY FALL BACK CHECK INCASE OF OVERFLOW....
        let (assert_check) = is_nn(100 + food_calc)
        if assert_check == 0:
            return (50)
        end

        let happiness = 100 + food_calc

        # if happiness less than 50, cap it
        let (is_lessthan_threshold) = is_le(happiness, 50)
        if is_lessthan_threshold == 1:
            return (50)
        end

        # if happiness greater than 150 cap it
        let (is_greaterthan_threshold) = is_le(150, happiness)
        if is_greaterthan_threshold == 1:
            return (150)
        end
        return (happiness)
    end
end
