# -----------------------------------
# ____Module.GoblinTown
#   Logic of the Goblin Town, as far as one can claim goblins follow logic

# ELI5:
#   TODO
# MIT License
# -----------------------------------

# TODO:
#   goblin town
#     on succes, attacker gets LORDS

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.utils.constants import GOBLIN_WELCOME_PARTY_STRENGTH
from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds, RealmData
from contracts.settling_game.modules.goblintown.library import GoblinTown

# -----------------------------------
# Events
# -----------------------------------

# TODO? what events do we need?

# -----------------------------------
# Storage
# -----------------------------------

# TODO: write docs

@storage_var
func xoroshiro_address() -> (address : felt):
end

@storage_var
func goblin_town_data() -> (packed : felt):
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

@external
func spawn_goblin_welcomparty{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    realm_id : Uint256
):
    alloc_locals

    Module.only_approved()

    let (ts) = get_block_timestamp()
    let (packed) = GoblinTown.pack(GOBLIN_WELCOME_PARTY_STRENGTH, ts)
    goblin_town_data.write(packed)

    return ()
end

@external
func spawn_next{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    realm_id : Uint256
):
    alloc_locals

    Module.only_approved()

    let (xoroshiro_addr) = get_xoroshiro()
    let (rnd) = IXoroshiro.next(xoroshiro_addr)

    # calculate the next spawn timestamp
    let (_, spawn_delay_hours) = unsigned_div_rem(rnd, 25)  # [0,24]
    let (now) = get_block_timestamp()
    let next_spawn_ts = now + ((24 + spawn_delay_hours) * 3600)

    # calculate the strength
    # normal and staked Realms have the same ID, so the following will work
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms)
    let (realm_data : RealmData) = realms_IERC721.fetch_realm_data(realms_address, realm_id)
    let (_, extras) = unsigned_div_rem(rnd, 5)  # [0,4]
    let (strength) = GoblinTown.calculate_strength(realm_data, extras)

    # pack & store the data
    let (packed) = GoblinTown.pack(strength, next_spawn_ts)
    goblin_town_data.write(packed)

    return ()
end

# -----------------------------------
# INTERNAL
# -----------------------------------

# -----------------------------------
# GETTERS
# -----------------------------------

@view
func get_strength_and_timestamp{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    realm_id : Uint256
) -> (strength : felt, timestamp : felt):
    let (packed) = goblin_town_data.read()
    let (strength, ts) = GoblinTown.unpack(packed)
    return (strength, ts)
end

# -----------------------------------
# ADMIN
# -----------------------------------

@external
func set_xoroshiro{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    xoroshiro : felt
):
    Proxy.assert_only_admin()
    xoroshiro_address.write(xoroshiro)
    return ()
end

@external
func get_xoroshiro{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    xoroshiro_address : felt
):
    xoroshiro_address.read(xoroshiro)
    return xoroshiro_address.read(xoroshiro)
end
