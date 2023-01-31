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
from starkware.cairo.common.math import unsigned_div_rem, assert_nn, assert_not_zero
from starkware.cairo.common.math_cmp import is_le

from starkware.cairo.common.bool import TRUE

from contracts.settling_game.utils.constants import BASE_LABOR_UNITS, DAY, VAULT_LENGTH, CCombat

from contracts.settling_game.utils.game_structs import ResourceIds, RealmData

const VAULT_PERCENTAGE = 250;  // bp

const DIVIDER_1000 = 1000;

const DIVIDER_100 = 100;

namespace Labor {
    func labor_units_generated{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        current_balance: felt, last_harvest_time: felt, time_stamp: felt
    ) -> (
        labor_units_generated: felt,
        part_labor_units: felt,
        is_labor_complete: felt,
        vault_amount: felt,
    ) {
        alloc_locals;

        // check if balance is in the past - this means you can harvest the entire amount
        let is_labor_complete = is_le(current_balance, time_stamp);

        if (is_labor_complete == TRUE) {
            tempvar to_harvest = current_balance - last_harvest_time;
        } else {
            tempvar to_harvest = time_stamp - last_harvest_time;
        }

        // calculate vault amount
        let (vault_amount, _) = unsigned_div_rem(to_harvest * VAULT_PERCENTAGE, DIVIDER_1000);

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
    func raidable_labor_units{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        current_balance: felt
    ) -> (vault_units_generated: felt, part_vault_units_generated: felt) {
        alloc_locals;

        // calculate vault amount in BASE_LABOR_UNITS
        let (vault_units_generated, part_vault_units_generated) = unsigned_div_rem(
            current_balance, BASE_LABOR_UNITS
        );

        // get PILLAGE_AMOUNT of total units
        let (vault_amount, _) = unsigned_div_rem(
            vault_units_generated * CCombat.PILLAGE_AMOUNT, DIVIDER_100
        );

        return (vault_amount, part_vault_units_generated);
    }

    func food_units_generated{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        current_balance: felt, last_harvest_time: felt, time_stamp: felt
    ) -> (labor_units_generated: felt, part_labor_units: felt, is_labor_complete: felt) {
        alloc_locals;

        // check if balance is in the past - this means you can harvest the entire amount
        let is_labor_complete = is_le(current_balance, time_stamp);

        if (is_labor_complete == TRUE) {
            tempvar to_harvest = current_balance - last_harvest_time;
        } else {
            tempvar to_harvest = time_stamp - last_harvest_time;
        }

        // calculate vault amount
        let (vault_amount, _) = unsigned_div_rem(to_harvest * VAULT_PERCENTAGE, DIVIDER_1000);

        // harvest - all and set last harvest to now
        // subtract vault amount
        let (labor_units_generated, part_labor_units) = unsigned_div_rem(
            to_harvest - vault_amount, BASE_LABOR_UNITS
        );

        return (labor_units_generated, part_labor_units, is_labor_complete);
    }

    func assert_resource_ids{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        resource_id: felt
    ) {
        alloc_locals;

        // check
        if (resource_id == ResourceIds.fish) {
            return ();
        }
        if (resource_id == ResourceIds.wheat) {
            return ();
        }

        with_attr error_message("Labor: Incorrect Resource ID") {
            assert 1 = 0;
        }

        return ();
    }

    func assert_enough_traits{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        realm_data: RealmData, resource_id: felt, qty_built: felt
    ) {
        alloc_locals;

        // check
        if (resource_id == ResourceIds.fish) {
            let le = is_le(qty_built, realm_data.harbours);
            assert_not_zero(le);
            return ();
        }
        if (resource_id == ResourceIds.wheat) {
            let le = is_le(qty_built, realm_data.rivers);
            assert_not_zero(le);
            return ();
        }

        with_attr error_message("Labor: Not enough Traits") {
            assert 1 = 0;
        }

        return ();
    }
}
