// STAKING LIBRARY
//   Helper functions for staking.
//
//
// MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_nn
from starkware.cairo.common.math_cmp import is_le

from starkware.cairo.common.bool import TRUE, FALSE

from contracts.settling_game.utils.game_structs import RealmData
from contracts.settling_game.utils.constants import (
    CCombat,
    VAULT_LENGTH,
    DAY,
    BASE_RESOURCES_PER_DAY,
    BASE_LORDS_PER_DAY,
    MAX_DAYS_ACCURED,
    WONDER_RATE,
    BASE_LABOR_UNITS,
)

namespace Labor {
    func labor_units_generated{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        current_balance: felt, last_harvest_time: felt
    ) -> (labor_units_generated: felt, part_labor_units: felt, is_labor_complete: felt) {
        alloc_locals;
        let (ts) = get_block_timestamp();

        // check if balance is in the past - this means you can harvest the entire amount
        let is_labor_complete = is_le(current_balance, ts);

        if (is_labor_complete == TRUE) {
            tempvar to_harvest = current_balance - last_harvest_time;
        } else {
            tempvar to_harvest = ts - last_harvest_time;
        }

        // harvest - all and set last harvest to now
        let (labor_units_generated, part_labor_units) = unsigned_div_rem(
            to_harvest, BASE_LABOR_UNITS
        );

        return (labor_units_generated, part_labor_units, is_labor_complete);
    }
}
