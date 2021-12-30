%lang starknet
%builtins pedersen range_check bitwise
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.pow import pow
from contracts.settling_game.utils.general import scale
from contracts.settling_game.utils.interfaces import IModuleController

from contracts.settling_game.utils.game_structs import ResourceLevel

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155
from contracts.settling_game.realms_IERC721 import realms_IERC721

from contracts.settling_game.utils.game_structs import RealmData, ResourceUpgradeIds
# #### Module 2B #####
# Claim & Resource State
####################

# ########### Game state ############

# Stores the address of the ModuleController.
@storage_var
func controller_address() -> (address : felt):
end

@storage_var
func resource_levels(token_id : Uint256, resource_id : felt) -> (level : felt):
end

@storage_var
func resource_upgrade_cost(token_id : Uint256, resource_id : felt) -> (level : felt):
end

@storage_var
func resource_upgrade_ids(resource_id : felt) -> (ids : felt):
end

# ########### Admin Functions for Testing ############
# Called on deployment only.
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    # Store the address of the only fixed contract in the system.
    controller_address.write(address_of_controller)
    return ()
end

@external
func get_resource_level{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, resource : felt) -> (level : felt):
    alloc_locals

    local l

    let (level) = resource_levels.read(token_id, resource)

    if level == 0:
        assert l = 10
    else:
        assert l = level
    end

    return (level=l)
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
    let (resources_address) = IModuleController.get_resources_address(contract_address=controller)

    let (level) = resource_levels.read(token_id, resource)

    let (upgrade_cost) = resource_upgrade_cost.read(token_id, resource)

    let (resource_upgrade_ids : ResourceUpgradeIds) = fetch_resource_upgrade_ids(resource)

    # check correct ids
    assert resource_upgrade_ids.resource_1 = token_ids[0]
    assert resource_upgrade_ids.resource_2 = token_ids[1]
    assert resource_upgrade_ids.resource_3 = token_ids[2]
    assert resource_upgrade_ids.resource_4 = token_ids[3]
    assert resource_upgrade_ids.resource_5 = token_ids[4]

    # create array of ids and values
    let (local resource_ids : felt*) = alloc()
    let (local resource_values : felt*) = alloc()

    assert resource_ids[0] = resource_upgrade_ids.resource_1
    assert resource_ids[1] = resource_upgrade_ids.resource_2
    assert resource_ids[2] = resource_upgrade_ids.resource_3
    assert resource_ids[3] = resource_upgrade_ids.resource_4
    assert resource_ids[4] = resource_upgrade_ids.resource_5 

    assert resource_values[0] = token_values[0]
    assert resource_values[1] = token_values[1]
    assert resource_values[2] = token_values[2]
    assert resource_values[3] = token_values[3]
    assert resource_values[4] = token_values[4]

    # burn resources
    IERC1155.burn_batch(resources_address, caller, 5, resource_ids, 5, resource_values)

    # increase level
    resource_levels.write(token_id, resource, level + 1)

    return ()
end

func unpack_data{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(resource_id : felt, index : felt) -> (score : felt):
    alloc_locals

    let (local data) = resource_upgrade_ids.read(resource_id)
    local syscall_ptr : felt* = syscall_ptr
    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
    # 1. Create a 4-bit mask at and to the left of the index
    # E.g., 000111100 = 2**2 + 2**3 + 2**4 + 2**5
    # E.g.,  2**(i) + 2**(i+1) + 2**(i+2) + 2**(i+3) = (2**i)(15)
    let (power) = pow(2, index)
    # 1 + 2 + 4 + 8 + 16 + 32 = 15
    let mask = 255 * power

    # 2. Apply mask using bitwise operation: mask AND data.
    let (masked) = bitwise_and(mask, data)

    # 3. Shift element right by dividing by the order of the mask.
    let (result, _) = unsigned_div_rem(masked, power)

    return (score=result)
end

@external
func fetch_resource_upgrade_ids{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(resource_id : felt) -> (resource_ids : ResourceUpgradeIds):
    alloc_locals

    let (local resource_1) = unpack_data(resource_id, 0)
    let (local resource_2) = unpack_data(resource_id, 8)
    let (local resource_3) = unpack_data(resource_id, 16)
    let (local resource_4) = unpack_data(resource_id, 24)
    let (local resource_5) = unpack_data(resource_id, 32)

    let resource_ids = ResourceUpgradeIds(
        resource_1=resource_1,
        resource_2=resource_2,
        resource_3=resource_3,
        resource_4=resource_4,
        resource_5=resource_5)
    return (resource_ids=resource_ids)
end

@external
func set_resource_upgrade_ids{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(resource_id : felt, _resource_upgrade_ids : felt) -> ():
    resource_upgrade_ids.write(resource_id, _resource_upgrade_ids)

    return ()
end
