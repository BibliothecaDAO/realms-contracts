# ____MODULE_L02___RESOURCES_LOGIC
#   Logic to create and issue resources for a given Realm
#
# MIT License
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.utils.game_structs import RealmData, ModuleIds, ExternalContractIds, Cost
from contracts.settling_game.utils.general import (
    transform_costs_to_token_ids_values,
)

from contracts.settling_game.utils.constants import (
    TRUE,
    FALSE,
    VAULT_LENGTH,
    DAY,
    BASE_RESOURCES_PER_DAY,
    BASE_LORDS_PER_DAY,
    PILLAGE_AMOUNT,
)
from contracts.settling_game.utils.library import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
    MODULE_only_arbiter
)

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.imodules import (
    IModuleController,
    IL01_Settling,
    IL04_Calculator,
    IL05_Wonders,
)

from openzeppelin.upgrades.library import (
    Proxy_initializer,
    Proxy_only_admin,
    Proxy_set_implementation
)

##########
# EVENTS #
# ########

@event
func ResourceUpgraded(token_id : Uint256, building_id : felt, level : felt):
end

###########
# STORAGE #
###########

@storage_var
func resource_levels(token_id : Uint256, resource_id : felt) -> (level : felt):
end

@storage_var
func resource_upgrade_cost(resource_id : felt) -> (cost : Cost):
end

###############
# CONSTRUCTOR #
###############

@external
func initializer{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        address_of_controller : felt,
        proxy_admin : felt
    ):
    MODULE_initializer(address_of_controller)
    Proxy_initializer(proxy_admin)
    return ()
end

