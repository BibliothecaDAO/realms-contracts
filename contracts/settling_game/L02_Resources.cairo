# ____MODULE_L02___RESOURCES_LOGIC
#   Logic to create and issue resources for a given Realm
#
# MIT License
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le, is_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.game_structs import RealmData, ModuleIds, ExternalContractIds, Cost
from contracts.settling_game.utils.general import (
    scale,
    unpack_data,
    transform_costs_to_token_ids_values,
)

from contracts.settling_game.utils.constants import (
    TRUE,
    FALSE,
    VAULT_LENGTH,
    DAY,
    VAULT_LENGTH_SECONDS,
    BASE_RESOURCES_PER_DAY,
    BASE_LORDS_PER_DAY,
    PILLAGE_AMOUNT,
)
from contracts.settling_game.utils.library import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
)

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.imodules import (
    IModuleController,
    IS02_Resources,
    IS01_Settling,
    IL04_Calculator,
    IS05_Wonders,
)

##########
# EVENTS #
# ########

@event
func ResourceUpgraded(token_id : Uint256, building_id : felt, level : felt):
end

###############
# CONSTRUCTOR #
###############
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt
):
    MODULE_initializer(address_of_controller)
    return ()
end

############
# EXTERNAL #
############

@external
func claim_resources{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()

    # LORDS CONTRACT
    let (lords_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Lords
    )

    # REALMS CONTRACT
    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    )

    # S_REALMS CONTRACT
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms
    )

    # RESOURCES 1155 CONTRACT
    let (resources_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    )

    # RESOURCE STATE
    let (resources_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S02_Resources
    )

    # SETTLING STATE
    let (settling_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S01_Settling
    )

    # SETTLING LOGIC
    let (settling_logic_address) = IModuleController.get_module_address(
        controller, ModuleIds.L01_Settling
    )

    # CALCULATOR
    let (calculator_address) = IModuleController.get_module_address(
        controller, ModuleIds.L04_Calculator
    )

    # TREASURY
    let (treasury_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Treasury
    )

    # WONDER STATE
    let (wonders_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S05_Wonders
    )

    # FETCH OWNER
    let (owner) = realms_IERC721.ownerOf(s_realms_address, token_id)

    # ALLOW RESOURCE LOGIC ADDRESS TO CLAIM, BUT STILL RESTRICT
    if caller != settling_logic_address:
        with_attr error_message("SETTLING_STATE: Not your realm ser"):
            assert caller = owner
        end
    end

    let (local resource_ids : Uint256*) = alloc()
    let (local user_mint : Uint256*) = alloc()
    let (local wonder_tax_arr : Uint256*) = alloc()

    # FETCH REALM DATA
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(realms_address, token_id)

    # CALC DAYS
    let (total_days, remainder) = get_available_resources(token_id)

    # CALC VAULT DAYS
    let (total_vault_days, vault_remainder) = get_available_vault_resources(token_id)

    # CHECK DAYS + VAULT > 1
    let days = total_days + total_vault_days

    with_attr error_message("RESOURCES: Nothing Claimable."):
        assert_not_zero(days)
    end

    # SET VAULT TIME = REMAINDER - CURRENT_TIME
    IS01_Settling.set_time_staked(settling_state_address, token_id, remainder)
    IS01_Settling.set_time_vault_staked(settling_state_address, token_id, vault_remainder)

    # GET WONDER TAX
    let (wonder_tax) = IL04_Calculator.calculate_wonder_tax(calculator_address)

    # SET MINT
    let treasury_mint_perc = wonder_tax
    let user_mint_rel_perc = 100 - wonder_tax

    # GET OUTPUT FOR EACH RESOURCE
    let (r_1_output) = calculate_resource_output(token_id, realms_data.resource_1)
    let (r_2_output) = calculate_resource_output(token_id, realms_data.resource_2)
    let (r_3_output) = calculate_resource_output(token_id, realms_data.resource_3)
    let (r_4_output) = calculate_resource_output(token_id, realms_data.resource_5)
    let (r_5_output) = calculate_resource_output(token_id, realms_data.resource_5)
    let (r_6_output) = calculate_resource_output(token_id, realms_data.resource_6)
    let (r_7_output) = calculate_resource_output(token_id, realms_data.resource_7)

    # ADD VALUES TO TEMP ARRAY FOR EACH AVAILABLE RESOURCE
    let (r_1_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, user_mint_rel_perc, r_1_output
    )
    let (r_1_wonder) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, treasury_mint_perc, r_1_output
    )

    assert resource_ids[0] = Uint256(realms_data.resource_1, 0)
    assert user_mint[0] = r_1_user
    assert wonder_tax_arr[0] = r_1_wonder

    let (r_2_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, user_mint_rel_perc, r_2_output
    )
    let (r_2_wonder) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, treasury_mint_perc, r_2_output
    )
    if realms_data.resource_2 != 0:
        assert resource_ids[1] = Uint256(realms_data.resource_2, 0)
        assert user_mint[1] = r_2_user
        assert wonder_tax_arr[1] = r_2_wonder
    end
    let (r_3_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, user_mint_rel_perc, r_3_output
    )
    let (r_3_wonder) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, treasury_mint_perc, r_3_output
    )
    if realms_data.resource_3 != 0:
        assert resource_ids[2] = Uint256(realms_data.resource_3, 0)
        assert user_mint[2] = r_3_user
        assert wonder_tax_arr[2] = r_3_wonder
    end
    let (r_4_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, user_mint_rel_perc, r_4_output
    )
    let (r_4_wonder) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, treasury_mint_perc, r_4_output
    )
    if realms_data.resource_4 != 0:
        assert resource_ids[3] = Uint256(realms_data.resource_4, 0)
        assert user_mint[3] = r_4_user
        assert wonder_tax_arr[3] = r_4_wonder
    end
    let (r_5_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, user_mint_rel_perc, r_5_output
    )
    let (r_5_wonder) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, treasury_mint_perc, r_5_output
    )
    if realms_data.resource_5 != 0:
        assert resource_ids[4] = Uint256(realms_data.resource_5, 0)
        assert user_mint[4] = r_5_user
        assert wonder_tax_arr[4] = r_5_wonder
    end

    let (r_6_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, user_mint_rel_perc, r_6_output
    )
    let (r_6_wonder) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, treasury_mint_perc, r_6_output
    )
    if realms_data.resource_6 != 0:
        assert resource_ids[5] = Uint256(realms_data.resource_6, 0)
        assert user_mint[5] = r_6_user
        assert wonder_tax_arr[5] = r_6_wonder
    end

    let (r_7_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, user_mint_rel_perc, r_7_output
    )
    let (r_7_wonder) = calculate_total_claimable(
        token_id, realms_data.resource_1, days, treasury_mint_perc, r_7_output
    )
    if realms_data.resource_7 != 0:
        assert resource_ids[6] = Uint256(realms_data.resource_7, 0)
        assert user_mint[6] = r_7_user
        assert wonder_tax_arr[6] = r_7_wonder
    end

    # LORDS MINT
    let lords_available = Uint256(total_days * BASE_LORDS_PER_DAY, 0)

    # MINT LORDS
    IERC20.transferFrom(lords_address, treasury_address, owner, lords_available)

    # TODO: AUDIT CHECK SECURE PATH TO MINT

    # MINT USERS RESOURCES
    IERC1155.mintBatch(
        resources_address,
        owner,
        realms_data.resource_number,
        resource_ids,
        realms_data.resource_number,
        user_mint,
    )

    # GET EPOCH
    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)

    # SET WONDER TAX IN POOL
    IS05_Wonders.batch_set_tax_pool(
        wonders_state_address,
        current_epoch,
        realms_data.resource_number,
        resource_ids,
        realms_data.resource_number,
        wonder_tax_arr,
    )

    return ()
