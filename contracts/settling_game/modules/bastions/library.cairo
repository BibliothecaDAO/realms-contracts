%lang starknet

from starkware.cairo.common.math import abs_value
from starkware.cairo.common.math_cmp import is_not_zero, is_le
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.settling_game.modules.bastions.constants import MovingTimes

namespace Bastions {
    // TODO: see if we want to allow travel to non adjacent towers
    // find_shortest_path_from_tower_to_opposite_tower

    func find_shortest_path_from_tower_to_central_square{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        order: felt,
        current_location: felt,
        tower_1_defending_order: felt,
        tower_2_defending_order: felt,
        tower_3_defending_order: felt,
        tower_4_defending_order: felt,
        distance_gate_tower: felt,
        distance_tower_cs: felt,
    ) -> (moving_time: felt) {
        alloc_locals;
        // if location 1 = north tower
        // adjacent = tower 4 (west) and tower 2 (east)
        // oppposite = 3 south tower
        let is_not_location_1 = is_not_zero(current_location - 1);
        let is_not_location_3 = is_not_zero(current_location - 3);
        let is_location_1_or_3 = is_le(is_not_location_1 + is_not_location_3, 1);

        // if is location 1 or 3
        if (is_location_1_or_3 == 1) {
            let is_not_defending_tower_2 = is_not_zero(tower_2_defending_order - order);
            let is_not_defending_tower_4 = is_not_zero(tower_4_defending_order - order);
            let number_of_adjacent_towers_not_defending = is_not_defending_tower_2 +
                is_not_defending_tower_4;
            let has_at_least_one_adjacent_tower = is_le(number_of_adjacent_towers_not_defending, 1);
            if (has_at_least_one_adjacent_tower == 1) {
                local moving_times = distance_gate_tower + distance_tower_cs;
                return (moving_times,);
            } else {
                local moving_times = distance_gate_tower * 2;
                local moving_times = moving_times + distance_tower_cs;
                return (moving_times,);
            }
        } else {
            // if not has to be location 2 or 4
            let is_not_defending_tower_1 = is_not_zero(tower_1_defending_order - order);
            let is_not_defending_tower_3 = is_not_zero(tower_3_defending_order - order);
            let number_of_adjacent_towers_not_defending = is_not_defending_tower_1 +
                is_not_defending_tower_3;
            let has_at_least_one_adjacent_tower = is_le(number_of_adjacent_towers_not_defending, 1);
            if (has_at_least_one_adjacent_tower == 1) {
                local moving_times = distance_gate_tower + distance_tower_cs;
                return (moving_times,);
            } else {
                local moving_times = distance_gate_tower * 2;
                local moving_times = moving_times + distance_tower_cs;
                return (moving_times,);
            }
        }
    }

    // Can only move from one tower/gate to an adjacent tower/gate
    func is_adjacent_tower{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        current_location: felt, next_location: felt
    ) -> (valid: felt) {
        let location_difference = abs_value(current_location - next_location);
        if (location_difference == 1) {
            return (TRUE,);
        } else {
            if (location_difference == 3) {
                return (TRUE,);
            } else {
                return (FALSE,);
            }
        }
    }

    // Returns number of conquered tower by the order
    func number_of_conquered_towers{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        order: felt,
        tower_1_defending_order: felt,
        tower_2_defending_order: felt,
        tower_3_defending_order: felt,
        tower_4_defending_order: felt,
    ) -> (number_of_conquered_towers: felt) {
        let tower_1_order_difference = tower_1_defending_order - order;
        let tower_2_order_difference = tower_2_defending_order - order;
        let tower_3_order_difference = tower_3_defending_order - order;
        let tower_4_order_difference = tower_4_defending_order - order;

        tempvar number_of_unconquered_towers = is_not_zero(tower_1_order_difference) + is_not_zero(
            tower_2_order_difference
        ) + is_not_zero(tower_3_order_difference) + is_not_zero(tower_4_order_difference);
        return (4 - number_of_unconquered_towers,);
    }
}
