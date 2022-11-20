// -----------------------------------
//   Module.Beast
//   Beast logic
//
//
//
// -----------------------------------

%lang starknet
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_not_equal
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
from contracts.loot.constants.adventurer import Adventurer, AdventurerState, AdventurerStatus, AdventurerSlotIds
from contracts.loot.constants.beast import Beast
from contracts.loot.interfaces.imodules import IModuleController
from contracts.loot.loot.ILoot import ILoot
from contracts.loot.loot.stats.combat import CombatStats
from contracts.loot.utils.constants import ModuleIds, ExternalContractIds


// -----------------------------------
// Events
// -----------------------------------

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func beast_static(tokenId: Uint256) -> (beast: BeastStatic) {
}

@storage_var
func beast_dynamic(tokenId: Uint256) -> (packed_beast: felt) {
}

@storage_var
func total_supply() -> (res: Uint256) {
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
func create{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_id: Uint256) -> (beast_id: Uint256) {
    Module.only_approved();
    let (controller) = Module.controller_address();
    let (xoroshiro_address_) = IModuleController.get_xoroshiro(controller);
    let (rnd) = IXoroshiro.next(xoroshiro_address_);
    let (beast_static, beast_dynamic) = BeastLib.create(rnd);
    let (packed_beast) = BeastLib.pack(beast_dynamic);

    with_attr error_message("Beast: Can't set beast adventurer to same value as current") {
        assert_not_equal(adventurer_id, unpacked_beast.adventurer);
    }

    let (current_id) = total_supply.read();
    let next_id = uint256_add(current_id, Uint256(1,0));
    beast_static.write(next_id, beast_static);
    beast_dynamic.write(next_id, beast_dynamic);
    return (next_id,);
}

@external
func attack{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_id: Uint256) {
    alloc_locals;

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);

    let (caller) = get_caller_address();
    let (owner) = IAdventurer.ownerOf(adventurer_address, adventurer_id);

    with_attr error_message("Beast: Only adventurer owner can attack") {
        assert caller = owner;
    }

    let (unpacked_adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, adventurer_id);

    with_attr error_message("Beast: Adventurer must be in a battle") {
        assert unpacked_adventurer.Status = AdventurerStatus.Battle;
    }

    let (beast_: Beast) = get_beast_by_id(beast_id);

    let (item_address) = Module.get_module_address(ModuleIds.Loot);

    let (weapon) = ILoot.getItemByTokenId(item_address, Uint256(unpacked_adventurer.WeaponId, 0));

    let (damage_dealt) = CombatStats.calculate_damage_to_beast(beast_, weapon);

    // check if damage dealt is less than health remaining
    let still_alive = is_le(damage_dealt, beast_.Health);

    // deduct health from beast
    let (updated_beast) = BeastLib.deduct_health(damage_dealt, beast_);

    let (packed_beast) = BeastLib.pack(updated_beast);

    beast.write(unpacked_adventurer.Beast, packed_beast);

    // if the beast is alive
    if (still_alive == TRUE) {
        // having been attacked, it automatically attacks back
        let (chest) = ILoot.getItemByTokenId(item_address, Uint256(unpacked_adventurer.ChestId, 0));
        let (damage_taken) = CombatStats.calculate_damage_from_beast(updated_beast, chest);
        IAdventurer.deduct_health(adventurer_address, adventurer_id, damage_taken);
    } else {
        // if beast has been slain, grant adventurer xp
        let (beast_greatness) = BeastLib.calculate_greatness(updated_beast.XP);
        let xp_gained = updated_beast.Rank * beast_greatness;
        IAdventurer.increase_xp(adventurer_address, adventurer_id, xp_gained);
    }

    return ();
}


@external
func flee{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_id: Uint256) {
    alloc_locals;

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);

    let (caller) = get_caller_address();
    let (owner) = IAdventurer.ownerOf(adventurer_address, adventurer_id);

    with_attr error_message("Beast: Only adventurer owner can flee") {
        assert caller = owner;
    }

    let (unpacked_adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, adventurer_id);

    with_attr error_message("Beast: Adventurer must be in a battle") {
        assert unpacked_adventurer.Status = AdventurerStatus.Battle;
    }

    let (beast: Beast) = getBeastById(beast_id);   

    // Adventurer Speed is Dexterity - Weight of all equipped items
    let weight_of_equipment = 3;
    let adventurer_speed = unpacked_adventurer.Dexterity - weight_of_equipment;

    // Adventurer ambush resistance is based on wisdom plus luck
    let ambush_resistance = unpacked_adventurer.Wisdom + unpacked_adventurer.Luck;

    // Generate random number which will determine:
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

    let (item_address) = Module.get_module_address(ModuleIds.Loot);

    // unless ambush occurs
    if (is_ambushed == TRUE) {
        let (beast_: Beast) = get_beast_by_id(unpacked_adventurer.Beast);
        let (chest) = ILoot.getItemByTokenId(item_address, Uint256(unpacked_adventurer.ChestId, 0));
        // then calculate damage based on beast
        let (damage_taken) = CombatStats.calculate_damage_from_beast(beast_, chest);
        IAdventurer.deduct_health(adventurer_address, adventurer_id, damage_taken);

        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
    } else {
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
    }

    let can_flee = is_le(rnd, adventurer_speed);
    if (can_flee == TRUE) {
        IAdventurer.update_status(adventurer_address, adventurer_id, AdventurerStatus.Idle);
        return ();
    }

    return ();
}

// --------------------
// Setters
// --------------------

@external
func set_beast_by_id{
        pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: felt, beast_: Beast) {
    let (packed_beast: felt) = BeastLib.pack(beast_);
    beast.write(tokenId, packed_beast);
    return ();
}

// --------------------
// Getters
// --------------------

@view
func get_beast_by_id{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(tokenId: felt) -> (beast: Beast) {
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