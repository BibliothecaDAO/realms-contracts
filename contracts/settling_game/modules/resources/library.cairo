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
from starkware.cairo.common.registers import get_label_location

from contracts.settling_game.utils.game_structs import RealmData
from contracts.settling_game.utils.constants import (
    BASE_RESOURCES_PER_DAY,
    WORK_HUT_COST,
    WORK_HUT_OUTPUT,
    CCombat,
    WONDER_RATE
)

namespace Resources {
    // @notice gets resource ids from realm data
    // @param: data struct of realm
    // @return resource_mint: array of resource ids
    func _calculate_realm_resource_ids{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(realms_data: RealmData) -> (resource_ids: Uint256*) {
        alloc_locals;

        let (local resource_ids: Uint256*) = alloc();

        // ADD VALUES TO TEMP ARRAY FOR EACH AVAILABLE RESOURCE
        assert resource_ids[0] = Uint256(realms_data.resource_1, 0);

        if (realms_data.resource_2 != 0) {
            assert resource_ids[1] = Uint256(realms_data.resource_2, 0);
        }

        if (realms_data.resource_3 != 0) {
            assert resource_ids[2] = Uint256(realms_data.resource_3, 0);
        }

        if (realms_data.resource_4 != 0) {
            assert resource_ids[3] = Uint256(realms_data.resource_4, 0);
        }

        if (realms_data.resource_5 != 0) {
            assert resource_ids[4] = Uint256(realms_data.resource_5, 0);
        }

        if (realms_data.resource_6 != 0) {
            assert resource_ids[5] = Uint256(realms_data.resource_6, 0);
        }

        if (realms_data.resource_7 != 0) {
            assert resource_ids[6] = Uint256(realms_data.resource_7, 0);
        }

        return (resource_ids,);
    }

    // @notics gets the cost to build a workhut on a Realm
    // @param realms_data: data struct of realm
    // @param quantity: number of workhuts
    // @return resource_ids: array of resource ids
    // @return resource_values: array of resource costs
    func workhut_costs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        realms_data: RealmData, quantity: felt
    ) -> (resource_ids: Uint256*, resource_values: Uint256*) {
        alloc_locals;

        let (local resource_ids: Uint256*) = alloc();
        let (local resource_values: Uint256*) = alloc();

        let cost = (WORK_HUT_COST * 10 ** 18) * quantity;

        // ADD VALUES TO TEMP ARRAY FOR EACH AVAILABLE RESOURCE
        assert resource_ids[0] = Uint256(realms_data.resource_1, 0);
        assert resource_values[0] = Uint256(cost, 0);

        if (realms_data.resource_2 != 0) {
            assert resource_ids[1] = Uint256(realms_data.resource_2, 0);
            assert resource_values[1] = Uint256(cost, 0);
        }

        if (realms_data.resource_3 != 0) {
            assert resource_ids[2] = Uint256(realms_data.resource_3, 0);
            assert resource_values[2] = Uint256(cost, 0);
        }

        if (realms_data.resource_4 != 0) {
            assert resource_ids[3] = Uint256(realms_data.resource_4, 0);
            assert resource_values[3] = Uint256(cost, 0);
        }

        if (realms_data.resource_5 != 0) {
            assert resource_ids[4] = Uint256(realms_data.resource_5, 0);
            assert resource_values[4] = Uint256(cost, 0);
        }

        if (realms_data.resource_6 != 0) {
            assert resource_ids[5] = Uint256(realms_data.resource_6, 0);
            assert resource_values[5] = Uint256(cost, 0);
        }

        if (realms_data.resource_7 != 0) {
            assert resource_ids[6] = Uint256(realms_data.resource_7, 0);
            assert resource_values[6] = Uint256(cost, 0);
        }

        return (resource_ids, resource_values);
    }

