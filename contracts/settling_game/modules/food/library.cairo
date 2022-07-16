# -----------------------------------
# ____Food Library
#   Food
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem

from contracts.settling_game.utils.constants import FARM_LENGTH

namespace Food:
    func create{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        number_to_build : felt, food_building_id : felt
    ) -> (cost : felt):
        alloc_locals

        # check less rivers available
        # get farm cost * number of farms
        # time stamp
        #
        return ()
    end

    func calculate_harvest{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        update_time : felt, block_timestamp : felt
    ) -> (total_farms : felt, total_remaining : felt):
        alloc_locals

        let time_since_update = block_timestamp - update_time

        let (total_farms, remainding_crops) = unsigned_div_rem(time_since_update, FARM_LENGTH)

        return (total_farms, remainding_crops)
    end

    func calculate_store_house{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256
    ) -> (token_id : Uint256):
        alloc_locals
        return ()
    end

    func calculate_cost{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256
    ) -> (token_id : Uint256):
        alloc_locals
        return ()
    end
end
