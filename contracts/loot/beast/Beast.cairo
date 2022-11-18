// -----------------------------------
//   Module.Beast
//   Beast logic
//
//
//
// -----------------------------------

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.library.library_module import Module
from contracts.loot.adventurer.interface import IAdventurer
from contracts.loot.beast.library import BeastLib
from contracts.loot.constants.adventurer import AdventurerState
from contracts.loot.constants.beast import Beast
from contracts.loot.loot.stats.combat import CombatStats
from contracts.loot.utils.constants import ModuleIds, ExternalContractIds


// -----------------------------------
// Events
// -----------------------------------

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func beast(beastId: felt, adventurerTokenId: Uint256) -> (beast: felt) {
}

// -----------------------------------
// Initialize & upgrade
// -----------------------------------

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @return proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt,
    address_of_controller: felt,
) {
    // set as module
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

@external
func attack_beast{syscall_ptr: felt*, range_check_ptr}(
    adventurer_id: Uint256
) -> (new_unpacked_adventurer: AdventurerState) {
    alloc_locals;

    Module.only_approved();

    assert unpacked_adventurer.Status = AdventurerStatus.Battle;

    let (beast: Beast) = getBeastForAdventurer(adventurer_id);

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);

    let (damage_dealt) = CombatStats.calculate_damage_to_beast(beast, unpacked_adventurer.WeaponId);

    // check if damage dealt is less than health remaining
    let still_alive = is_le(damage_dealt, beast.Health);

    // deduct health from beast
    let (updated_beast) = BeastLib.deduct_health(damage_dealt, beast);

    // if the beast is alive
    if (still_alive == TRUE) {
        // having been attacked, it automatically attacks back
        let (damage_taken) = CombatStats.calculate_damage_from_beast(beast, unpacked_adventurer.ChestId);
        let (updated_adventurer: AdventurerState) = IAdventurer.deductHealth(
            adventurer_address, unpacked_adventurer, damage_taken
        );
        // beast.write(updated_beast);
    } else {
        // if beast has been slain, grant adventurer xp
        let (xp_gained) = beast.Rank * beast.Greatness;
        let (updated_adventurer: AdventurerState) = increase_xp(xp_gained, unpacked_adventurer);
    }

    return (updated_adventurer,);
}

@external
func flee_from_beast{syscall_ptr: felt*, range_check_ptr}(
    unpacked_adventurer: AdventurerState, beast: Beast
) -> (new_unpacked_adventurer: AdventurerState) {
    alloc_locals;

    Module.only_approved();

    // Adventurer Speed is Dexterity - Weight of all equipped items
    // TODO: Provide utility function that takes in an adventurer and returns net weight of gear
    //       For now just hard_code this weight:
    let (weight_of_equipment) = 3;
    let (adventurer_speed) = unpacked_adventurer.Dexterity - weight_of_equipment;

    // Adventurer ambush resistance is based on wisdom plus luck
    let (ambush_resistance) = unpacked_adventurer.Wisdom + unpacked_adventurer.Luck;

    let (controller) = Module.controller_address();
    let (xoroshiro_address_) = IModuleController.get_xoroshiro(controller);
    let (rnd) = IXoroshiro.next(xoroshiro_address_);
    let (_, r) = unsigned_div_rem(rnd, 20);

    // if adventurer ambush resistance is less than beast ambush ability
    let is_ambushed = is_le(ambush_resistance, r);

    // default damage when fleeing is 0
    let damage_taken = 0;
    // unless ambush occurs
    if (is_ambushed == TRUE) {
        // then calculate damage based on beast
        let (damage_taken) = CombatStats.calculate_damage_from_beast(beast, Adventurer.ChestId);

            let (ambushed_adventurer: AdventurerState) = deduct_health(
                damage_taken, unpacked_adventurer
            );
    }

    let (can_flee) = is_le(ambush_rng, adventurer_speed);
    if (can_flee == TRUE) {
        // if the adventurer is able to flee, set their state back to idle

        let (was_ambushed) = is_le(damage_taken, 0);

        if (was_ambushed == TRUE) {
            let (adventurer_fled: AdventurerState) = cast_state(
                AdventurerSlotIds.Mode, AdventurerMode.Idle, ambushed_adventurer
            );
        } else {
            let (adventurer_fled: AdventurerState) = cast_state(
                AdventurerSlotIds.Mode, AdventurerMode.Idle, unpacked_adventurer
            );
        }

        return (adventurer_fled,);

    } else {
        // if adventurer is not able to flee, their state stays same (battle)
        return (unpacked_adventurer,);
    }
}

// --------------------
// Getters
// --------------------

@view
func getBeastById{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: Uint256) -> (beast: Beast) {
    alloc_locals;

    let (packed_beast) = beast.read(tokenId);

    // unpack
    let (unpacked_beast: Beast) = BeastLib.unpack(packed_beast);

    return (unpacked_beast,);
}





