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
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp

from openzeppelin.upgrades.library import Proxy
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable

from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.library.library_module import Module
from contracts.loot.adventurer.interface import IAdventurer
from contracts.loot.adventurer.library import AdventurerLib
from contracts.loot.beast.stats.beast import BeastStats
from contracts.loot.beast.library import BeastLib
from contracts.loot.constants.adventurer import Adventurer, AdventurerState, AdventurerStatus, AdventurerSlotIds
from contracts.loot.constants.beast import Beast, BeastStatic, BeastDynamic
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
    let (rnd) = get_random_number();
    let (beast_static_, beast_dynamic_) = BeastLib.create(rnd, adventurer_id.low);
    let (packed_beast) = BeastLib.pack(beast_dynamic_);
    let (current_id) = total_supply.read();
    let (next_id, _) = uint256_add(current_id, Uint256(1,0));
    beast_static.write(next_id, beast_static_);
    beast_dynamic.write(next_id, packed_beast);
    total_supply.write(next_id);
    return (next_id,);
}

@external
func attack{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_id: Uint256) {
    alloc_locals;

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);
    let (beast) = get_beast_by_id(beast_id);
    let adventurer_id = Uint256(beast.Adventurer, 0);
    assert_adventurer_owner(adventurer_id);

    let (unpacked_adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, adventurer_id);

    // verify adventurer is in battle mode
    with_attr error_message("Beast: Adventurer must be in a battle") {
        assert unpacked_adventurer.Status = AdventurerStatus.Battle;
    }

    // verify it's not already dead
    with_attr error_message("Beast: Cannot attack a dead beast") {
        assert_not_zero(beast.Health);
    }

    // calculate damage
    let (item_address) = Module.get_module_address(ModuleIds.Loot);
    let (weapon) = ILoot.getItemByTokenId(item_address, Uint256(unpacked_adventurer.WeaponId, 0));
    let (damage_dealt) = CombatStats.calculate_damage_to_beast(beast, weapon);
    // deduct health from beast
    let (beast_static_, beast_dynamic_) = BeastLib.split_data(beast);
    let (updated_health_beast) = BeastLib.deduct_health(damage_dealt, beast_dynamic_);
    let (packed_beast) = BeastLib.pack(updated_health_beast);
    let (new_beast_) = BeastLib.aggregate_data(beast_static_, updated_health_beast);

    // check if beast is still alive after the attack
    let still_alive = is_not_zero(updated_health_beast.Health);

    // if the beast is alive
    if (still_alive == TRUE) {
        // having been attacked, it automatically attacks back
        let (chest) = ILoot.getItemByTokenId(item_address, Uint256(unpacked_adventurer.ChestId, 0));
        let (damage_taken) = CombatStats.calculate_damage_from_beast(new_beast_, chest);
        IAdventurer.deduct_health(adventurer_address, adventurer_id, damage_taken);
        return ();
    // } else {
    //     // update beast with slain details
    //     let (current_time) = get_block_timestamp();
    //     let (slain_updated_beast) = BeastLib.slay(adventurer_id.low, current_time, updated_health_beast); 
    //     let (new_packed_beast) = BeastLib.pack(updated_health_beast);
    //     beast_dynamic.write(beast_id, new_packed_beast);
    //     // grant adventurer xp
    //     let (beast_greatness) = BeastLib.calculate_greatness(slain_updated_beast.XP);
    //     let (rank) = BeastStats.get_rank_from_id(new_beast_.Id);
    //     let xp_gained = rank * beast_greatness;
    //     IAdventurer.increase_xp(adventurer_address, adventurer_id, xp_gained);
    //     return ();
    // }
    }

    return ();
}

@external
func flee{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_id: Uint256) {
    alloc_locals;

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);

    let (beast) = get_beast_by_id(beast_id);

    assert_adventurer_owner(Uint256(beast.Adventurer, 0));

    let (unpacked_adventurer) = IAdventurer.get_adventurer_by_id(adventurer_address, Uint256(beast.Adventurer, 0));

    with_attr error_message("Beast: Adventurer must be in a battle") {
        assert unpacked_adventurer.Status = AdventurerStatus.Battle;
    }  

    // TODO: calculate accurate rng for ambush and fleeing

    // Adventurer Speed is Dexterity - Weight of all equipped items
    let weight_of_equipment = 3;
    let adventurer_speed = unpacked_adventurer.Dexterity - weight_of_equipment;

    // Adventurer ambush resistance is based on wisdom plus luck
    let ambush_resistance = unpacked_adventurer.Wisdom + unpacked_adventurer.Luck;

    let (rnd) = get_random_number();
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
        let (chest) = ILoot.getItemByTokenId(item_address, Uint256(unpacked_adventurer.ChestId, 0));
        // then calculate damage based on beast
        let (damage_taken) = CombatStats.calculate_damage_from_beast(beast, chest);
        IAdventurer.deduct_health(adventurer_address, Uint256(beast.Adventurer, 0), damage_taken);

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
        IAdventurer.update_status(adventurer_address, Uint256(beast.Adventurer, 0), AdventurerStatus.Idle);
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
}(token_id: Uint256, beast: Beast) {
    // Module.only_approved();
    let (beast_static_, beast_dynamic_) = BeastLib.split_data(beast);
    let (packed_beast: felt) = BeastLib.pack(beast_dynamic_);
    beast_static.write(token_id, beast_static_);
    beast_dynamic.write(token_id, packed_beast);
    return ();
}

// --------------------
// Internal
// --------------------

func get_random_number{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}() -> (
    dice_roll: felt
) {
    alloc_locals;

    let (controller) = Module.controller_address();
    let (xoroshiro_address_) = IModuleController.get_xoroshiro(controller);
    let (rnd) = IXoroshiro.next(xoroshiro_address_);
    return (rnd,);
}

func assert_adventurer_owner{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_id: Uint256) {
    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);

    let (caller) = get_caller_address();
    let (owner) = IAdventurer.ownerOf(adventurer_address, adventurer_id);

    with_attr error_message("Beast: Only adventurer owner can attack") {
        assert caller = owner;
    }
    return ();
}

// --------------------
// Getters
// --------------------

@view
func get_beast_by_id{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(token_id: Uint256) -> (beast: Beast) {
    alloc_locals;

    let (beast_static_) = beast_static.read(token_id);
    let (packed_beast) = beast_dynamic.read(token_id);

    // unpack
    let (unpacked_beast: BeastDynamic) = BeastLib.unpack(packed_beast);

    let (beast) = BeastLib.aggregate_data(beast_static_, unpacked_beast);

    return (beast,);
}

@view
func get_total_supply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    total_supply: Uint256
) {
    let (total_supply: Uint256) = ERC721Enumerable.total_supply();
    return (total_supply,);
}