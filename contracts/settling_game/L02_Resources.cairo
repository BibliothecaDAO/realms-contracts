%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.game_structs import RealmData, ResourceUpgradeIds, ModuleIds
from contracts.settling_game.utils.general import scale, unpack_data

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.imodules import (
    IModuleController, IS02_Resources, IS01_Settling)

# #### Module 2A ##########
#                        #
# Claim & Resource Logic #
#                        #
##########################

@storage_var
func controller_address() -> (address : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    controller_address.write(address_of_controller)
    return ()
end

# Claims Resources
# Checks user owns sRealm of Realm
# Claims resources allocated
@external
func claim_resources{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()

    # realms contract
    let (realms_address) = IModuleController.get_realms_address(contract_address=controller)

    # sRealms contract
    let (s_realms_address) = IModuleController.get_s_realms_address(contract_address=controller)

    # resource contract
    let (resources_address) = IModuleController.get_resources_address(contract_address=controller)

    # state contract
    let (resources_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S02_Resources)

    # settling state contract
    let (settling_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S01_Settling)

    # treasury address
    let (treasury_address) = IModuleController.get_treasury_address(contract_address=controller)

    # check owner of sRealm
    let (owner) = realms_IERC721.ownerOf(contract_address=s_realms_address, token_id=token_id)
    assert caller = owner

    let (local resource_ids : felt*) = alloc()
    let (local user_mint : felt*) = alloc()
    let (local treasury_mint : felt*) = alloc()

    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(
        contract_address=realms_address, token_id=token_id)

    let (r_1) = IS02_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_1)
    let (r_2) = IS02_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_2)
    let (r_3) = IS02_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_3)
    let (r_4) = IS02_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_5)
    let (r_5) = IS02_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_5)
    let (r_6) = IS02_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_6)
    let (r_7) = IS02_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_7)

    # # TODO: only allow claim contract to mint
    # get time staked
    let (time_staked) = IS01_Settling.get_time_staked(settling_state_address, token_id)

    # calculate days
    let (days) = getAvailableResources(time_staked)

    # check days greater than zero
    assert_not_zero(days)

    # TODO: change to safemath functions
    assert resource_ids[0] = realms_data.resource_1
    assert user_mint[0] = ((r_1 * days) * 80) / 100
    assert treasury_mint[0] = ((r_1 * days) * 20) / 100

    if realms_data.resource_2 != 0:
        assert resource_ids[1] = realms_data.resource_2
        assert user_mint[1] = ((r_2 * days) * 80) / 100
        assert treasury_mint[1] = ((r_2 * days) * 20) / 100
    end

    if realms_data.resource_3 != 0:
        assert resource_ids[2] = realms_data.resource_3
        assert user_mint[2] = ((r_3 * days) * 80) / 100
        assert treasury_mint[2] = ((r_3 * days) * 20) / 100
    end

    if realms_data.resource_4 != 0:
        assert resource_ids[3] = realms_data.resource_4
        assert user_mint[3] = ((r_4 * days) * 80) / 100
        assert treasury_mint[3] = ((r_4 * days) * 20) / 100
    end

    if realms_data.resource_5 != 0:
        assert resource_ids[4] = realms_data.resource_5
        assert user_mint[4] = ((r_5 * days) * 80) / 100
        assert treasury_mint[4] = ((r_5 * days) * 20) / 100
    end

    if realms_data.resource_6 != 0:
        assert resource_ids[5] = realms_data.resource_7
        assert user_mint[5] = ((r_6 * days) * 80) / 100
        assert treasury_mint[5] = ((r_6 * days) * 20) / 100
    end

    if realms_data.resource_7 != 0:
        assert resource_ids[6] = realms_data.resource_7
        assert user_mint[6] = ((r_7 * days) * 80) / 100
        assert treasury_mint[6] = ((r_7 * days) * 20) / 100
    end

    # mint users
    IERC1155.mint_batch(
        resources_address,
        caller,
        realms_data.resource_number,
        resource_ids,
        realms_data.resource_number,
        user_mint)

    # mint treasury
    IERC1155.mint_batch(
        resources_address,
        treasury_address,
        realms_data.resource_number,
        resource_ids,
        realms_data.resource_number,
        treasury_mint)

    return ()
end

@external
func getAvailableResources{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        last_update : felt) -> (time : felt):
    let (block_timestamp) = get_block_timestamp()
    # Real line commented out for testing
    # let days = (block_timestamp - last_update) / 3600

    # dummy numbers as no blocktime on local machine
    # this will equal 24 days uncollected

    # TODO: Return unclaimed time back to felt
    let days = (86400 - 3600) / 3600

    return (time=days)
end

@external
func upgrade_resource{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(token_id : Uint256, resource : felt) -> ():
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()

    # resource contract
    let (resource_address) = IModuleController.get_resources_address(contract_address=controller)

    # sRealms contract
    let (s_realms_address) = IModuleController.get_s_realms_address(contract_address=controller)

    # check owner of sRealm
    let (owner) = realms_IERC721.ownerOf(contract_address=s_realms_address, token_id=token_id)

    with_attr error_message("You do not own this Realm"):
        assert caller = owner
    end

    # STATE
    let (resources_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S02_Resources)

    # GET RESOURCE LEVEL
    let (level) = IS02_Resources.get_resource_level(resources_state_address, token_id, resource)

    # GET UPGRADE COSTS
    let (upgrade_cost) = IS02_Resources.get_resource_upgrade_cost(
        resources_state_address, token_id, resource)

    # GET UPGRADE IDS
    let (resource_upgrade_ids : ResourceUpgradeIds) = fetch_resource_upgrade_ids(resource)

    # CREATE TEMP ARRARY
    let (resource_ids : felt*) = alloc()
    let (resource_values : felt*) = alloc()

    resource_ids[0] = resource_upgrade_ids.resource_1
    resource_ids[1] = resource_upgrade_ids.resource_2
    resource_ids[2] = resource_upgrade_ids.resource_3
    resource_ids[3] = resource_upgrade_ids.resource_4
    resource_ids[4] = resource_upgrade_ids.resource_5

    resource_values[0] = resource_upgrade_ids.resource_1_values
    resource_values[1] = resource_upgrade_ids.resource_2_values
    resource_values[2] = resource_upgrade_ids.resource_3_values
    resource_values[3] = resource_upgrade_ids.resource_4_values
    resource_values[4] = resource_upgrade_ids.resource_5_values

    # BURN RESOURCES
    IERC1155.burn_batch(resource_address, caller, 5, resource_ids, 5, resource_values)

    # INCREASE LEVEL
    IS02_Resources.set_resource_level(resources_state_address, token_id, resource, level + 1)

    return ()
end

@external
func fetch_resource_upgrade_ids{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(resource_id : felt) -> (resource_ids : ResourceUpgradeIds):
    alloc_locals

    let (controller) = controller_address.read()

    # STATE
    let (resources_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=4)

    let (data) = IS02_Resources.get_resource_upgrade_value(resources_state_address, resource_id)

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
        resource_ids=ResourceUpgradeIds(
        resource_1=resource_1,
        resource_2=resource_2,
        resource_3=resource_3,
        resource_4=resource_4,
        resource_5=resource_5,
        resource_1_values=resource_1_values,
        resource_2_values=resource_2_values,
        resource_3_values=resource_3_values,
        resource_4_values=resource_4_values,
        resource_5_values=resource_5_values))
end
