%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.settling_game.modules.food.library import Food

from contracts.settling_game.utils.constants import FARM_LENGTH

const UPDATE_TIME = 2000
const BLOCK_TIMESTAMP = 3000

@external
func test_current_relic_holder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (total_farms, remainding_crops) = Food.calculate_harvest(UPDATE_TIME, BLOCK_TIMESTAMP)

    assert total_farms = FARM_LENGTH / 10

    return ()
end
