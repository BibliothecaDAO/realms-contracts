%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le, is_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.game_structs import (
    RealmData, ResourceUpgradeValues, ModuleIds, ExternalContractIds)
from contracts.settling_game.utils.general import scale, unpack_data
from contracts.settling_game.utils.constants import (
    TRUE, FALSE, VAULT_LENGTH, DAY, VAULT_LENGTH_SECONDS, BASE_RESOURCES_PER_DAY,
    BASE_LORDS_PER_DAY)
from contracts.settling_game.utils.library import (
    MODULE_controller_address, MODULE_only_approved, MODULE_initializer)

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.IStorage import IStorage
from contracts.settling_game.interfaces.imodules import (
    IModuleController, IS02_Resources, IS01_Settling, IL04_Calculator, IS05_Wonders)

# ____MODULE_L02___RESOURCES_LOGIC

##########
# EVENTS #
##########

@event
func ResourceUpgraded(token_id : Uint256, building_id : felt, level : felt):
end

###############
# CONSTRUCTOR #
###############
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    MODULE_initializer(address_of_controller)
    return ()
end

############
# EXTERNAL #
############

@external
func claim_resources{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()

    # lords contract
    let (lords_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Lords)

    # realms contract
    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms)

    # sRealms contract
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms)

    # resource contract
    let (resources_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources)

    # state contract
    let (resources_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S02_Resources)

    # settling state contract
    let (settling_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S01_Settling)

    # calculator logic contract
    let (calculator_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L04_Calculator)

    # treasury address
    let (treasury_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Treasury)

    # wonder tax pool address
    let (wonders_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S05_Wonders)

    # check owner of sRealm
    let (owner) = realms_IERC721.ownerOf(contract_address=s_realms_address, token_id=token_id)
    assert caller = owner

    let (local resource_ids : Uint256*) = alloc()
    let (local user_mint : Uint256*) = alloc()
    let (local wonder_tax_arr : Uint256*) = alloc()

    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(
        contract_address=realms_address, token_id=token_id)

    let (r_1) = calculate_resource_output(token_id, realms_data.resource_1)
    let (r_2) = calculate_resource_output(token_id, realms_data.resource_2)
    let (r_3) = calculate_resource_output(token_id, realms_data.resource_3)
    let (r_4) = calculate_resource_output(token_id, realms_data.resource_5)
    let (r_5) = calculate_resource_output(token_id, realms_data.resource_5)
    let (r_6) = calculate_resource_output(token_id, realms_data.resource_6)
    let (r_7) = calculate_resource_output(token_id, realms_data.resource_7)

    # calculate days
    let (total_days, remainder) = get_available_resources(token_id)

    # calculate vault days
    let (total_vault_days, vault_remainder) = get_available_vault_resources(token_id)

    # check vault days + days greater than zero
    let days = total_days + total_vault_days
    assert_not_zero(days)

    IS01_Settling.set_time_staked(settling_state_address, token_id, remainder)

    # get wonder tax percentage
    let (wonder_tax) = IL04_Calculator.calculate_wonder_tax(contract_address=calculator_address)
    let (wonder_tax_rel_perc, _) = unsigned_div_rem(wonder_tax, 100)

    # set minting percentages
    let treasury_mint_perc = wonder_tax_rel_perc
    let user_mint_rel_perc = 100 - wonder_tax_rel_perc

    let (user_resource_factor, _) = unsigned_div_rem(
        days * user_mint_rel_perc, BASE_RESOURCES_PER_DAY)
    let (wonder_tax_resource_factor, _) = unsigned_div_rem(
        days * treasury_mint_perc, BASE_RESOURCES_PER_DAY)

    # current
    assert resource_ids[0] = Uint256(realms_data.resource_1, 0)
    assert user_mint[0] = Uint256(r_1 * user_resource_factor, 0)
    assert wonder_tax_arr[0] = Uint256(r_1 * wonder_tax_resource_factor, 0)

    if realms_data.resource_2 != 0:
        assert resource_ids[1] = Uint256(realms_data.resource_2, 0)
        assert user_mint[1] = Uint256(r_2 * user_resource_factor, 0)
        assert wonder_tax_arr[1] = Uint256(r_2 * wonder_tax_resource_factor, 0)
    end

    if realms_data.resource_3 != 0:
        assert resource_ids[2] = Uint256(realms_data.resource_3, 0)
        assert user_mint[2] = Uint256(r_3 * user_resource_factor, 0)
        assert wonder_tax_arr[2] = Uint256(r_3 * wonder_tax_resource_factor, 0)
    end

    if realms_data.resource_4 != 0:
        assert resource_ids[3] = Uint256(realms_data.resource_4, 0)
        assert user_mint[3] = Uint256(r_4 * user_resource_factor, 0)
        assert wonder_tax_arr[3] = Uint256(r_4 * wonder_tax_resource_factor, 0)
    end

    if realms_data.resource_5 != 0:
        assert resource_ids[4] = Uint256(realms_data.resource_5, 0)
        assert user_mint[4] = Uint256(r_5 * user_resource_factor, 0)
        assert wonder_tax_arr[4] = Uint256(r_5 * wonder_tax_resource_factor, 0)
    end

    if realms_data.resource_6 != 0:
        assert resource_ids[5] = Uint256(realms_data.resource_7, 0)
        assert user_mint[5] = Uint256(r_6 * user_resource_factor, 0)
        assert wonder_tax_arr[5] = Uint256(r_6 * wonder_tax_resource_factor, 0)
    end

    if realms_data.resource_7 != 0:
        assert resource_ids[6] = Uint256(realms_data.resource_7, 0)
        assert user_mint[6] = Uint256(r_7 * user_resource_factor, 0)
        assert wonder_tax_arr[6] = Uint256(r_7 * wonder_tax_resource_factor, 0)
    end

    # LORDS MINT
    let lords_available = Uint256(total_days * BASE_LORDS_PER_DAY, 0)

    # TODO: CAN WE IMPROVE THE GAS OF THIS??

    # approve lords
    # IERC20.approve(lords_address, treasury_address, lords_available)

    # mint lords
    IERC20.transferFrom(lords_address, treasury_address, caller, lords_available)

    # TODO: ONLY ALLOW THIS MODULE TO MINT FROM RESOURCE CONTRACT

    # mint users
    IERC1155.mintBatch(
        resources_address,
        caller,
        realms_data.resource_number,
        resource_ids,
        realms_data.resource_number,
        user_mint)

    # update wonder tax pool
    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)

    IS05_Wonders.batch_set_tax_pool(
        wonders_state_address,
        current_epoch,
        realms_data.resource_number,
        resource_ids,
        realms_data.resource_number,
        wonder_tax_arr)

    return ()
