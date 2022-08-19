# -----------------------------------
# ____Food Library
#   Food
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le

from contracts.settling_game.utils.constants import (
    FARM_LENGTH,
    MAX_HARVESTS,
    HARVEST_LENGTH,
    STORE_HOUSE_SIZE,
    SHIFT_41
)
from contracts.settling_game.utils.game_structs import (
    RealmData,
    RealmBuildingsIds,
    HarvestType,
    FoodBuildings,
    ResourceIds,
)
from contracts.settling_game.utils.general import unpack_data

namespace Food:
    # @notice Calculates how many available farms/fishing villages to harvest
    #   MAX_HARVESTS = max amount you can harvest at once.
    #   if more farms than MAX, return MAX and decayed farms. How will loose these harvests.
    func calculate_harvest{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        time_since_update : felt
    ) -> (total_harvests : felt, total_remaining : felt, decayed_farms : felt):
        alloc_locals

        let (total_harvests, remaining_crops) = unsigned_div_rem(time_since_update, HARVEST_LENGTH)

        let (le_max_harvests) = is_le(total_harvests, MAX_HARVESTS + 1)

        if le_max_harvests == TRUE:
            return (total_harvests, remaining_crops, 0)
        end

        # this could be done better... This just stops returning when no farms have been built
        let (no_harvests) = is_le(1000000, total_harvests)

        if no_harvests == TRUE:
            return (0, 0, 0)
        end

        return (MAX_HARVESTS, remaining_crops, total_harvests - MAX_HARVESTS)
    end

    # @notice Calculates base food in the storehouse
    func calculate_food_in_store_house{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(current_food_supply : felt) -> (current : felt):
        alloc_locals

        let (is_empty) = is_le(current_food_supply, 0)

        if is_empty == TRUE:
            return (0)
        end

        return (current_food_supply)
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
    ):
        alloc_locals

        # check
        if food_building_id == RealmBuildingsIds.Farm:
            return ()
        end
        if food_building_id == RealmBuildingsIds.FishingVillage:
            return ()
        end

        with_attr error_message("FOOD: Incorrect Building ID"):
            assert 1 = 0
        end

        return ()
    end

    # @notice asserts correct harvest type
    func assert_harvest_type{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        harvest_type : felt
    ):
        alloc_locals

        # check
        if harvest_type == HarvestType.Export:
            return ()
        end
        if harvest_type == HarvestType.Store:
            return ()
        end

        with_attr error_message("FOOD: Incorrect Harvest type"):
            assert 1 = 0
        end

        return ()
    end

    # @notice asserts correct harvest type
    func assert_food_type{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        harvest_type : felt
    ):
        alloc_locals

        # check
        if harvest_type == ResourceIds.fish:
            return ()
        end
        if harvest_type == ResourceIds.wheat:
            return ()
        end

        with_attr error_message("FOOD: Incorrect Food type"):
            assert 1 = 0
        end

        return ()
    end

    # @notice packs buildings
    # @param food_buildings_unpacked: unpacked buildings
    # @return food_buildings_packed: packed buildings
    func pack_food_buildings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        food_buildings_unpacked : FoodBuildings
    ) -> (food_buildings_packed : felt):
        alloc_locals

        let number_built = food_buildings_unpacked.number_built * SHIFT_41._1
        let collections_left = food_buildings_unpacked.collections_left * SHIFT_41._2
        let update_time = food_buildings_unpacked.update_time * SHIFT_41._3

        tempvar packed_value = update_time + collections_left + number_built

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

        let (number_built) = unpack_data(packed_food_buildings, 0, 2199023255551)
        let (collections_left) = unpack_data(packed_food_buildings, 41, 2199023255551)
        let (update_time) = unpack_data(packed_food_buildings, 82, 2199023255551)

        return (
            unpacked_food_buildings=FoodBuildings(
            number_built,
            collections_left,
            update_time
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
