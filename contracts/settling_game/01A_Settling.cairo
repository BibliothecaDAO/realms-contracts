%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.general import scale
from contracts.settling_game.utils.interfaces import IModuleController, I01B_Settling

from contracts.token.ERC20.interfaces.IERC20 import IERC20
from contracts.token.ERC1155.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721

# #### Module 1A ###
#                 #
# Settling Logic  #
#                 #
###################

@storage_var
func controller_address() -> (address : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    # Store the address of the only fixed contract in the system.
    controller_address.write(address_of_controller)
    return ()
end

# Settles Realm
# Transfers Realm to State Contract
# Mints sRealm and sends to user
@external
func settle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token_id : Uint256):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()
    let (block_timestamp) = get_block_timestamp()
    # realms address
    let (realms_address) = IModuleController.get_realms_address(contract_address=controller)

    # s realms address
    let (s_realms_address) = IModuleController.get_s_realms_address(contract_address=controller)

    # settle address
    let (settle_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=2)

    # transfer realm into settling state contract
    realms_IERC721.transferFrom(realms_address, caller, settle_state_address, token_id)

    # mint sRealm
    s_realms_IERC721.mint(s_realms_address, caller, token_id)

    # TODO: TimeStamp - current Hardcoded
    I01B_Settling.set_time_staked(settle_state_address, token_id, block_timestamp)

    # updated settled realms counter
    let (realms_settled) = I01B_Settling.get_total_realms_settled(contract_address=settle_state_address)
    I01B_Settling.set_total_realms_settled(settle_state_address, realms_settled + 1)

    return ()
end

# UnSettles Realm
# Transfers Realm to State Contract
# Burns sRealm and sends to user
@external
func unsettle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()
    let (block_timestamp) = get_block_timestamp()
    # realms address
    let (realms_address) = IModuleController.get_realms_address(contract_address=controller)

    # s realms address
    let (s_realms_address) = IModuleController.get_s_realms_address(contract_address=controller)

    # settle address
    let (settle_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=2)

    # transfer realm back to owner
    realms_IERC721.transferFrom(realms_address, settle_state_address, caller, token_id)

    # burn sRealm
    s_realms_IERC721.burn(s_realms_address, token_id)

    # TODO: TimeStamp - current Hardcoded
    I01B_Settling.set_time_staked(settle_state_address, token_id, block_timestamp)

    # TOD0: Claim resources if available before unsettling

    # updated settled realms counter
    let (realms_settled) = I01B_Settling.get_total_realms_settled(contract_address=settle_state_address)
    I01B_Settling.set_total_realms_settled(settle_state_address, realms_settled - 1)

    return ()
end
