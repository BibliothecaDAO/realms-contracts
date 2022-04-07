%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.dict import dict_write, dict_read
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.interfaces.imodules import IModuleController
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721

from contracts.settling_game.utils.library import (
    MODULE_controller_address, MODULE_only_approved, MODULE_initializer)

from contracts.settling_game.utils.constants import TRUE, FALSE

# NOTES:
# Remove redundent methods
# See what module functions could be shared with future modules and realms modules. We could MODULE these

# ___MODULE_S07___CRYPTS_STATE

##########
# EVENTS #
##########

# STAKE TIME - THIS IS USED AS THE MAIN IDENTIFIER FOR STAKING TIME.
# IT IS UPDATED ON RESOURCE CLAIM, STAKE, UNSTAKE
@storage_var
func time_staked(token_id : Uint256) -> (time : felt):
end

# VESTING TIME - 7 DAYS
# THIS IS THE STORAGE VAR FOR THE VAULT
# THE VAULT STORES THE VESTED RESOURCES, IT CAN ONLY BE ACCESS WHEN A FULL EPOCH WORTH IS AVAILABLE
# THIS IS CURRENTLY SET AT 7 DAYS
@storage_var
func time_vault_staked(token_id : Uint256) -> (time : felt):
end

@storage_var
func total_realms_settled() -> (amount : felt):
end

###############
# CONSTRUCTOR #
###############

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    # Store the address of the only fixed contract in the system.
    MODULE_initializer(address_of_controller)
    return ()
end

###########
# SETTERS #
###########
# ## VARS ###
# TIME_LEFT -> WHEN PLAYER CLAIMS, THIS IS THE REMAINDER TO BE PASSED BACK INTO STORAGE
# THIS ALLOWS FULL DAYS TO BE CLAIMED ONLY AND ALLOWS LESS THAN FULL DAYS TO CONTINUE ACCRUREING
@external
func set_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, time_left : felt):
    MODULE_only_approved()

    let (block_timestamp) = get_block_timestamp()

    # SETS CURRENT TIME
    time_staked.write(token_id, block_timestamp - time_left)
    return ()
end

# VAULT_TIME_LEFT -> WHEN PLAYER CLAIMS, THIS IS THE REMAINDER TO BE PASSED BACK INTO STORAGE
# THIS ALLOWS FULL 7 DAYS TO BE CLAIMED ONLY AND ALLOWS LESS THAN FULL DAYS TO CONTINUE ACCRUREING
@external
func set_time_vault_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, time_left : felt):
    MODULE_only_approved()

    let (block_timestamp) = get_block_timestamp()

    # SETS CURRENT TIME
    time_vault_staked.write(token_id, block_timestamp - time_left)
    return ()
end

@external
func set_total_realms_settled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        amount : felt):
    MODULE_only_approved()

    total_realms_settled.write(amount)
    return ()
end

###########
# GETTERS #
###########

@view
func get_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (time : felt):
    let (time) = time_staked.read(token_id)

    return (time=time)
end