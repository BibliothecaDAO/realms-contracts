# -----------------------------------
# ____Module.L02___RELIC
#   Logic around Relics
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.constants import TRUE
from contracts.settling_game.library.library_module import Module
from openzeppelin.upgrades.library import Proxy

# -----------------------------------
# Events
# -----------------------------------

@event
func RelicUpdate(relic_id : Uint256, owner_token_id : Uint256):
end

# -----------------------------------
# Storage
# -----------------------------------

@storage_var
func storage_relic_holder(relic_id : Uint256) -> (owner_token_id : Uint256):
end

# -----------------------------------
# INITIALIZER & UPGRADE
# -----------------------------------

# @notice Module initializer
# @param address_of_controller: Controller/arbiter address
# @proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt, proxy_admin : felt
):
    Module.initializer(address_of_controller)
    Proxy.initializer(proxy_admin)
    return ()
end

# @notice Set new proxy implementation
# @dev Can only be set by the arbiter
# @param new_implementation: New implementation contract address
@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy.assert_only_admin()
    Proxy._set_implementation_hash(new_implementation)
    return ()
end

# -----------------------------------
# EXTERNAL
# -----------------------------------

# Plant farm

# Harvest farm

# Mint food

# Convert food to storehouse

# Calculate food available

# -----------------------------------
# SETTERS
# -----------------------------------

# -----------------------------------
# GETTERS
# -----------------------------------
