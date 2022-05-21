%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div
from contracts.settling_game.utils.game_structs import BuildingsFood, BuildingsPopulation, BuildingsCulture
from contracts.settling_game.library.library_calculator import CALCULATOR
from starkware.cairo.common.pow import pow

# @external
# func test_resources{syscall_ptr : felt*, range_check_ptr}():
#     alloc_locals

#     let lords_decimals = 25 * 10 ** 18
    
#     # let lords_available = Uint256(lords_decimals, 0)

#     %{ print(ids.lords_decimals) %}
#     return ()
# end

@external
func test_sub{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (new_reserves) = uint256_sub(Uint256(20,0), Uint256(10,0))
    
    # let lords_available = Uint256(lords_decimals, 0)

    %{ print(ids.new_reserves.low) %}
    return ()
end