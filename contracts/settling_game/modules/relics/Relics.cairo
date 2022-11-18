// -----------------------------------
//   Module.L02___RELIC
//   Logic around Relics
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_lt

from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.library.library_module import Module

from contracts.settling_game.interfaces.IRealms import IRealms
from contracts.settling_game.interfaces.imodules import IModuleController
from contracts.settling_game.utils.game_structs import RealmData, ExternalContractIds

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
func owned_relics_len(owner_token_id: Uint256) -> (res: felt) {
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
    // Only combat
    Module.only_approved();

    let (current_relic_owner) = get_current_relic_holder(loser_token_id);

    let (loser_has_own_relic) = uint256_eq(current_relic_owner, loser_token_id);

    let (old_owner_token_id) = storage_relic_holder.read(current_relic_owner);

    // If old owner exists, update array
    let (old_owner_of_relic_exists) = uint256_lt(Uint256(0, 0), old_owner_token_id);

    // Capture Relic if owned by loser
    // If Relic is owned by loser, send to victor
    if (loser_has_own_relic == TRUE) {
        if (old_owner_of_relic_exists == TRUE) {
            tempvar remove_victory_relics: Uint256* = new (loser_token_id);
            let (loser_relics_len) = owned_relics_len.read(loser_token_id);
            loop_remove_relic(0, 0, loser_relics_len, loser_token_id, 1, remove_victory_relics);
            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
        }
        _set_relic_holder(winner_token_id, loser_token_id);
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }

    let (controller) = Module.controller_address();

    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    );

    let (winner_realm_data: RealmData) = IRealms.fetch_realm_data(realms_address, winner_token_id);

    let (loser_relics_len) = owned_relics_len.read(loser_token_id);

    let (remove_order_relics: Uint256*) = alloc();

    let (remove_relics_len) = loop_claim_order_relic(
        0, realms_address, winner_realm_data, loser_token_id, loser_relics_len, 0, remove_order_relics
    );

    return loop_remove_relic(0, 0, loser_relics_len, loser_token_id, remove_relics_len, remove_order_relics);
}

// @notice loop loser relic and return if order of winner matches holder
// @implicit syscall_ptr
// @implicit range_check_ptr
// @param index: index of owner relics to check, starting at 0
// @param realms_address: realms token address
// @param winner_realm_data: realm data of the winner
// @param loser_token_id: realm id of loser
// @param loser_relics_len: length of relics array of loser
// @param remove_relics_index: index of relics to remove
// @param remove_relics: array of relics to remove from loser
// @return remove_relics_len: length of relics to remove from loser 
func loop_claim_order_relic{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    index: felt,
    realms_address: felt,
    winner_realm_data: RealmData,
    loser_token_id: Uint256,
    loser_relics_len: felt,
    remove_relics_index: felt,
    remove_relics: Uint256*,
) -> (remove_relics_len: felt) {
    alloc_locals;
    if (index == loser_relics_len) {
        return (remove_relics_index,);
    }

    let (relic_id) = owned_relics.read(loser_token_id, index);

    let (relic_owner_data: RealmData) = IRealms.fetch_realm_data(realms_address, relic_id);

    if (winner_realm_data.order == relic_owner_data.order) {
        _set_relic_holder(relic_id, relic_id);
        assert remove_relics[remove_relics_index] = relic_id;
        return loop_claim_order_relic(
            index + 1,
            realms_address,
            winner_realm_data,
            loser_token_id,
            loser_relics_len,
            remove_relics_index + 1,
            remove_relics,
        );
    }
    return loop_claim_order_relic(
        index + 1,
        realms_address,
        winner_realm_data,
        loser_token_id,
        loser_relics_len,
        remove_relics_index,
        remove_relics,
    );
}

// @notice return held relics to original owners
// @implicit syscall_ptr
// @implicit range_check_ptr
// @param realms_token_id: realm id that needs assets returned
@external
func return_relics{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    realms_token_id: Uint256
) {
    alloc_locals;
    // Only Settling
    Module.only_approved();
    let (relics_len) = owned_relics_len.read(realms_token_id);

    let (remove_relics: Uint256*) = alloc();

    loop_return_relics(0, realms_token_id, relics_len, remove_relics);

    loop_remove_relic(0, 0, relics_len, realms_token_id, relics_len, remove_relics);
    
    return ();
}

