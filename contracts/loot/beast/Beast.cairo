// -----------------------------------
//   Module.Beast
//   Beast logic
//
//
//
// -----------------------------------

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.upgrades.library import Proxy
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable

from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.library.library_module import Module
from contracts.loot.adventurer.interface import IAdventurer
from contracts.loot.adventurer.library import AdventurerLib
from contracts.loot.beast.library import BeastLib
from contracts.loot.constants.adventurer import (
    Adventurer,
    AdventurerState,
    AdventurerStatus,
    AdventurerSlotIds,
)
from contracts.loot.constants.beast import Beast, BeastConstants
from contracts.loot.interfaces.imodules import IModuleController
from contracts.loot.loot.stats.combat import CombatStats
from contracts.loot.utils.constants import ModuleIds, ExternalContractIds


// -----------------------------------
// Events
// -----------------------------------

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func beast(tokenId: felt) -> (packed_beast: felt) {
}
// -----------------------------------
// Initialize & upgrade
// -----------------------------------

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @return proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt, address_of_controller: felt
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
func createBeast{
     pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
     }(adventurer_token_id: felt, xp: felt) -> (tokenId: felt) {

    let (caller) = get_caller_address();
    let (owner) = IAdventurer.ownerOf(adventurer_token_id);
    with_attr error_message("Beast: Can't generate a beast for another adventurer... for now") {
        assert caller = owner;
    }

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);
    let (unpacked_adventurer) = IAdventurer.getAdventurerById(adventurer_address, adventurer_token_id);
    with_attr error_message("Beast: Only one beast at a time... for now") {
        assert unpacked_adventurer.Beast = 0;
    }
    with_attr error_message("Beast: Only adventurers in battle mode can create a beast") {
        assert unpacked_adventurer.Status = AdventurerStatus.Battle;
    }

     // get a random beast id (determines type and rank)
     let (beast_id) = get_random_beast_id();

     // create beast
     let (new_beast: BeastState) = BeastLib.create(beast_id, adventurer_token_id, xp);

     // TODO MILESTONE1: Need to create PackedBeast struct
     let (packed_new_beast: PackedBeast) = BeastLib.pack(new_beast);

    // get current ID and add 1
    let (current_id: Uint256) = totalSupply();
    let (next_beast_id, _) = uint256_add(current_id, Uint256(1, 0));

    // store beast
    beast.write(next_beast_id, packed_new_beast);

    return (next_beast_id,);
}

// TODO MILESTONE2: Change this function to take in beast tokenId instead of adventurer tokenId
//                  as its more intuitive from a client perspective
@external
func attack{syscall_ptr: felt*, range_check_ptr}(adventurer_id: Uint256) {
    alloc_locals;

    let (caller) = get_caller_address();
    let (owner) = IAdventurer.ownerOf(adventurer_id);

    with_attr error_message("Beast: Only adventurer owner can attack") {
        assert caller = owner;
    }

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);

    let (unpacked_adventurer) = IAdventurer.getAdventurerById(adventurer_address, adventurer_id);

    with_attr error_message("Beast: Adventurer must be in a battle") {
        assert unpacked_adventurer.Status = AdventurerStatus.Battle;
    }

    // get the beast the adventurer is currently battling
    let (beast: Beast) = getBeastById(unpacked_adventurer.beast);
    // and verify it's not already dead
    with_attr error_message("Beast: Can't attack a dead beast") {
        assert_not_zero(beast.Health);
    }

    // calculate damage dealt to the beast from adventurer
    let (damage_dealt) = CombatStats.calculate_damage_to_beast(beast, unpacked_adventurer.WeaponId);
    // and deduct it from beast's health
    let (updated_beast) = BeastLib.deduct_health(damage_dealt, beast);

    // check if beast is still alive after the attack
    let still_alive = is_le(damage_dealt, beast.Health);

    // if the beast is alive
    if (still_alive == TRUE) {
        // it automatically counter attacks
        let (damage_taken) = CombatStats.calculate_damage_from_beast(
            beast, unpacked_adventurer.ChestId
        );

        // deduct beast damage from adventurer's health
        let (updated_adventurer: AdventurerState) = IAdventurer.deductHealth(
            adventurer_address, unpacked_adventurer, damage_taken
        );
    } else {
        // if beast has been slain, grant adventurer xp
        let (xp_gained) = beast.Rank * beast.XP;
        let (updated_adventurer: AdventurerState) = AdventurerLib.increase_xp(
            xp_gained, unpacked_adventurer
        );
    }


    // TODO for Milestone1
    // write beast update to chain
    // write adventurer update to chain

    return ();
}


