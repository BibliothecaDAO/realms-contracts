%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (
    get_caller_address, get_block_timestamp, get_contract_address)
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds, CryptData
from contracts.settling_game.utils.constants import TRUE, FALSE
from contracts.settling_game.utils.library import (
    MODULE_controller_address, MODULE_only_approved, MODULE_initializer)

from contracts.settling_game.interfaces.crypts_IERC721 import crypts_IERC721
from contracts.settling_game.interfaces.s_crypts_IERC721 import s_crypts_IERC721
from contracts.settling_game.interfaces.imodules import (
    IModuleController, IS07_Crypts, IL02_Resources)

# TODO:
# ~~Refactor this file to take into account the Crypts contracts. This will mostly be just chaning contract address~~
# Create Crypts Struct to conform with the Crypts Metadata (game_structs.cairo)
# Refactor unpacking of crypts data witin the Crypts_ERC721_Mintable.cairo to enable fetching of information
# Add module to Module controller and add extra module params to Arbiter
# Add functions to L02_Resources.cairo to calculate the length of the stake (!!where can we double both crypts and realms functions to keep it DRY)

# ____MODULE_L07___CRYPTS_LOGIC

##########
# EVENTS #
##########

# Staked = 🗝️ unlocked
# Unstaked = 🔒 locked (because Lore ofc)

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


# STAKE - UNLOCKS CRYPT
@external
func unlock_crypt{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (success : felt):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()
    let (contract_address) = get_contract_address()

    let (crypts_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Crypts)
    let (s_crypts_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Crypts)
                
    let (crypts_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S07_Crypts)
    let (resource_logic_address) = IModuleController.get_module_address(
    controller, ModuleIds.L02_Resources)

    # TRANSFER CRYPT TO STAKING WALLET
    # Crypt will be locked (on starknet and mainnet) until a user unstakes.
    crypts_IERC721.transferFrom(crypts_address, caller, crypts_state_address, token_id)

    # MINT S_CRYPT IN USER'S WALLET
    # S_CRYPT is a token that lives in a user's wallet and represents ownership of a staked crypt.
    # When the crypt is unstaked, the S_CRYPT will be burned.
    s_crypts_IERC721.mint(s_crypts_address, caller, token_id)

    # PASS 0 to set the current time
    IS07_Crypts.set_time_staked(crypts_state_address, token_id, 0)

    # UPDATE UNLOCKED CRYPTS COUNTER
    let (crypts_unlocked) = IS07_Crypts.get_total_crypts_unlocked( 
        contract_address=crypts_state_address)
    IS07_Crypts.set_total_crypts_unlocked(crypts_state_address, crypts_unlocked + 1)

    # UPDATE OTHER MODULES
    let (crypts_data : CryptData) = crypts_IERC721.fetch_crypt_data(
        contract_address=crypts_address, token_id=token_id)

    # EMIT - STAKE
    Unlocked.emit(caller, token_id)
    # RETURN 1 (TRUE)
    return (TRUE)
end

# UNSTAKE - LOCKS CRYPT
@external
func lock_crypt{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (success : felt):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()
    let (block_timestamp) = get_block_timestamp()

   # FETCH ADDRESSES
    let (crypts_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Crypts)
    let (s_crypts_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Crypts)
    let (crypts_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S07_Crypts)
    let (resource_logic_address) = IModuleController.get_module_address(
        controller, ModuleIds.L02_Resources)

    # TRANSFER CRYPT BACK TO OWNER
    crypts_IERC721.transferFrom(crypts_address, crypts_state_address, caller, token_id)

    # BURN S_CRYPT
    s_crypts_IERC721.burn(s_crypts_address, token_id)

    # TODO: TimeStamp - current Hardcoded
    # PASS 0 to set the current time
    IS07_Crypts.set_time_staked(crypts_state_address, token_id, 0)

    # TOD0: Claim resources if available before unsettling

    # UPDATE STAKED CRYPTS COUNTER
    let (crypts_unlocked) = IS07_Crypts.get_total_crypts_unlocked(
        contract_address=crypts_state_address)
    IS07_Crypts.set_total_crypts_unlocked(crypts_state_address, crypts_unlocked - 1)

    # UPDATE OTHER MODULES
    let (crypts_data : CryptData) = crypts_IERC721.fetch_crypt_data(
        contract_address=crypts_address, token_id=token_id)

    # EMIT - UNSTAKE
    Locked.emit(caller, token_id)
    # RETURN 1 (TRUE)
    return (TRUE)
end
