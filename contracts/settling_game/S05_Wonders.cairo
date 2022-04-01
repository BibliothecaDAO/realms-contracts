%lang starknet

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
from contracts.settling_game.interfaces.imodules import IModuleController

from contracts.settling_game.utils.game_structs import ResourceLevel

from contracts.token.ERC20.interfaces.IERC20 import IERC20
from contracts.token.ERC1155.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721

from contracts.settling_game.utils.game_structs import RealmData
from contracts.settling_game.utils.general import unpack_data

from contracts.settling_game.utils.library import (
    MODULE_only_approved, MODULE_initializer)

# #### Module S05 ##########
#                        #
# Wonders Pool State     #
#                        #
##########################

@storage_var
func epoch_claimed(address : felt) -> (epoch : felt):
end

@storage_var
func total_wonders_staked(epoch : felt) -> (amount : felt):
end

@storage_var
func last_updated_epoch() -> (epoch : felt):
end

@storage_var
func wonder_id_staked(token_id : Uint256) -> (epoch : felt):
end

@storage_var
func wonder_epoch_upkeep(epoch : felt, token_id : Uint256) -> (upkept : felt):
end

@storage_var
func tax_pool(epoch : felt, resource_id : felt) -> (supply : felt):
end 


@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    MODULE_initializer(address_of_controller)
    return ()
end

# ##### SETTERS ######
@external
func set_total_wonders_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, amount : felt):
    MODULE_only_approved()

    total_wonders_staked.write(epoch, amount)
    return ()
end

@external
func set_last_updated_epoch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt):
    MODULE_only_approved()

    last_updated_epoch.write(epoch)
    return ()
end

@external
func set_wonder_id_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, epoch : felt):
    MODULE_only_approved()

    wonder_id_staked.write(token_id, epoch)
    return ()
end

@external
func set_wonder_epoch_upkeep{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, token_id : Uint256, upkept : felt):
    MODULE_only_approved()

    wonder_epoch_upkeep.write(epoch, token_id, upkept)
    return ()
end

@external
func set_tax_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, resource_id : felt, amount : felt):
    MODULE_only_approved()

    tax_pool.write(epoch, resource_id, amount)
    return ()
end

@external
func batch_set_tax_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt,
        resource_ids_len : felt, 
        resource_ids : felt*,
        amounts_len : felt,
        amounts : felt*):
    alloc_locals    
    MODULE_only_approved()
    # Update tax pool
    if resource_ids_len == 0:
        return ()
    end
    let ( tax_pool ) = get_tax_pool(epoch, [resource_ids])
    set_tax_pool(epoch, [resource_ids], tax_pool + [amounts])

    # Recurse
    return batch_set_tax_pool(
        epoch=epoch,
        resource_ids_len=resource_ids_len - 1,
        resource_ids=resource_ids + 1,
        amounts_len=amounts_len - 1,
        amounts=amounts + 1)
end

# ##### GETTERS ######
@view
func get_total_wonders_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    epoch : felt) -> (amount : felt):

    let (amount) = total_wonders_staked.read(epoch)

    return (amount=amount)
end

@view
func get_last_updated_epoch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (epoch : felt):
    let (epoch) = last_updated_epoch.read()

    return (epoch=epoch)
end

@view
func get_wonder_id_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256) -> (epoch : felt):

    let (epoch) = wonder_id_staked.read(token_id)

    return (epoch=epoch)
end

@view
func get_wonder_epoch_upkeep{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    epoch : felt, token_id : Uint256) -> (upkept : felt):

    let (upkept) = wonder_epoch_upkeep.read(epoch, token_id)

    return (upkept=upkept)
end

@view
func get_tax_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    epoch : felt, resource_id : felt) -> (supply : felt):

    let (supply) = tax_pool.read(epoch, resource_id)

    return (supply)
end