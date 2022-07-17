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
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.cairo.common.math_cmp import is_le

from contracts.settling_game.utils.constants import FARM_LENGTH
from contracts.settling_game.utils.game_structs import RealmData, RealmBuildingsIds

namespace Food:
    # checks can build, maybe move to actual contract rather than lib
    func create{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        number_to_build : felt, food_building_id : felt, realm_data : RealmData
    ) -> (time : felt):
        alloc_locals

        # add +1 so you can build upto the amount
        if food_building_id == RealmBuildingsIds.Farm:
            let (enough_rivers) = is_le(number_to_build, realm_data.rivers + 1)
            with_attr error_message("FOOD: Not enough Rivers"):
                assert_not_zero(enough_rivers)
            end
        else:
            let (enough_harbours) = is_le(number_to_build, realm_data.harbours + 1)
            with_attr error_message("FOOD: Not enough Harbours"):
                assert_not_zero(enough_harbours)
            end
        end

        return (FARM_LENGTH)
    end

    # calculates how many available farms to harvest
    # max of 3 full harvests accure
    # decay rate in time if you harvest later
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