// @notice loop relic held and return it to original owner
// @implicit syscall_ptr
// @implicit range_check_ptr
// @param index: index of relic held
// @param realms_token_id: realm id holding the relics
// @param relics_len: length of relic array held by realm id
// @param remove_relics: array of relics to remove
func loop_return_relics{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: felt, realms_token_id: Uint256, relics_len: felt, remove_relics: Uint256*
) {
    alloc_locals;
    if (index == relics_len) {
        return ();
    }

    let (relic_id) = owned_relics.read(realms_token_id, index);

    _set_relic_holder(relic_id, relic_id);
    assert remove_relics[index] = relic_id;

    return loop_return_relics(index + 1, realms_token_id, relics_len, remove_relics);
}

// -----------------------------------
// SETTERS
// -----------------------------------

// @notice sets the relic against the new holder
// @implicit syscall_ptr
// @implicit range_check_ptr
// @param owner_token_id: realm id of new owner
// @param relic_id: relic id, original relic owner realm id
func _set_relic_holder{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner_token_id: Uint256, relic_id: Uint256
) {
    alloc_locals;

    // Store in as usual storage value
    storage_relic_holder.write(relic_id, owner_token_id);

    // Array stored for multiple relic returns
    let (relics_len) = owned_relics_len.read(owner_token_id);
    owned_relics.write(owner_token_id, relics_len, relic_id);
    owned_relics_len.write(owner_token_id, relics_len + 1);

    // Emit update whenever Relic changes hands
    RelicUpdate.emit(relic_id, owner_token_id);
    return ();
}

// -----------------------------------
// SETTERS
// -----------------------------------

// @notice loop to remove relics from old owner array
// @implicit syscall_ptr
// @implicit range_check_ptr
// @param old_index: index in old (current) owned relic array
// @param new_index: index in new owned relic array
// @param relics_len: length of old owned relic array
// @param owner_token_id: realm id of old relic owner
// @param remove_relics_len: length of relics to remove from loser
// @param remove_relics: array of relics to remove from loser
func loop_remove_relic{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    old_index: felt,
    new_index: felt,
    relics_len: felt,
    owner_token_id: Uint256,
    remove_relics_len: felt,
    remove_relics: Uint256*,
) {
    alloc_locals;
    let check = is_le(relics_len, old_index);
    if (check == TRUE) {
        owned_relics_len.write(owner_token_id, relics_len - remove_relics_len);
        return ();
    }
    let (stored_relic_id) = owned_relics.read(owner_token_id, old_index);
    let (check) = loop_check_relic(0, stored_relic_id, remove_relics_len, remove_relics);
    if (check == TRUE) {
        let (shift_stored_relic_id) = owned_relics.read(owner_token_id, old_index + 1);
        owned_relics.write(owner_token_id, new_index, shift_stored_relic_id);
        return loop_remove_relic(
            old_index + 2,
            new_index + 1,
            relics_len,
            owner_token_id,
            remove_relics_len,
            remove_relics,
        );
    } else {
        owned_relics.write(owner_token_id, new_index, stored_relic_id);
        return loop_remove_relic(
            old_index + 1,
            new_index + 1,
            relics_len,
            owner_token_id,
            remove_relics_len,
            remove_relics,
        );
    }
}

// @notice loop to check relic exists at elemnt in array
// @implicit syscall_ptr
// @implicit range_check_ptr
// @param index: index in array
// @param stored_relic_id: relic id in owned_relics
// @param remove_relics_len: length of relics to be removed
// @param remove_relics: array of relics to be removed
func loop_check_relic{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    index: felt, stored_relic_id: Uint256, remove_relics_len: felt, remove_relics: Uint256*
) -> (check: felt) {
    if (index == remove_relics_len) {
        return (FALSE,);
    }
    let (check) = uint256_eq(stored_relic_id, remove_relics[index]);
    if (check == TRUE) {
        return (TRUE,);
    }

    return loop_check_relic(index + 1, stored_relic_id, remove_relics_len, remove_relics);
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

    // If 0 the relic is still in the hands of the owner
    // else realm is in new owner
    let (is_equal) = uint256_eq(holder_id, Uint256(0, 0));

    if (is_equal == TRUE) {
        return (relic_id,);
    }

    return (holder_id,);
}

// @notice returns true if Relic exists
@view
func is_relic_at_home{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    relic_id: Uint256
) -> (yesno: felt) {
    alloc_locals;

    let (holder_id) = storage_relic_holder.read(relic_id);

    let (current_holder) = Relics._current_relic_holder(relic_id, holder_id);

    let (holds_relic) = uint256_eq(holder_id, current_holder);

    return (yesno=holds_relic);
}
