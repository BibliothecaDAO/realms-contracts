// -----------------------------------
//   Module.GoblinTown
//   Logic of the Goblin Town, as far as one can claim goblins follow logic

// ELI5:
//   WIP: Upgrade to new Combat.
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math_cmp import is_le
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_timestamp,
    get_contract_address,
)

from openzeppelin.upgrades.library import Proxy
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.token.erc20.IERC20 import IERC20

from contracts.settling_game.interfaces.IRealms import IRealms
from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.modules.goblintown.library import GoblinTown
from contracts.settling_game.utils.constants import GOBLIN_WELCOME_PARTY_STRENGTH, DAY, CCombat
from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds, RealmData
from contracts.settling_game.utils.game_structs import Squad
from contracts.settling_game.modules.combat.library import Combat

// -----------------------------------
// Events
// -----------------------------------

@event
func GoblinSpawn(realm_id: Uint256, goblin_squad: Squad, time_stamp: felt) {
}

// -----------------------------------
// Storage
// -----------------------------------

// TODO: write docs

@storage_var
func xoroshiro_address() -> (address: felt) {
}

@storage_var
func goblin_town_data(realm_id: Uint256) -> (packed: felt) {
}

// -----------------------------------
// INITIALIZER & UPGRADE
// -----------------------------------

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address_of_controller: felt, proxy_admin: felt
) {
    Module.initializer(address_of_controller);
    Proxy.initializer(proxy_admin);
    return ();
}

// @notice Set new proxy implementation
// @dev Can only be set by the arbiter
// @param new_implementation: New implementation contract address
@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

// -----------------------------------
// EXTERNAL
// -----------------------------------

@storage_var
func last_claimed(realm_id: Uint256) -> (time_stamp: felt) {
}

// only used in testing
@external
func lords_faucet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    realm_id: Uint256
) {
    alloc_locals;

    Module.ERC721_owner_check(realm_id, ExternalContractIds.S_Realms);

    let (ts) = get_block_timestamp();

    let (last_claim) = last_claimed.read(realm_id);

    let difference = ts - last_claim;

    let is_available = is_le(DAY, difference);

    assert is_available = TRUE;

    last_claimed.write(realm_id, ts);

    let (caller) = get_caller_address();
    let (lords_address) = Module.get_external_contract_address(ExternalContractIds.Lords);
    IERC20.approve(lords_address, caller, Uint256(CCombat.GOBLINDOWN_REWARD * 10 ** 18, 0));
    IERC20.transfer(lords_address, caller, Uint256(CCombat.GOBLINDOWN_REWARD * 10 ** 18, 0));

    return ();
}

// @external
// func spawn_goblin_welcomparty{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     realm_id: Uint256
// ) {
//     alloc_locals;

// Module.only_approved();

// let (ts) = get_block_timestamp();
//     let (packed) = GoblinTown.pack(GOBLIN_WELCOME_PARTY_STRENGTH, ts);
//     goblin_town_data.write(realm_id, packed);

// // emit goblin spawn
//     let (goblins: Squad) = Combat.build_goblin_squad(GOBLIN_WELCOME_PARTY_STRENGTH);
//     GoblinSpawn.emit(realm_id, goblins, ts);

// return ();
// }

// @external
// func spawn_next{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     realm_id: Uint256
// ) {
//     alloc_locals;

// // TODO: turn on NOT working for some reason.
//     // Module.only_approved()

// let (xoroshiro_addr) = xoroshiro_address.read();
//     let (rnd) = IXoroshiro.next(xoroshiro_addr);

// // calculate the next spawn timestamp
//     let (_, spawn_delay_hours) = unsigned_div_rem(rnd, 25);  // [0,24]
//     let (now) = get_block_timestamp();

// // get DAY / 24
//     let (day_cycle_hour, _) = unsigned_div_rem(DAY, 24);
//     let next_spawn_ts = now + (DAY + spawn_delay_hours * day_cycle_hour);

// // calculate the strength
//     // normal and staked Realms have the same ID, so the following will work
//     let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms);
//     let (realm_data: RealmData) = IRealms.fetch_realm_data(realms_address, realm_id);
//     let (_, extras) = unsigned_div_rem(rnd, 5);  // [0,4]
//     let (strength) = GoblinTown.calculate_strength(realm_data, extras);

// // pack & store the data
//     let (packed) = GoblinTown.pack(strength, next_spawn_ts);
//     goblin_town_data.write(realm_id, packed);

// // emit goblin spawn
//     let (goblins: Squad) = Combat.build_goblin_squad(strength);
//     GoblinSpawn.emit(realm_id, goblins, next_spawn_ts);

// return ();
// }

// -----------------------------------
// INTERNAL
// -----------------------------------

// -----------------------------------
// GETTERS
// -----------------------------------

// @view
// func get_strength_and_timestamp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     realm_id: Uint256
// ) -> (strength: felt, timestamp: felt) {
//     let (packed) = goblin_town_data.read(realm_id);
//     let (strength, ts) = GoblinTown.unpack(packed);
//     return (strength, ts);
// }

// @view
// func get_goblin_squad{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     realm_id: Uint256
// ) -> (goblins: Squad) {
//     alloc_locals;
//     let (packed) = goblin_town_data.read(realm_id);
//     let (strength, ts) = GoblinTown.unpack(packed);
//     let (goblins: Squad) = Combat.build_goblin_squad(strength);
//     return (goblins,);
// }

// -----------------------------------
// ADMIN
// -----------------------------------

// @external
// func set_xoroshiro{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     xoroshiro: felt
// ) {
//     Proxy.assert_only_admin();
//     xoroshiro_address.write(xoroshiro);
//     return ();
// }