// TODO MILESTONE1: Change this function to take in beast tokenId instead of adventurer tokenId
//                  as its more intuitive from a client perspective
@external
func flee{syscall_ptr: felt*, range_check_ptr}(adventurer_id: Uint256) {
    alloc_locals;

    let (caller) = get_caller_address();
    let (owner) = IAdventurer.ownerOf(adventurer_id);

    with_attr error_message("Beast: Only adventurer owner can flee") {
        assert caller = owner;
    }

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);

    let (unpacked_adventurer) = IAdventurer.getAdventurerById(adventurer_address, adventurer_id);

    with_attr error_message("Beast: Adventurer must be in a battle to flee") {
        assert unpacked_adventurer.Status = AdventurerStatus.Battle;
    }

    let (beast: Beast) = getBeastById(unpacked_adventurer.beast);   

    // Adventurer Speed is Dexterity - Weight of all equipped items
    // TODO: Provide utility function that takes in an adventurer and returns net weight of gear
    //       For now just hard_code this weight:
    let (weight_of_equipment) = 3;
    let (adventurer_speed) = unpacked_adventurer.Dexterity - weight_of_equipment;

    // Adventurer ambush resistance is based on wisdom plus luck
    let (ambush_resistance) = unpacked_adventurer.Wisdom + unpacked_adventurer.Luck;

    // Generate random number which will determine:
    // 1. Chance of adventurer getting ambushed (i.e attacked before they can start to flee)
    // 2. Chance of adventurer successfully fleeing
    let (controller) = Module.controller_address();
    let (xoroshiro_address_) = IModuleController.get_xoroshiro(controller);
    let (rnd) = IXoroshiro.next(xoroshiro_address_);
    let (_, r) = unsigned_div_rem(rnd, 20);

    // TODO Milestone2: Factor in beast health for the ambush chance and for flee chance
    // Short-term (while we are using rng) would be to base rng on beast health. The 
    // lower the beast health, the lower the chance it will ambush and the easier
    // it will be to flee.

    // adventurer is ambushed if their ambush resistance is less than random number
    let is_ambushed = is_le(ambush_resistance, r);

    // default damage when fleeing is 0 (i.e no ambush)
    let damage_taken = 0;

    // if adventurer gets ambushed
    if (is_ambushed == TRUE) {
        // calculate damage from the attack
        // get the beast the adventurer is currently battling
        let (damage_taken) = CombatStats.calculate_damage_from_beast(beast, Adventurer.ChestId);

        // and deduct health from the adventurer
        let (unpacked_adventurer: AdventurerState) = IAdventurer.deductHealth(
            adventurer_address, adventurer_id, damage_taken
        );
    }

    // Adventurer getting ambushed and being able to flee are separate mechanisms
    // Currently we are using the same random number for both of these but
    // the adventurer avoiding ambush is based on mental stats, while fleeing
    // is based on physical stats. Eventually I think instead of using a random number
    // for the beast side of the equation, beasts should also have mental and physical stats
    // just like adventurers.

    // for now, if random number if less than adventurer speed (i.e if adventurer is faster than the beast)
    let (can_flee) = is_le(r, adventurer_speed);

    // if the adventurer is able to flee
    if (can_flee == TRUE) {
        // set adventurer status back to idl
        let (unpacked_adventurer: AdventurerState) = AdventurerLib.cast_state(
            AdventurerSlotIds.Status, AdventurerStatus.Idle, unpacked_adventurer
        );

        // and beast to 0 to indicate they aren't associated with a beast
        let (unpacked_adventurer: AdventurerState) = AdventurerLib.cast_state(
            AdventurerSlotIds.Beast, 0, unpacked_adventurer
        );

        // zero out the adventurer tokenId on the beast to indicate it's no longer being attacked
        beast.Adventuer = 0;
    }

    // return adventurer
    return (unpacked_adventurer,);
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

// @view
// func getBeastForAdventurer{
//         pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
// }(adventurer_id: Uint256) -> (unpacked_beast: Beast) {
//     let (adventurer_data) = IAdventurer
// }

func get_random_beast_id{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}() -> (
    dice_roll: felt
) {
    alloc_locals;

    let (controller) = Module.controller_address();
    let (xoroshiro_address_) = IModuleController.get_xoroshiro(controller);
    let (rnd) = IXoroshiro.next(xoroshiro_address_);
    let (_, r) = unsigned_div_rem(rnd, BeastConstants.MaxBeastId);
    return (r + 1,);  // values from 1 to 18 inclusive
}

// --------------------
// Base ERC721 Functions
// --------------------

@view
func totalSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply: Uint256) = ERC721Enumerable.total_supply();
    return (totalSupply,);
}