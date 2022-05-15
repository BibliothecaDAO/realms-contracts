    # ____MODULE_L08___CRYPTS_RESOURCES_LOGIC
#   Logic to create and issue resources for a given Crypt
#   roughly follows the same patterns as L02_Resources (But for Crypts!)
#
# MIT License
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.utils.game_structs import CryptData, ModuleIds, ExternalContractIds

from contracts.settling_game.utils.constants import (
    TRUE,
    FALSE,
    DAY,
    BASE_RESOURCES_PER_DAY
)
from contracts.settling_game.library.library_module import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
    MODULE_only_arbiter,
    MODULE_ERC721_owner_check
)

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from openzeppelin.token.erc721.interfaces.IERC721 import IERC721
from contracts.settling_game.interfaces.crypts_IERC721 import crypts_IERC721
from contracts.settling_game.interfaces.imodules import (
    IModuleController,
    IL07_Crypts,
    IL04_Calculator         # Needed for calculate_epoch
)

from openzeppelin.upgrades.library import (
    Proxy_initializer,
    Proxy_only_admin,
    Proxy_set_implementation
)

###########
# STORAGE #
###########

@storage_var
func resource_levels(token_id : Uint256, resource_id : felt) -> (level : felt):
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

    # CONTRACT ADDRESSES
    let (crypts_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Crypts
    )
    let (s_crypts_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Crypts
    )
    let (crypts_logic_address) = IModuleController.get_module_address(
        controller, ModuleIds.L07_Crypts
    )
    let (resources_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    )
    let (calculator_address) = IModuleController.get_module_address(
        controller, ModuleIds.L04_Calculator
    )

    # FETCH OWNER
    let (owner) = IERC721.ownerOf(s_crypts_address, token_id)

    # ALLOW RESOURCE LOGIC ADDRESS TO CLAIM, BUT STILL RESTRICT
    if caller != crypts_logic_address:
        # ONLY THE OWNER OF THIS CRYPT CAN CALL THIS FUNCTION DIRECTLY
        MODULE_ERC721_owner_check(token_id, ExternalContractIds.S_Crypts)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        # OR WE CALL IT FROM UNSETTLE (but no other contracts can call it)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    let (local resource_ids : Uint256*) = alloc()
    let (local user_mint : Uint256*) = alloc()

    # FETCH CRYPT DATA
    let (crypts_data : CryptData) = crypts_IERC721.fetch_crypt_data(crypts_address, token_id)

    # CALC DAYS SINCE LAST CLAIM
    let (days, remainder) = days_accrued(token_id)

    with_attr error_message("RESOURCES: Nothing Claimable."):
        assert_not_zero(days)
    end

    # SET STAKED TIME = REMAINDER - CURRENT_TIME
    IL07_Crypts.set_time_staked(crypts_logic_address, token_id, remainder)

    # GET RESOURCE OUTPUT
    let (r_output) = calculate_resource_output(token_id, crypts_data.resource)
    let (r_1_user) = calculate_total_claimable(token_id, crypts_data.resource, days, r_output)

    assert resource_ids[0] = Uint256(crypts_data.resource, 0)
    assert user_mint[0] = r_1_user
    
    # MINT USERS RESOURCES
    IERC1155.mintBatch(
        resources_address,
        owner,
        crypts_data.resource_number,
        resource_ids,
        crypts_data.resource_number,
        user_mint,
    )

    # GET EPOCH
    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)

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

    # AUTH
    MODULE_ERC721_owner_check(token_id, ExternalContractIds.S_Crypts)

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
    let (crypts_logic_address) = IModuleController.get_module_address(controller, ModuleIds.L07_Crypts)
    
    # GET DAYS ACCRUED
    let (last_update) = IL07_Crypts.get_time_staked(crypts_logic_address, token_id)
    let (days_accrued, seconds_left_over) = unsigned_div_rem(block_timestamp - last_update, DAY)

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

    # ADD 1 TO ALLOW USERS TO CLAIM FULL EPOCH
    let (less_than) = is_le(days + 1, 1)

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
    token_id : Uint256, resource_id : felt
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

#########
# ADMIN #
#########

@external
func set_resource_upgrade_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    resource_id : felt, cost : Cost
):
    Proxy_only_admin()
    resource_upgrade_cost.write(resource_id, cost)
    return ()
end