@external
func upgrade{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(new_implementation: felt):
    Proxy_only_admin()
    Proxy_set_implementation(new_implementation)
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
    let (wonders_logic_address) = IModuleController.get_module_address(
        controller, ModuleIds.L05_Wonders
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
    let (total_days, remainder) = days_accrued(token_id)

    # CALC VAULT DAYS
    let (total_vault_days, vault_remainder) = get_available_vault_days(token_id)

    # CHECK DAYS + VAULT > 1
    let days = total_days + total_vault_days

    with_attr error_message("RESOURCES: Nothing Claimable."):
        assert_not_zero(days)
    end

    # SET VAULT TIME = REMAINDER - CURRENT_TIME
    IL01_Settling.set_time_staked(settling_logic_address, token_id, remainder)
    IL01_Settling.set_time_vault_staked(settling_logic_address, token_id, vault_remainder)

    # GET WONDER TAX
    let (wonder_tax) = IL04_Calculator.calculate_wonder_tax(calculator_address)
    let (happiness) = IL04_Calculator.calculate_happiness(calculator_address, token_id)

    # SET MINT
    let treasury_mint_perc = wonder_tax
    let user_mint_rel_perc = 100 - wonder_tax

    # GET OUTPUT FOR EACH RESOURCE
    let (r_1_output) = calculate_resource_output(token_id, realms_data.resource_1, happiness)
    let (r_2_output) = calculate_resource_output(token_id, realms_data.resource_2, happiness)
    let (r_3_output) = calculate_resource_output(token_id, realms_data.resource_3, happiness)
    let (r_4_output) = calculate_resource_output(token_id, realms_data.resource_5, happiness)
    let (r_5_output) = calculate_resource_output(token_id, realms_data.resource_5, happiness)
    let (r_6_output) = calculate_resource_output(token_id, realms_data.resource_6, happiness)
    let (r_7_output) = calculate_resource_output(token_id, realms_data.resource_7, happiness)

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
    IL05_Wonders.batch_set_tax_pool(
        wonders_logic_address,
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
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()

    let (combat_address) = IModuleController.get_module_address(
        controller, ModuleIds.L06_Combat
    )

    with_attr error_message("RESOURCES: ONLY COMBAT MODULE CAN CALL"):
        assert caller = combat_address
    end

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

    # SETTLING LOGIC
    let (settling_logic_address) = IModuleController.get_module_address(
        controller, ModuleIds.L01_Settling
    )

    # CALCULATOR
    let (calculator_address) = IModuleController.get_module_address(
        controller, ModuleIds.L04_Calculator
    )

    let (local resource_ids : Uint256*) = alloc()
    let (local user_mint : Uint256*) = alloc()

    # FETCH REALM DATA
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(realms_address, token_id)

    # CALC PILLAGABLE DAYS
    let (total_pillagable_days, pillagable_remainder) = vault_days_accrued(token_id)

    with_attr error_message("RESOURCES: NOTHING TO RAID!"):
        assert_not_zero(total_pillagable_days)
    end

    # SET VAULT TIME = REMAINDER - CURRENT_TIME
    IL01_Settling.set_time_vault_staked(settling_logic_address, token_id, pillagable_remainder)

    # GET HAPPINESS    
    let (happiness) = IL04_Calculator.calculate_happiness(calculator_address, token_id)

    # GET OUTPUT FOR EACH RESOURCE
    let (r_1_output) = calculate_resource_output(token_id, realms_data.resource_1, happiness)
    let (r_2_output) = calculate_resource_output(token_id, realms_data.resource_2, happiness)
    let (r_3_output) = calculate_resource_output(token_id, realms_data.resource_3, happiness)
    let (r_4_output) = calculate_resource_output(token_id, realms_data.resource_5, happiness)
    let (r_5_output) = calculate_resource_output(token_id, realms_data.resource_5, happiness)
    let (r_6_output) = calculate_resource_output(token_id, realms_data.resource_6, happiness)
    let (r_7_output) = calculate_resource_output(token_id, realms_data.resource_7, happiness)

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

@external
func upgrade_resource{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr
}(token_id : Uint256, resource_id : felt) -> ():
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()

    # CONTRACT ADDRESSES
    let (resource_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    )
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms
    )

    # AUTH CHECK
    let (owner) = realms_IERC721.ownerOf(s_realms_address, token_id)
    with_attr error_message("RESOURCES: You do not own this Realm"):
        assert caller = owner
    end

    # GET RESOURCE LEVEL
    let (level) = get_resource_level(token_id, resource_id)

    # GET UPGRADE VALUE
    let (upgrade_cost : Cost) = get_resource_upgrade_cost(resource_id)
    let (costs : Cost*) = alloc()
    assert [costs] = upgrade_cost
    let (token_ids : Uint256*) = alloc()
    let (token_values : Uint256*) = alloc()
    let (token_len : felt) = transform_costs_to_token_ids_values(1, costs, token_ids, token_values)

    # BURN RESOURCES
    IERC1155.burnBatch(resource_address, caller, token_len, token_ids, token_len, token_values)

    # INCREASE LEVEL
    set_resource_level(token_id, resource_id, level + 1)

    # EMIT
    ResourceUpgraded.emit(token_id, resource_id, level + 1)
    return ()
end

###########
# GETTERS #
###########

# FETCHES AVAILABLE RESOURCES PER DAY
@view
func days_accrued{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (days_accrued : felt, remainder : felt):
    let (controller) = MODULE_controller_address()
    let (block_timestamp) = get_block_timestamp()
    let (settling_logic_address) = IModuleController.get_module_address(controller, ModuleIds.L01_Settling)
    
    # GET DAYS ACCRUED
    let (last_update) = IL01_Settling.get_time_staked(settling_logic_address, token_id)
    let (days_accrued, seconds_left_over) = unsigned_div_rem(block_timestamp - last_update, DAY)

    return (days_accrued, seconds_left_over)
end

# CALCS VAULTS DAYS ACCRUED
# USED AS HELPER FUNCTION AND IN PILLAGING
@view
func vault_days_accrued{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (days_accrued : felt, remainder : felt):
    alloc_locals
    let (controller) = MODULE_controller_address()
    let (block_timestamp) = get_block_timestamp()
    let (settling_logic_address) = IModuleController.get_module_address(controller, ModuleIds.L01_Settling)
    
    # GET DAYS ACCRUED
    let (last_update) = IL01_Settling.get_time_vault_staked(settling_logic_address, token_id)
    let (days_accrued, seconds_left_over) = unsigned_div_rem(block_timestamp - last_update, DAY)

    return (days_accrued, seconds_left_over)
end

# FETCHES VAULT DAYS AVAILABLE FOR REALM OWNER ONLY
# ONLY RETURNS VALUE IF DAYS ARE OVER EPOCH LENGTH - SET TO 7 DAY CYCLES
@view
func get_available_vault_days{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(token_id : Uint256) -> (days_accrued : felt, remainder : felt):
    alloc_locals
    let (controller) = MODULE_controller_address()

    # CALC REMAINING DAYS
    let (days_accrued, seconds_left_over) = vault_days_accrued(token_id)

    # returns true if days <= vault_length -1 (we minus 1 so the user can claim when they have 7 days)
    let (less_than) = is_le(days_accrued, VAULT_LENGTH - 1)

    # return no days and no remainder
    if less_than == TRUE:
        return (0, 0)
    end

    # else return days and remainder
    return (days_accrued, seconds_left_over)
end

# CLAIM CHECK
@view
func check_if_claimable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (can_claim : felt):
    alloc_locals

    # FETCH AVAILABLE
    let (days, _) = days_accrued(token_id)
    let (epochs, _) = get_available_vault_days(token_id)

    # ADD 1 TO ALLOW USERS TO CLAIM FULL EPOCH
    let (less_than) = is_le(days + epochs + 1, 1)

    if less_than == TRUE:
        return (FALSE)
    end

    return (TRUE)
end


############
# INTERNAL #
############

# RETURNS RESOURCE OUTPUT
func calculate_resource_output{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, resource_id : felt, happiness : felt
) -> (value : felt):
    alloc_locals

    # GET RESOURCE LEVEL
    let (level) = get_resource_level(token_id, resource_id)

    # HAPPINESS CHECK
    let (production_output, _) = unsigned_div_rem(BASE_RESOURCES_PER_DAY * happiness, 100)

    # IF LEVEL 0 RETURN NO INCREASE
    if level == 0:
        return (production_output)
    end
    return ((level + 1) * production_output)
end

# CALCULATE TOTAL CLAIMABLE
func calculate_total_claimable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, resource_id : felt, days : felt, tax : felt, output : felt
) -> (value : Uint256):
    alloc_locals
    # days * current tax * output
    # we multiply by tax before dividing by 100
    let (total_work_generated, _) = unsigned_div_rem(days * tax * output, 100)
    return (Uint256(total_work_generated, 0))
end

# SET LEVEL
func set_resource_level{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256, resource_id : felt, level : felt) -> ():
    resource_levels.write(token_id, resource_id, level)
    return ()
end

# SET COST
@external
func set_resource_upgrade_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    resource_id : felt, cost : Cost
):
    Proxy_only_admin()
    resource_upgrade_cost.write(resource_id, cost)
    return ()
end

###########
# GETTERS #
###########

# GET RESOURCE LEVEL
@view
func get_resource_level{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, resource : felt
) -> (level : felt):
    let (level) = resource_levels.read(token_id, resource)
    return (level=level)
end

# GET COSTS
@view
func get_resource_upgrade_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    resource_id : felt
) -> (cost : Cost):
    let (cost) = resource_upgrade_cost.read(resource_id)
    return (cost)
end
