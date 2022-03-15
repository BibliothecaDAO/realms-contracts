%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.dict import dict_write, dict_read
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.interfaces import IModuleController
from contracts.token.ERC20.interfaces.IERC20 import IERC20
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721

# #### Module 1B ###
#                 #
# Settling State  #
#                 #
###################

@storage_var
func controller_address() -> (address : felt):
end

@storage_var
func genesis() -> (timestamp : felt):
end

@storage_var
func epoch_length() -> (time : felt):
end

@storage_var
func time_staked(token_id : Uint256) -> (time : felt):
end

@storage_var
func total_realms_settled() -> (amount : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    # Store the address of the only fixed contract in the system.
    controller_address.write(address_of_controller)
    return ()
end

# Setters
@external
func set_genesis{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        time : felt):
    only_approved()

    genesis.write(time)
    return ()
end

@external
func set_epoch_length{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        time : felt):
    only_approved()

    epoch_length.write(time)
    return ()
end

@external
func set_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, timestamp : felt):
    only_approved()

    time_staked.write(token_id, timestamp)
    return ()
end

@external
func set_total_realms_settled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        amount : felt):
    only_approved()

    total_realms_settled.write(amount)
    return ()
end

@external
func set_approval{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (controller) = controller_address.read()

    # realms address
    let (realms_address) = IModuleController.get_realms_address(contract_address=controller)

    # settle address
    let (settle_logic_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=1)

    # Allow logic to access the erc721 stored
    realms_IERC721.setApprovalForAll(realms_address, settle_logic_address, 1)

    return ()
end

# Getters
@external
func get_genesis{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (timestamp : felt):
    let (timestamp) = genesis.read()

    return (timestamp=timestamp)
end

@external
func get_epoch_length{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (time : felt):
    let (time) = epoch_length.read()

    return (time=time)
end

@external
func get_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (time : felt):
    let (time) = time_staked.read(token_id)

    return (time=time)
end

# Getters
@external
func get_total_realms_settled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (realms_settled : felt):
    let (amount) = total_realms_settled.read()

    return (realms_settled=amount)
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