end

###########
# GETTERS #
###########

@view
func get_available_resources{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (days_accrued : felt, remainder : felt):
    let (controller) = MODULE_controller_address()

    let (settling_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S01_Settling)

    let (last_update) = IS01_Settling.get_time_staked(settling_state_address, token_id)

    let (block_timestamp) = get_block_timestamp()

    let (days_accrued, seconds_left_over) = unsigned_div_rem(block_timestamp - last_update, DAY)

    return (days_accrued, seconds_left_over)
end

@view
func get_available_vault_resources{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token_id : Uint256) -> (
        days_accrued : felt, remainder : felt):
    alloc_locals
    let (controller) = MODULE_controller_address()

    let (settling_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S01_Settling)

    let (block_timestamp) = get_block_timestamp()

    let (last_update) = IS01_Settling.get_time_vault_staked(settling_state_address, token_id)

    # calc days remaining
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

@view
func check_if_claimable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (can_claim : felt):
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
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(token_id : Uint256, resource_id : felt) -> ():
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()

    # resource contract
    let (resource_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources)

    # sRealms contract
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms)

    # check owner of sRealm
    let (owner) = realms_IERC721.ownerOf(contract_address=s_realms_address, token_id=token_id)

    with_attr error_message("You do not own this Realm"):
        assert caller = owner
    end

    # STATE
    let (resources_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S02_Resources)

    # GET RESOURCE LEVEL
    let (level) = IS02_Resources.get_resource_level(resources_state_address, token_id, resource_id)

    # GET UPGRADE VALUE
    let (resource_upgrade_value : ResourceUpgradeValues) = fetch_resource_upgrade_values(
        resource_id)

    # CREATE TEMP ARRARY
    let (resource_ids : Uint256*) = alloc()
    let (resource_values : Uint256*) = alloc()

    assert resource_ids[0] = Uint256(resource_upgrade_value.resource_1, 0)
    assert resource_ids[1] = Uint256(resource_upgrade_value.resource_2, 0)
    assert resource_ids[2] = Uint256(resource_upgrade_value.resource_3, 0)
    assert resource_ids[3] = Uint256(resource_upgrade_value.resource_4, 0)
    assert resource_ids[4] = Uint256(resource_upgrade_value.resource_5, 0)

    assert resource_values[0] = Uint256(resource_upgrade_value.resource_1_values, 0)
    assert resource_values[1] = Uint256(resource_upgrade_value.resource_2_values, 0)
    assert resource_values[2] = Uint256(resource_upgrade_value.resource_3_values, 0)
    assert resource_values[3] = Uint256(resource_upgrade_value.resource_4_values, 0)
    assert resource_values[4] = Uint256(resource_upgrade_value.resource_5_values, 0)

    # BURN RESOURCES
    IERC1155.burnBatch(resource_address, caller, 5, resource_ids, 5, resource_values)

    # INCREASE LEVEL
    IS02_Resources.set_resource_level(resources_state_address, token_id, resource_id, level + 1)

    # EMIT
    ResourceUpgraded.emit(token_id, resource_id, level + 1)
    return ()
