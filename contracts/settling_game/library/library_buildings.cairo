# STAKING LIBRARY
#   Helper functions for staking.
#
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.utils.game_structs import RealmBuildings
from starkware.cairo.common.math import unsigned_div_rem
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_ln

const CASTLE_RATE = 10000

namespace BUILDINGS:
    func get_realm_buildable_area{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(square_units : felt, buildings : RealmBuildings):
        # Get buildable units
        return ()
    end

    func return_final_decay_time{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        unit_decay_time : felt, number : felt
    ) -> (time : felt):
        let (block_timestamp) = get_block_timestamp()

        return (block_timestamp + unit_decay_time * number)
    end

    # Gets raw buildings on realm. This is only used for precalulations
    func get_base_building_left{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        time_balance : felt, building_id : felt
    ) -> (buildings : felt):
        alloc_locals

        let (buildings_left, _) = unsigned_div_rem(time_balance, 100)

        return (buildings_left)
    end

    # Gets effective buildings on Realm
    func get_effective_building_left{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(time_balance : felt) -> (buildings : felt):
        alloc_locals

        # TODO: log function
        # let (effective_buildings) = Math64x61_ln(time_balance)

        # divide time left by building decay time
        let (buildings_left) = get_base_building_left(time_balance, 100)

        return (buildings_left)
    end

    # Returns decay rate in bp
    # you must convert to float in order to use
    func get_decay_rate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        buildings_left : felt, decay_slope : felt
    ) -> (decay_rate : felt):
        # divide time left by building decay time
        return (decay_slope * buildings_left)
    end

    # Time balance
    func get_effective_building_time{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(time_balance : felt, decay_rate : felt) -> (current_actual_time : felt):
        # Calculate effective building time

        # TODO: Add Max decay
        let (current_actual_time, _) = unsigned_div_rem((10000 - decay_rate) * time_balance, 10000)

        return (current_actual_time)
    end
end