end

@external
func pillage_resources{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, claimer : felt
):
    # TODO: auth checks
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()

    # REALMS CONTRACT
    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    )

    # S_REALMS CONTRACT
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms
    )

    # RESOURCES 1155 CONTRACT
    let (resources_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    )

    # RESOURCE STATE
    let (resources_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S02_Resources
    )

    # SETTLING STATE
    let (settling_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S01_Settling
    )

    # SETTLING LOGIC
    let (settling_logic_address) = IModuleController.get_module_address(
        controller, ModuleIds.L01_Settling
    )

    let (local resource_ids : Uint256*) = alloc()
    let (local user_mint : Uint256*) = alloc()

    # FETCH REALM DATA
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(realms_address, token_id)

    # CALC PILLAGABLE DAYS
    let (total_pillagable_days, pillagable_remainder) = get_pillaged_resources(token_id)

    with_attr error_message("RESOURCES: NOTHING TO RAID!"):
        assert_not_zero(total_pillagable_days)
    end

    # SET VAULT TIME = REMAINDER - CURRENT_TIME
    IS01_Settling.set_time_vault_staked(settling_state_address, token_id, pillagable_remainder)

    # GET OUTPUT FOR EACH RESOURCE
    let (r_1_output) = calculate_resource_output(token_id, realms_data.resource_1)
    let (r_2_output) = calculate_resource_output(token_id, realms_data.resource_2)
    let (r_3_output) = calculate_resource_output(token_id, realms_data.resource_3)
    let (r_4_output) = calculate_resource_output(token_id, realms_data.resource_5)
    let (r_5_output) = calculate_resource_output(token_id, realms_data.resource_5)
    let (r_6_output) = calculate_resource_output(token_id, realms_data.resource_6)
    let (r_7_output) = calculate_resource_output(token_id, realms_data.resource_7)

    # ADD VALUES TO TEMP ARRAY FOR EACH AVAILABLE RESOURCE
    let (r_1_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, total_pillagable_days, PILLAGE_AMOUNT, r_1_output
    )
    assert resource_ids[0] = Uint256(realms_data.resource_1, 0)
    assert user_mint[0] = r_1_user

    let (r_2_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, total_pillagable_days, PILLAGE_AMOUNT, r_2_output
    )

    if realms_data.resource_2 != 0:
        assert resource_ids[1] = Uint256(realms_data.resource_2, 0)
        assert user_mint[1] = r_2_user
    end
    let (r_3_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, total_pillagable_days, PILLAGE_AMOUNT, r_3_output
    )

    if realms_data.resource_3 != 0:
        assert resource_ids[2] = Uint256(realms_data.resource_3, 0)
        assert user_mint[2] = r_3_user
    end
    let (r_4_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, total_pillagable_days, PILLAGE_AMOUNT, r_4_output
    )

    if realms_data.resource_4 != 0:
        assert resource_ids[3] = Uint256(realms_data.resource_4, 0)
        assert user_mint[3] = r_4_user
    end
    let (r_5_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, total_pillagable_days, PILLAGE_AMOUNT, r_5_output
    )

    if realms_data.resource_5 != 0:
        assert resource_ids[4] = Uint256(realms_data.resource_5, 0)
        assert user_mint[4] = r_5_user
    end

    let (r_6_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, total_pillagable_days, PILLAGE_AMOUNT, r_6_output
    )

    if realms_data.resource_6 != 0:
        assert resource_ids[5] = Uint256(realms_data.resource_6, 0)
        assert user_mint[5] = r_6_user
    end

    let (r_7_user) = calculate_total_claimable(
        token_id, realms_data.resource_1, total_pillagable_days, PILLAGE_AMOUNT, r_7_output
    )
    if realms_data.resource_7 != 0:
        assert resource_ids[6] = Uint256(realms_data.resource_7, 0)
        assert user_mint[6] = r_7_user
    end

    # MINT USERS RESOURCES
    IERC1155.mintBatch(
        resources_address,
        claimer,
        realms_data.resource_number,
        resource_ids,
        realms_data.resource_number,
        user_mint,
    )

    return ()