end

func fetch_resource_upgrade_values{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(resource_id : felt) -> (
        resource_values : ResourceUpgradeValues):
    alloc_locals

    let (controller) = MODULE_controller_address()

    # STATE
    let (storage_db_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Storage)

    let (data) = IStorage.get_resource_upgrade_value(storage_db_address, resource_id)

    let (resource_1) = unpack_data(data, 0, 255)
    let (resource_2) = unpack_data(data, 8, 255)
    let (resource_3) = unpack_data(data, 16, 255)
    let (resource_4) = unpack_data(data, 24, 255)
    let (resource_5) = unpack_data(data, 32, 255)
    let (resource_1_values) = unpack_data(data, 40, 255)
    let (resource_2_values) = unpack_data(data, 48, 255)
    let (resource_3_values) = unpack_data(data, 56, 255)
    let (resource_4_values) = unpack_data(data, 64, 255)
    let (resource_5_values) = unpack_data(data, 72, 255)

    # TODO: ADD IN DYNAMIC COST ACCORDING TO RESOURCE LEVEL
    return (
        resource_values=ResourceUpgradeValues(
        resource_1,
        resource_2,
        resource_3,
        resource_4,
        resource_5,
        resource_1_values,
        resource_2_values,
        resource_3_values,
        resource_4_values,
        resource_5_values))
end

func calculate_resource_level_cost{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, resource_id : felt, resource_value : felt) -> (value : felt):
    let (controller) = MODULE_controller_address()

    # STATE
    let (resources_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S02_Resources)

    # GET RESOURCE LEVEL
    let (level) = IS02_Resources.get_resource_level(resources_state_address, token_id, resource_id)

    # CALC
    let value = level * resource_value

    return (value)
end

func calculate_resource_output{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, resource_id : felt) -> (value : felt):
    alloc_locals
    let (controller) = MODULE_controller_address()

    # STATE
    let (resources_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S02_Resources)

    # GET RESOURCE LEVEL
    let (level) = IS02_Resources.get_resource_level(resources_state_address, token_id, resource_id)

    local l
    # CALC
    if level == 0:
        return (BASE_RESOURCES_PER_DAY)
    end
    return (level * BASE_RESOURCES_PER_DAY)
end
