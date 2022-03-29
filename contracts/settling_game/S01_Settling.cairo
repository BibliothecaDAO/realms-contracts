%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.dict import dict_write, dict_read
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.token.IERC20 import IERC20
from contracts.settling_game.interfaces.imodules import IModuleController
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721

from contracts.settling_game.utils.library import (
    MODULE_controller_address, MODULE_only_approved, MODULE_initializer)

# #### Module 1B ###
#                 #
# Settling State  #
#                 #
###################

@storage_var
func time_staked(token_id : Uint256) -> (time : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    # Store the address of the only fixed contract in the system.
    MODULE_initializer(address_of_controller)
    return ()
end

#
# Setters
#

@external
func set_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, timestamp : felt):
    MODULE_only_approved()

    time_staked.write(token_id, timestamp)
    return ()
end

@external
func set_approval{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (controller) = MODULE_controller_address()

    # realms address
    let (realms_address) = IModuleController.get_realms_address(contract_address=controller)

    # settle address
    let (settle_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=1)

    # Allow logic to access the erc721 stored
    realms_IERC721.setApprovalForAll(realms_address, settle_logic_address, 1)

    return ()
end

#
# Getters
#

@external
func get_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (time : felt):
    let (time) = time_staked.read(token_id)

    return (time=time)
end
