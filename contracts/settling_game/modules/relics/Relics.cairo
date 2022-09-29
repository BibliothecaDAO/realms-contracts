// -----------------------------------
//   Module.L02___RELIC
//   Logic around Relics
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_lt

from starkware.cairo.common.bool import TRUE

from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.library.library_module import Module
from contracts.settling_game.modules.relics.library import Relics

from contracts.settling_game.interfaces.IRealms import IRealms
from contracts.settling_game.interfaces.imodules import IModuleController
from contracts.settling_game.utils.game_structs import ModuleIds, RealmData, ExternalContractIds

// -----------------------------------
// Events
// -----------------------------------

@event
func RelicUpdate(relic_id: Uint256, owner_token_id: Uint256) {
}

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func storage_relic_holder(relic_id: Uint256) -> (owner_token_id: Uint256) {
}

@storage_var
func owned_relics_count(owner_token_id: Uint256) -> (res: felt) {
}

@storage_var
func owned_relics(owner_token_id: Uint256, index: felt) -> (relic_id: Uint256) {
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

// @notice set relic holder external function
// @implicit syscall_ptr
// @implicit range_check_ptr
// @param winner_token_id: winning realm id of battle
// @param loser_token_id: loosing realm id of battle
@external
func set_relic_holder{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    winner_token_id: Uint256, loser_token_id: Uint256
) {
    alloc_locals;
    // Only Combat

    // TODO: Fix auth issue
    // Module.only_approved()

    let (current_relic_owner) = get_current_relic_holder(loser_token_id);

    let (is_equal) = uint256_eq(current_relic_owner, loser_token_id);

    // Capture Relic if owned by loser
    // If Relic is owned by loser, send to victor
    if (is_equal == TRUE) {
        _set_relic_holder(loser_token_id, winner_token_id);
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }

    // TODO: Add Order capture back
    let (controller) = Module.controller_address();

    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    );

    let (winner_realm_data: RealmData) = IRealms.fetch_realm_data(realms_address, winner_token_id);

    let (relics_len) = owned_relics_count.read(loser_token_id);

    loop_relic(0, realms_address, winner_realm_data, loser_token_id, relics_len);

    return ();
}

func loop_relic{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    index: felt,
    realms_address: felt,
    winner_realm_data: RealmData,
    loser_token_id: Uint256,
    relics_len: felt,
) {
    if (index == relics_len) {
        return ();
    }

    let (relic_id) = owned_relics.read(loser_token_id, index);

    let (relic_owner_data: RealmData) = IRealms.fetch_realm_data(realms_address, relic_id);

    if (winner_realm_data.order == relic_owner_data.order) {
        _set_relic_holder(relic_id, relic_id);
        return ();
    }

    loop_relic(index + 1, realms_address, winner_realm_data, loser_token_id, relics_len);

    return ();
}

@external
func return_relics{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    realms_token_id: Uint256
) {
    let (relic_count) = owned_relics_count.read(realms_token_id);

    loop_return_relics(0, realms_token_id, relic_count);

    return ();
}

func loop_return_relics{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: felt, realms_token_id: Uint256, relic_count: felt
) {
    if (index == relic_count) {
        return ();
    }

    let (relic_id) = owned_relics.read(realms_token_id, index);

    _set_relic_holder(relic_id, relic_id);

    loop_return_relics(index + 1, realms_token_id, relic_count);

    return ();
}

func get_relic_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    relic_id: Uint256, owner_token_id: Uint256
) -> (index: felt) {
    let (relics_len: felt, relics: Uint256*) = get_owned_relics(owner_token_id);

    let (index) = find_uint256_value(0, relics_len, relics, value=relic_id);

    return (index=index);
}

// -----------------------------------
// SETTERS
// -----------------------------------

func _set_relic_holder{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    relic_id: Uint256, owner_token_id: Uint256
) {
    alloc_locals;
    // Get old relic holder, then update array
    let (old_owner_token_id) = storage_relic_holder.read(relic_id);

    storage_relic_holder.write(relic_id, owner_token_id);

    // If old owner exists, update array
    let (check_exists) = uint256_lt(Uint256(0,0), old_owner_token_id);
    if (check_exists == TRUE) {
        let (relic_index) = get_relic_index(relic_id=relic_id, owner_token_id=old_owner_token_id);
        owned_relics.write(old_owner_token_id, relic_index, Uint256(0, 0));
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }

    // Array stored for multiple relic returns
    let (relic_count) = owned_relics_count.read(owner_token_id);
    owned_relics.write(owner_token_id, relic_count, relic_id);
    owned_relics_count.write(owner_token_id, relic_count + 1);

    // Emit update whenever Relic changes hands
    RelicUpdate.emit(relic_id, owner_token_id);
    return ();
}

// -----------------------------------
// GETTERS
// -----------------------------------

// @notice gets current relic holder
// @implicit syscall_ptr
// @implicit range_check_ptr
// @param relic_id: id of relic, pass in realm id
// @return token_id: returns realm id of owning relic
@view
func get_current_relic_holder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    relic_id: Uint256
) -> (token_id: Uint256) {
    alloc_locals;

    let (holder_id) = storage_relic_holder.read(relic_id);

    let (data) = Relics._current_relic_holder(relic_id, holder_id);

    return (data,);
}

@view
func get_owned_relics{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owned_token_id: Uint256
) -> (relics_len: felt, relics: Uint256*) {
    alloc_locals;
    let (relics_len) = owned_relics_count.read(owned_token_id);
    let (relics: Uint256*) = alloc();
    loop_get_relics(0, owned_token_id, relics_len, relics);
    return (relics_len, relics);
}

func loop_get_relics{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: felt, owned_token_id: Uint256, relics_len: felt, relics: Uint256*
) {
    if (index == relics_len) {
        return ();
    }

    let (relic) = owned_relics.read(owned_token_id, index);

    assert relics[index] = relic;

    loop_get_relics(
        index=index + 1, owned_token_id=owned_token_id, relics_len=relics_len, relics=relics
    );

    return ();
}

@view
func find_uint256_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    arr_index: felt, arr_len: felt, arr: Uint256*, value: Uint256
) -> (index: felt) {
    if (arr_index == arr_len) {
        with_attr error_message("Find Value: Value not found") {
            assert 1 = 0;
        }
    }
    let (check) = uint256_eq(arr[arr_index], value);
    if (check == TRUE) {
        return (index=arr_index);
    }

    find_uint256_value(arr_index + 1, arr_len, arr, value);

    return (index=arr_index);
}
