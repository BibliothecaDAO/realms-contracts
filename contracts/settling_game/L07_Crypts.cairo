%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (
    get_caller_address, get_block_timestamp, get_contract_address)
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds, RealmData
from contracts.settling_game.utils.constants import TRUE, FALSE
from contracts.settling_game.utils.library import (
    MODULE_controller_address, MODULE_only_approved, MODULE_initializer)

from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721
from contracts.settling_game.interfaces.imodules import (
    IModuleController, IS01_Settling, IL05_Wonders, IL02_Resources)

# TODO:
# Refactor this file to take into account the Crypts contracts. This will mostly be just chaning contract address
# Create Crypts Struct to conform with the Crypts Metadata (game_structs.cairo)
# Refactor unpacking of crypts data witin the Crypts_ERC721_Mintable.cairo to enable fetching of information
# Add module to Module controller and add extra module params to Arbiter
# Add functions to L02_Resources.cairo to calculate the length of the stake (!!where can we double both crypts and realms functions to keep it DRY)

# ____MODULE_L07___CRYPTS_LOGIC

##########
# EVENTS #
##########

# Staked = unlocked (because Lore ofc)
@event
func Unlocked(owner : felt, token_id : Uint256):
end

@event
func Locked(owner : felt, token_id : Uint256):
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


# SETTLES CRYPTS
@external
func unlock_crypt{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (success : felt):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()
    let (contract_address) = get_contract_address()

    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms)
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms)

    let (settle_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S01_Settling)

    # TRANSFER REALM
    realms_IERC721.transferFrom(realms_address, caller, settle_state_address, token_id)

    # MINT S_REALM
    s_realms_IERC721.mint(s_realms_address, caller, token_id)

    # PASS 0 to set the current time
    IS01_Settling.set_time_staked(settle_state_address, token_id, 0)
    IS01_Settling.set_time_vault_staked(settle_state_address, token_id, 0)

    # UPDATE SETTLED REALMS COUNTER
    let (realms_settled) = IS01_Settling.get_total_realms_settled(
        contract_address=settle_state_address)
    IS01_Settling.set_total_realms_settled(settle_state_address, realms_settled + 1)

    # UPDATE OTHER MODULES
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(
        contract_address=realms_address, token_id=token_id)

    # EMIT
    Unlocked.emit(caller, token_id)
    # RETURN 1 (TRUE)
    return (TRUE)
end

# UNSETTLES REALM
@external
func lock_crypt{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (success : felt):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()
    let (block_timestamp) = get_block_timestamp()

   # FETCH ADDRESSES
    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms)
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms)
    let (settle_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S01_Settling)
    let (resource_logic_address) = IModuleController.get_module_address(
        controller, ModuleIds.L02_Resources)

    # TRANSFER REALM BACK TO OWNER
    realms_IERC721.transferFrom(realms_address, settle_state_address, caller, token_id)

    # BURN S_REALM
    s_realms_IERC721.burn(s_realms_address, token_id)

    # TODO: TimeStamp - current Hardcoded
    # PASS 0 to set the current time
    IS01_Settling.set_time_staked(settle_state_address, token_id, 0)
    IS01_Settling.set_time_vault_staked(settle_state_address, token_id, 0)

    # TOD0: Claim resources if available before unsettling

    # UPDATE SETTLED REALMS COUNTER
    let (realms_settled) = IS01_Settling.get_total_realms_settled(
        contract_address=settle_state_address)
    IS01_Settling.set_total_realms_settled(settle_state_address, realms_settled - 1)

    # UPDATE OTHER MODULES
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(
        contract_address=realms_address, token_id=token_id)

    # EMIT
    Locked.emit(caller, token_id)
    # RETURN 1 (TRUE)
    return (TRUE)
end