end

###########
# GETTERS #
###########

# FETCHES AVAILABLE RESOURCES PER DAY
@view
func get_available_resources{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (days_accrued : felt, remainder : felt):
    let (controller) = MODULE_controller_address()

    let (settling_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S01_Settling
    )

    let (last_update) = IS01_Settling.get_time_staked(settling_state_address, token_id)

    let (block_timestamp) = get_block_timestamp()

    let (days_accrued, seconds_left_over) = unsigned_div_rem(block_timestamp - last_update, DAY)

    return (days_accrued, seconds_left_over)
end

# FETCHES AVAILABLE RESOURCES PER VAULT
@view
func get_available_vault_resources{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(token_id : Uint256) -> (days_accrued : felt, remainder : felt):
    alloc_locals
    let (controller) = MODULE_controller_address()

    let (settling_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S01_Settling
    )

    let (block_timestamp) = get_block_timestamp()

    let (last_update) = IS01_Settling.get_time_vault_staked(settling_state_address, token_id)

    # CALC REMAINING DAYS
    let (days_accrued, seconds_left_over) = unsigned_div_rem(block_timestamp - last_update, DAY)

    # returns true if days <= vault_length -1 (we minus 1 so the user can claim when they have 7 days)
    let (less_than) = is_le(days_accrued, VAULT_LENGTH - 1)

    # return no days and no remainder
    if less_than == TRUE:
        return (0, 0)
    end

    # else return days and remainder
    return (days_accrued, seconds_left_over)
end

# FETCHES RESOURCES FOR PILLAGING!
@view
func get_pillaged_resources{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (days_accrued : felt, remainder : felt):
    alloc_locals
    let (controller) = MODULE_controller_address()

    let (settling_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S01_Settling
    )

    let (block_timestamp) = get_block_timestamp()

    let (last_update) = IS01_Settling.get_time_vault_staked(settling_state_address, token_id)

    # CALC REMAINING DAYS
    let (days_accrued, seconds_left_over) = unsigned_div_rem(block_timestamp - last_update, DAY)

    # else return days and remainder
    return (days_accrued, seconds_left_over)
end

@view
func check_if_claimable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (can_claim : felt):
    alloc_locals
    let (days, _) = get_available_resources(token_id)
    let (epochs, _) = get_available_vault_resources(token_id)

    # add in 1 to allow user to claim 1 day if available
    let (less_than) = is_le(days + epochs + 1, 1)

    if less_than == TRUE:
        return (FALSE)
    end

    return (TRUE)
end

############
# EXTERNAL #
############

@external
func upgrade_resource{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr
}(token_id : Uint256, resource_id : felt) -> ():
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()

    # resource contract
    let (resource_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    )

    # sRealms contract
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms
    )

    # check owner of sRealm
    let (owner) = realms_IERC721.ownerOf(contract_address=s_realms_address, token_id=token_id)

    with_attr error_message("You do not own this Realm"):
        assert caller = owner
    end

    # STATE
    let (resources_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S02_Resources
    )

    # GET RESOURCE LEVEL
    let (level) = IS02_Resources.get_resource_level(resources_state_address, token_id, resource_id)

    # GET UPGRADE VALUE
    let (upgrade_cost : Cost) = IS02_Resources.get_resource_upgrade_cost(
        resources_state_address, resource_id
    )
    let (costs : Cost*) = alloc()
    assert [costs] = upgrade_cost
    let (token_ids : Uint256*) = alloc()
    let (token_values : Uint256*) = alloc()
    let (token_len : felt) = transform_costs_to_token_ids_values(1, costs, token_ids, token_values)

    # BURN RESOURCES
    IERC1155.burnBatch(resource_address, caller, token_len, token_ids, token_len, token_values)

    # INCREASE LEVEL
    IS02_Resources.set_resource_level(resources_state_address, token_id, resource_id, level + 1)

    # EMIT
    ResourceUpgraded.emit(token_id, resource_id, level + 1)
    return ()
end

func calculate_resource_output{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, resource_id : felt
) -> (value : felt):
    alloc_locals
    let (controller) = MODULE_controller_address()

    # STATE
    let (resources_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S02_Resources
    )

    # GET RESOURCE LEVEL
    let (level) = IS02_Resources.get_resource_level(resources_state_address, token_id, resource_id)

    local l
    # CALC
    if level == 0:
        return (BASE_RESOURCES_PER_DAY)
    end
    return ((level + 1) * BASE_RESOURCES_PER_DAY)
end

func calculate_total_claimable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, resource_id : felt, days : felt, tax : felt, output : felt
) -> (value : Uint256):
    alloc_locals

    # days * current tax * output
    # we multiply by tax before dividing by 100
    let (total_work_generated, _) = unsigned_div_rem(days * tax * output, 100)
    return (Uint256(total_work_generated, 0))
end