    // @notice generates array of mintable resources
    // @param realms_data: data struct of realm
    // @params resources_mint: amount of resourcs 1-7
    // @return resource_mint_len: length of claimable resources array
    // @return resource_mint: claimable resources array
    func _calculate_mintable_resources{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        realms_data: RealmData,
        resource_mint_1: Uint256,
        resource_mint_2: Uint256,
        resource_mint_3: Uint256,
        resource_mint_4: Uint256,
        resource_mint_5: Uint256,
        resource_mint_6: Uint256,
        resource_mint_7: Uint256,
    ) -> (resource_mint_len: felt, resource_mint: Uint256*) {
        alloc_locals;

        let (local resource_mint: Uint256*) = alloc();

        // ADD VALUES TO TEMP ARRAY FOR EACH AVAILABLE RESOURCE
        assert resource_mint[0] = resource_mint_1;

        if (realms_data.resource_2 != 0) {
            assert resource_mint[1] = resource_mint_2;
        }

        if (realms_data.resource_3 != 0) {
            assert resource_mint[2] = resource_mint_3;
        }

        if (realms_data.resource_4 != 0) {
            assert resource_mint[3] = resource_mint_4;
        }

        if (realms_data.resource_5 != 0) {
            assert resource_mint[4] = resource_mint_5;
        }

        if (realms_data.resource_6 != 0) {
            assert resource_mint[5] = resource_mint_6;
        }

        if (realms_data.resource_7 != 0) {
            assert resource_mint[6] = resource_mint_7;
        }

        return (realms_data.resource_number, resource_mint);
    }

