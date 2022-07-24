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

from contracts.settling_game.utils.constants import (
    FARM_LENGTH,
    MAX_HARVESTS,
    HARVEST_LENGTH,
    STORE_HOUSE_SIZE,
)
from contracts.settling_game.utils.game_structs import (
    RealmData,
    RealmBuildingsIds,
    HarvestType,
    FoodBuildings,
)
from contracts.settling_game.utils.constants import SHIFT_41
from contracts.settling_game.utils.general import unpack_data

namespace Food:
    # @notice Calculates how many available farms to harvest
    # max of 3 full harvests accure
    # if more farms than MAX, return MAX and decayed farms. How will loose these harvests.
    func calculate_harvest{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(update_time : felt, block_timestamp : felt) -> (
        total_farms : felt, total_remaining : felt, decayed_farms : felt
    ):
        alloc_locals

        let time_since_update = block_timestamp - update_time

        # TODO add max days can accure
        let (total_farms, remainding_crops) = unsigned_div_rem(time_since_update, HARVEST_LENGTH)

        let (le_max_farms) = is_le(total_farms, MAX_HARVESTS + 1)

        if le_max_farms == TRUE:
            return (total_farms, remainding_crops, 0)
        end

        return (MAX_HARVESTS, remainding_crops, total_farms - MAX_HARVESTS)
    end

    # @notice Calculates base food in the storehouse
    func calculate_food_in_store_house{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(current_food_supply : felt, block_timestamp : felt) -> (current : felt):
        alloc_locals

        let current = current_food_supply - block_timestamp

        let (is_empty) = is_le(current, 0)

        if is_empty == TRUE:
            return (0)
        end

        return (current)
    end

    # @notice This returns the real value of food available by taking into account the population
    func calculate_available_food{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(current_food_supply : felt, population : felt) -> (available_food : felt):
        alloc_locals

        let (true_food_supply, _) = unsigned_div_rem(current_food_supply, population + 1)

        let (is_empty) = is_le(true_food_supply, 0)

        if is_empty == TRUE:
            return (0)
        end

        return (true_food_supply)
    end

    # @notice asserts correct building ids
    func assert_ids{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        food_building_id : felt
    ) -> (success : felt):
        alloc_locals

        # check
        if food_building_id == RealmBuildingsIds.Farm:
            return (TRUE)
        end
        if food_building_id == RealmBuildingsIds.FishingVillage:
            return (TRUE)
        end

        return (FALSE)
    end

    # @notice asserts correct harvest type
    func assert_harvest_type{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        harvest_type : felt
    ) -> (success : felt):
        alloc_locals

        # check
        if harvest_type == HarvestType.Export:
            return (TRUE)
        end
        if harvest_type == HarvestType.Store:
            return (TRUE)
        end

        return (FALSE)
    end

    # @notice packs buildings
    # @param food_buildings_unpacked: unpacked buildings
    # @return food_buildings_packed: packed buildings
    func pack_food_buildings{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(food_buildings_unpacked : FoodBuildings) -> (food_buildings_packed : felt):
        alloc_locals

        let NumberBuilt = food_buildings_unpacked.NumberBuilt * SHIFT_41._1
        let CollectionsLeft = food_buildings_unpacked.CollectionsLeft * SHIFT_41._2
        let UpdateTime = food_buildings_unpacked.UpdateTime * SHIFT_41._3

        tempvar packed_value = UpdateTime + CollectionsLeft + NumberBuilt

        return (packed_value)
    end

    # @notice unpacks buildings
    # @param packed_food_buildings: packed buildings
    # @return unpacked_food_buildings: unpacked buildings
    func unpack_food_buildings{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(packed_food_buildings : felt) -> (unpacked_food_buildings : FoodBuildings):
        alloc_locals

        let (NumberBuilt) = unpack_data(packed_food_buildings, 0, 2199023255551)
        let (CollectionsLeft) = unpack_data(packed_food_buildings, 41, 2199023255551)
        let (UpdateTime) = unpack_data(packed_food_buildings, 82, 2199023255551)

        return (
            unpacked_food_buildings=FoodBuildings(
            NumberBuilt,
            CollectionsLeft,
            UpdateTime
            ),
        )
    end

    # @notice Computes value of store houses. Store houses take up variable space on the Realm according to STORE_HOUSE_SIZE
    # @param token_id: Staked Realm id (S_Realm)
    # @return full_store_houses: A full decimal value of storehouses

    func get_full_store_houses{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(food_in_store : felt) -> (full_store_houses : felt):
        alloc_locals

        let (total_store_house, _) = unsigned_div_rem(food_in_store, STORE_HOUSE_SIZE)

        let (zero_store_houses) = is_le(total_store_house, 0)

        if zero_store_houses == TRUE:
            return (0)
        end

        return (total_store_house)
    end
end
