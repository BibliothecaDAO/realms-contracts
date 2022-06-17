# ____MODULE_L09___RELIC
#   Contains Logic around Relics
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_timestamp,
    get_contract_address,
)
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds
from contracts.settling_game.utils.constants import TRUE
from contracts.settling_game.library.library_module import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
)

from openzeppelin.token.erc721.interfaces.IERC721 import IERC721
from contracts.settling_game.interfaces.s_crypts_IERC721 import s_crypts_IERC721
from contracts.settling_game.interfaces.imodules import IModuleController, IL08_Crypts_Resources

from openzeppelin.upgrades.library import (
    Proxy_initializer,
    Proxy_only_admin,
    Proxy_set_implementation,
)

##########
# EVENTS #
##########

@event
func RelicUpdate(relic_id : Uint256, owner_token_id : Uint256):
end

###########
# STORAGE #
###########

@storage_var
func Storage_relic_holder(relic_id : Uint256) -> (owner_token_id : Uint256):
end

###############
# CONSTRUCTOR #
###############

@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt, proxy_admin : felt
):
    MODULE_initializer(address_of_controller)
    Proxy_initializer(proxy_admin)
    return ()
end

@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy_only_admin()
    Proxy_set_implementation(new_implementation)
    return ()
end

############
# EXTERNAL #
############

@external
func set_relic_holder{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    winner_token_id : Uint256, loser_token_id : Uint256
):
    alloc_locals
    # Only Combat
    MODULE_only_approved()

    let (current_relic_owner) = get_current_relic_holder(loser_token_id)

    let (isEq) = uint256_eq(current_relic_owner, loser_token_id)

    # Capture Relic if owned by loser
    # If Relic is owned by loser, send to victor
    if isEq == 1:
        _set_relic_holder(loser_token_id, winner_token_id)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    # Capture back if held by loser
    # Check if loser has winners token
    let (winners_relic_owner) = get_current_relic_holder(winner_token_id)

    let (holdsRelic) = uint256_eq(winners_relic_owner, loser_token_id)

    if holdsRelic == 1:
        _set_relic_holder(winner_token_id, winner_token_id)
        return ()
    end

    # TODO: Add Order capture back

    return ()
end

###########
# SETTERS #
###########

func _set_relic_holder{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    relic_id : Uint256, owner_token_id : Uint256
):
    Storage_relic_holder.write(relic_id, owner_token_id)

    # Emit update whenever Relic changes hands
    RelicUpdate.emit(relic_id, owner_token_id)
    return ()
end

###########
# GETTERS #
###########

@view
func get_current_relic_holder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    relic_id : Uint256
) -> (token_id : Uint256):
    alloc_locals

    let (data) = Storage_relic_holder.read(relic_id)

    # If 0 the relic is still in the hands of the owner
    # else realm is in new owner
    let (isEq) = uint256_eq(data, Uint256(0, 0))

    if isEq == 1:
        return (relic_id)
    end

    return (data)
end
