//
// TITLE:
//      Labour Library
//
// LOGIC:
//      Utils for the Labor.cairo module
//
// AUTHOR:
//       <ponderingdemocritus@protonmail.com>
//
// MIT LICENSE

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_nn
from starkware.cairo.common.math_cmp import is_le

from starkware.cairo.common.bool import TRUE

from contracts.settling_game.utils.constants import BASE_LABOR_UNITS, DAY, VAULT_LENGTH

const VAULT_PERCENTAGE = 250;  // bp
const DIVIDER = 1000;

namespace Labor {
    func labor_units_generated{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        current_balance: felt, last_harvest_time: felt
    ) -> (
        labor_units_generated: felt,
        part_labor_units: felt,
        is_labor_complete: felt,
        vault_amount: felt,
    ) {
        alloc_locals;
        let (ts) = get_block_timestamp();

        // check if balance is in the past - this means you can harvest the entire amount
        let is_labor_complete = is_le(current_balance, ts);

        if (is_labor_complete == TRUE) {
            tempvar to_harvest = current_balance - last_harvest_time;
        } else {
            tempvar to_harvest = ts - last_harvest_time;
        }

        // calculate vault amount
        let (vault_amount, _) = unsigned_div_rem(to_harvest * VAULT_PERCENTAGE, DIVIDER);

        // harvest - all and set last harvest to now
        // subtract vault amount
        let (labor_units_generated, part_labor_units) = unsigned_div_rem(
            to_harvest - vault_amount, BASE_LABOR_UNITS
        );

        return (labor_units_generated, part_labor_units, is_labor_complete, vault_amount);
    }
    func vault_units{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        current_balance: felt
    ) -> (vault_units_generated: felt, part_vault_units_generated: felt) {
        alloc_locals;

        // calculate vault amount in BASE_LABOR_UNITS
        let (vault_units_generated, part_vault_units_generated) = unsigned_div_rem(
            current_balance, BASE_LABOR_UNITS
        );

        // check vault has at least 7 DAYS
        // calculated by 7 * 12 (turned into BASE_LABOR_UNITS)
        let less_than_vault_claim = is_le(vault_units_generated, VAULT_LENGTH * 12);

        if (less_than_vault_claim == TRUE) {
            return (0, 0);
        }

        return (vault_units_generated, part_vault_units_generated);
    }
}
