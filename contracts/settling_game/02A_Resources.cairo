%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.general import scale
from contracts.settling_game.utils.interfaces import IModuleController, I02B_Resources

from contracts.settling_game.utils.game_structs import RealmData, ResourceUpgradeIds
from contracts.settling_game.utils.general import unpack_data

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721



##### Module 2A ##########
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
    let (s_realms_address) = IModuleController.get_s_realms_address(contract_address=controller)
    # resource contract
    let (resources_address) = IModuleController.get_resources_address(contract_address=controller)

    # state contract
    let (resources_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=4)

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

    let (r_1) = I02B_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_1)
    let (r_2) = I02B_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_2)
    let (r_3) = I02B_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_3)
    let (r_4) = I02B_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_4)
    let (r_5) = I02B_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_5)
    let (r_6) = I02B_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_6)
    let (r_7) = I02B_Resources.get_resource_level(
        contract_address=resources_state_address,
        token_id=token_id,
        resource=realms_data.resource_7)

    assert resource_ids[0] = realms_data.resource_1
    assert user_mint[0] = r_1
    assert treasury_mint[0] = r_1

    if realms_data.resource_2 != 0:
        assert resource_ids[1] = realms_data.resource_2
        assert user_mint[1] = r_2
        assert treasury_mint[1] = r_2
    end

    if realms_data.resource_3 != 0:
        assert resource_ids[2] = realms_data.resource_3
        assert user_mint[2] = r_3
        assert treasury_mint[2] = r_3
    end

    if realms_data.resource_4 != 0:
        assert resource_ids[3] = realms_data.resource_4
        assert user_mint[3] = r_4
        assert treasury_mint[3] = r_4
    end

    if realms_data.resource_5 != 0:
        assert resource_ids[4] = realms_data.resource_5
        assert user_mint[4] = r_5
        assert treasury_mint[4] = r_5
    end

    if realms_data.resource_6 != 0:
        assert resource_ids[5] = realms_data.resource_6
        assert user_mint[5] = r_6
        assert treasury_mint[5] = r_6
    end

    if realms_data.resource_7 != 0:
        assert resource_ids[6] = realms_data.resource_7
        assert user_mint[6] = r_7
        assert treasury_mint[6] = r_7
    end

    # # TODO: only allow claim contract to mint

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
func upgrade_resource{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(
        token_id : Uint256, resource : felt, token_ids_len : felt, token_ids : felt*,
        token_values_len : felt, token_values : felt*) -> ():
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()


    # resource contract
    let (resource_address) = IModuleController.get_resources_address(contract_address=controller)
    let (s_realms_address) = IModuleController.get_s_realms_address(contract_address=controller)

    # check owner of sRealm
    let (owner) = realms_IERC721.ownerOf(contract_address=s_realms_address, token_id=token_id)
    assert caller = owner

    # resources state contract
    let (resources_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=4)

    let (level) = I02B_Resources.get_resource_level(resources_state_address, token_id, resource)

    let (upgrade_cost) = I02B_Resources.get_resource_upgrade_cost(
        resources_state_address, token_id, resource)

    let (resource_upgrade_ids : ResourceUpgradeIds) = fetch_resource_upgrade_ids(resource)

    # check correct ids
    if resource_upgrade_ids.resource_1 != token_ids[0]:
        resource_upgrade_ids.resource_1 = resource_upgrade_ids.resource_1 + 1
    end
    if resource_upgrade_ids.resource_2 != token_ids[1]:
        resource_upgrade_ids.resource_2 = resource_upgrade_ids.resource_2 + 1
    end
    if resource_upgrade_ids.resource_3 != token_ids[2]:
        resource_upgrade_ids.resource_3 = resource_upgrade_ids.resource_3 + 1
    end
    if resource_upgrade_ids.resource_4 != token_ids[3]:
        resource_upgrade_ids.resource_4 = resource_upgrade_ids.resource_4 + 1
    end
    if resource_upgrade_ids.resource_5 != token_ids[4]:
        resource_upgrade_ids.resource_5 = resource_upgrade_ids.resource_5 + 1
    end

    # check correct values
    if resource_upgrade_ids.resource_1_values != token_values[0]:
        resource_upgrade_ids.resource_1_values = resource_upgrade_ids.resource_1_values + 1
    end
    if resource_upgrade_ids.resource_2_values != token_values[1]:
        resource_upgrade_ids.resource_2_values = resource_upgrade_ids.resource_2_values + 1
    end
    if resource_upgrade_ids.resource_3_values != token_values[2]:
        resource_upgrade_ids.resource_3_values = resource_upgrade_ids.resource_3_values + 1
    end
    if resource_upgrade_ids.resource_4_values != token_values[3]:
        resource_upgrade_ids.resource_4_values = resource_upgrade_ids.resource_4_values + 1
    end
    if resource_upgrade_ids.resource_5_values != token_values[4]:
        resource_upgrade_ids.resource_5_values = resource_upgrade_ids.resource_5_values + 1
    end

    # create array of ids and values
    let (local resource_ids : felt*) = alloc()

    assert resource_ids[0] = resource_upgrade_ids.resource_1
    assert resource_ids[1] = resource_upgrade_ids.resource_2
    assert resource_ids[2] = resource_upgrade_ids.resource_3
    assert resource_ids[3] = resource_upgrade_ids.resource_4
    assert resource_ids[4] = resource_upgrade_ids.resource_5


    # burn resources
    IERC1155.burn_batch(resource_address, caller, 5, resource_ids, 5, token_values)

    # increase level
    I02B_Resources.set_resource_level(resources_state_address, token_id, resource, level + 1)

    return ()
end

func fetch_resource_upgrade_ids{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(resource_id : felt) -> (resource_ids : ResourceUpgradeIds):
    alloc_locals

    let (controller) = controller_address.read()

    # state contract
    let (resources_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=4)

    let (local data) = I02B_Resources.get_resource_upgrade_ids(resources_state_address, resource_id)

    let (local resource_1) = unpack_data(data, 0, 255)
    let (local resource_2) = unpack_data(data, 8, 255)
    let (local resource_3) = unpack_data(data, 16, 255)
    let (local resource_4) = unpack_data(data, 24, 255)
    let (local resource_5) = unpack_data(data, 32, 255)
    let (local resource_1_values) = unpack_data(data, 40, 255)
    let (local resource_2_values) = unpack_data(data, 48, 255)
    let (local resource_3_values) = unpack_data(data, 56, 255)
    let (local resource_4_values) = unpack_data(data, 64, 255)
    let (local resource_5_values) = unpack_data(data, 72, 255)

    return (resource_ids=ResourceUpgradeIds(
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
