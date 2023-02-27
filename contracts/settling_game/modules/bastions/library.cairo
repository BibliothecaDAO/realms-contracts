%lang starknet

from starkware.cairo.common.math import abs_value
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

namespace Bastions {
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