    // @notice calculate claimable resource
    // @param days: number of days accrued from unclaimed resources
    // @param tax: taxable resource rate
    // @param output: workhut and happiness output
    // @return value: claimable resource amount
    func _calculate_resource_claimable{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(days: felt, tax: felt, output: felt) -> (value: Uint256) {
        alloc_locals;
        // days * current tax * output
        // we multiply by tax before dividing by 100

        let (total_work_generated, _) = unsigned_div_rem(days * tax * output, 100);

        let work_bn = total_work_generated * 10 ** 18;

        with_attr error_message("RESOURCES: work bn greater than") {
            assert_nn(work_bn);
        }

        return (Uint256(work_bn, 0),);
    }

    // @notice calculate resource output
    // @param workhuts: number of workhuts
    // @param happiness: happiness value, out of 100
    // @return value: resource output
    func _calculate_resource_output{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(workhuts: felt, happiness: felt) -> (value: felt) {
        alloc_locals;

        // Add workhut boost
        let extra_output = workhuts * WORK_HUT_OUTPUT;

        // HAPPINESS CHECK
        let (production_output, _) = unsigned_div_rem(BASE_RESOURCES_PER_DAY * happiness, 100);

        return (production_output + extra_output,);
    }


    // @notice calculate resource output for 7 resources
    // @param workhuts: number of workhuts
    // @param happiness: happiness value, out of 100
    // @param realm_data: data struct for realm
    // @returns resources: resource output 1-7
    func _calculate_all_resource_output{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(workhuts: felt, happiness: felt, realms_data: RealmData) -> (
        resource_1: felt,
        resource_2: felt,
        resource_3: felt,
        resource_4: felt,
        resource_5: felt,
        resource_6: felt,
        resource_7: felt,
    ) {
        alloc_locals;

        let (output) = _calculate_resource_output(workhuts, happiness);

        return (output, output, output, output, output, output, output);
    }

    // @notice Calculate resources to mint
    // @param workhuts: number of workhuts
    // @param happiness: hapiness value, out of 100
    // @param realms_data: data struct of realm
    // @param days: days accrued from unclaimed resources
    // @param mint_percentage: percentage of mint after tax
    // @return resource_mint: amounts of resources to mint
    func _calculate_total_mintable_resources{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(
        workhuts: felt, happiness: felt, realms_data: RealmData, days: felt, mint_percentage: felt
    ) -> (resource_mint: Uint256*) {
        alloc_locals;

        let (
            r_1_output, r_2_output, r_3_output, r_4_output, r_5_output, r_6_output, r_7_output
        ) = _calculate_all_resource_output(workhuts, happiness, realms_data);

        // USER CLAIM
        let (r_1_user) = _calculate_resource_claimable(days, mint_percentage, r_1_output);
        let (r_2_user) = _calculate_resource_claimable(days, mint_percentage, r_2_output);
        let (r_3_user) = _calculate_resource_claimable(days, mint_percentage, r_3_output);
        let (r_4_user) = _calculate_resource_claimable(days, mint_percentage, r_4_output);
        let (r_5_user) = _calculate_resource_claimable(days, mint_percentage, r_5_output);
        let (r_6_user) = _calculate_resource_claimable(days, mint_percentage, r_6_output);
        let (r_7_user) = _calculate_resource_claimable(days, mint_percentage, r_7_output);

        let (_, resource_mint: Uint256*) = _calculate_mintable_resources(
            realms_data, r_1_user, r_2_user, r_3_user, r_4_user, r_5_user, r_6_user, r_7_user
        );

        return (resource_mint,);
    }

    // @notice Get 
    // @param total_time: time staked in vault
    // @return time_over: time left to stake
    func _calculate_vault_time_remaining{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(total_time: felt) -> (time_over: felt) {
        alloc_locals;

        let (time_over, _) = unsigned_div_rem(total_time * CCombat.PILLAGE_AMOUNT, 100);

        return (time_over,);
    }

    // @notice Get resource ids
    // @return resource_ids: resource ids array
    func _get_all_resource_ids{
        syscall_ptr: felt*, range_check_ptr
    }() -> (resource_ids: Uint256*) {
        alloc_locals;

        let (RESOURCES_ARR) = get_label_location(resource_start);
        return (resource_ids=cast(RESOURCES_ARR, Uint256*));

        resource_start:
        dw 1;
        dw 0;
        dw 2;
        dw 0;
        dw 3;
        dw 0;
        dw 4;
        dw 0;
        dw 5;
        dw 0;
        dw 6;
        dw 0;
        dw 7;
        dw 0;
        dw 8;
        dw 0;
        dw 9;
        dw 0;
        dw 10;
        dw 0;
        dw 11;
        dw 0;
        dw 12;
        dw 0;
        dw 13;
        dw 0;
        dw 14;
        dw 0;
        dw 15;
        dw 0;
        dw 16;
        dw 0;
        dw 17;
        dw 0;
        dw 18;
        dw 0;
        dw 19;
        dw 0;
        dw 20;
        dw 0;
        dw 21;
        dw 0;
        dw 22;
        dw 0;
    }
  
    // @notice Calculates wonder amounts to claim
    // @param days: number of day claimable
    // @return resource_amounts_len: length of resources
    // @return resource_amounts: calculated resource amounts
    func _calculate_wonder_amounts{
        syscall_ptr: felt*, range_check_ptr
    }(days: felt) -> (resource_amounts_len: felt, resource_amounts: Uint256*) {
        let wonder_amount = Uint256(days * WONDER_RATE * 10 ** 18, 0);
    
        let (resource_amounts: Uint256*) = alloc();
        assert resource_amounts[0] = wonder_amount;
        assert resource_amounts[1] = wonder_amount;
        assert resource_amounts[2] = wonder_amount;
        assert resource_amounts[3] = wonder_amount;
        assert resource_amounts[4] = wonder_amount;
        assert resource_amounts[5] = wonder_amount;
        assert resource_amounts[6] = wonder_amount;
        assert resource_amounts[7] = wonder_amount;
        assert resource_amounts[8] = wonder_amount;
        assert resource_amounts[9] = wonder_amount;
        assert resource_amounts[10] = wonder_amount;
        assert resource_amounts[11] = wonder_amount;
        assert resource_amounts[12] = wonder_amount;
        assert resource_amounts[13] = wonder_amount;
        assert resource_amounts[14] = wonder_amount;
        assert resource_amounts[15] = wonder_amount;
        assert resource_amounts[16] = wonder_amount;
        assert resource_amounts[17] = wonder_amount;
        assert resource_amounts[18] = wonder_amount;
        assert resource_amounts[19] = wonder_amount;
        assert resource_amounts[20] = wonder_amount;
        assert resource_amounts[21] = wonder_amount;

        return (22, resource_amounts);
    }
}
