%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.general import scale
from contracts.settling_game.utils.game_structs import ModuleIds
from contracts.settling_game.utils.constants import TRUE, FALSE

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721
from contracts.settling_game.interfaces.imodules import IModuleController, IS01_Settling

from contracts.settling_game.utils.library import (
    MODULE_controller_address, MODULE_only_approved, MODULE_initializer)

# ____MODULE_L01___SETTLING_LOGIC

##########
# EVENTS #
##########

@event
func Settled(owner : felt, token_id : Uint256):
end

@event
func UnSettled(owner : felt, token_id : Uint256):
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

############
# EXTERNAL #
############

# SETTLES REALM
@external
func settle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (success : felt):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()

    let (realms_address) = IModuleController.get_realms_address(contract_address=controller)

    let (s_realms_address) = IModuleController.get_s_realms_address(contract_address=controller)

    let (settle_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S01_Settling)

    # TRANSFER REALM
    realms_IERC721.transferFrom(realms_address, caller, settle_state_address, token_id)

    # MINT S_REALM
    s_realms_IERC721.mint(s_realms_address, caller, token_id)

    # PASS 0 to set the current time
    IS01_Settling.set_time_staked(settle_state_address, token_id, 0)

    # EMIT
    Settled.emit(caller, token_id)

    # RETURN 1 (TRUE)
    return (TRUE)
end

# UNSETTLES REALM
@external
func unsettle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (success : felt):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()
    let (block_timestamp) = get_block_timestamp()

    let (realms_address) = IModuleController.get_realms_address(contract_address=controller)
    let (s_realms_address) = IModuleController.get_s_realms_address(contract_address=controller)
    let (settle_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S01_Settling)

    # TRANSFER REALM BACK TO OWNER
    realms_IERC721.transferFrom(realms_address, settle_state_address, caller, token_id)

    # BURN S_REALM
    s_realms_IERC721.burn(s_realms_address, token_id)

    # TODO: TimeStamp - current Hardcoded
    # PASS 0 to set the current time
    IS01_Settling.set_time_staked(settle_state_address, token_id, 0)

    # TOD0: Claim resources if available before unsettling

    # EMIT
    UnSettled.emit(caller, token_id)

    # RETURN 1 (TRUE)
    return (TRUE)
end
