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
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721

from contracts.settling_game.utils.game_structs import RealmData, ResourceUpgradeIds
from contracts.settling_game.utils.general import unpack_data 


##### Module 2B ##########
#                        #
# Claim & Resource State #
#                        #
##########################

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


@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):

    controller_address.write(address_of_controller)
    return () 
end



###### SETTERS ######

@external
func set_resource_upgrade_ids{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(resource_id : felt, _resource_upgrade_ids : felt) -> ():
    resource_upgrade_ids.write(resource_id, _resource_upgrade_ids)

    return ()
end

@external
func set_resource_level{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(token_id : Uint256, resource_id : felt, level : felt) -> ():
    only_approved()
    resource_levels.write(token_id, resource_id, level)

    return ()
end

###### GETTERS ######

@external
func get_resource_level{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, resource : felt) -> (level : felt):
    alloc_locals

    local l

    let (level) = resource_levels.read(token_id, resource)

    if level == 0:
        assert l = 100
    else:
        assert l = level
    end

    return (level=l)
end

@external
func get_resource_upgrade_cost{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(token_id : Uint256, resource_id : felt) -> (level : felt):
    let (data) = resource_upgrade_cost.read(token_id, resource_id)

    return (level=data) 
end

@external
func get_resource_upgrade_ids{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(resource_id : felt) -> (level : felt):
    let (data) = resource_upgrade_ids.read(resource_id)

    return (level=data) 
end


# Checks write-permission of the calling contract.
func only_approved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    # Get the address of the module trying to write to this contract.
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()
    # Pass this address on to the ModuleController.
    # "Does this address have write-authority here?"
    # Will revert the transaction if not.
    IModuleController.has_write_access(
        contract_address=controller, address_attempting_to_write=caller)
    return ()
end
