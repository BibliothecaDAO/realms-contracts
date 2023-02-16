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
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_not_equal, assert_nn
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_eq
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp

from openzeppelin.upgrades.library import Proxy
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable

from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.library.library_module import Module
from contracts.loot.adventurer.interface import IAdventurer
from contracts.loot.adventurer.library import AdventurerLib
from contracts.loot.beast.stats.beast import BeastStats
from contracts.loot.beast.library import BeastLib
from contracts.loot.constants.adventurer import (
    Adventurer,
    AdventurerState,
    AdventurerStatus,
    AdventurerSlotIds,
)
from contracts.loot.constants.beast import Beast, BeastStatic, BeastDynamic
from contracts.loot.interfaces.imodules import IModuleController
from contracts.loot.loot.ILoot import ILoot
from contracts.loot.loot.stats.combat import CombatStats
from contracts.loot.utils.constants import ModuleIds, ExternalContractIds

// -----------------------------------
// Events
// -----------------------------------

@event
func NewBeastState(beast_token_id: Uint256, beast_state: Beast) {
}

@event
func BeastLevelUp(beast_token_id: Uint256, beast_state: Beast) {
}

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
    address_of_controller: felt, proxy_admin: felt
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

// -----------------------------
// External
// -----------------------------

// @notice Create a beast and attach to adventurer
// @param adventurer_id: Id of adventurer
// @return beast_token_id: Id of beast
@external
func create{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_id: Uint256) -> (beast_token_id: Uint256) {
    alloc_locals;
    Module.only_approved();

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);
    let (adventurer_state) = IAdventurer.get_adventurer_by_id(adventurer_address, adventurer_id);

    let (rnd) = get_random_number();
    let (beast_static_, beast_dynamic_) = BeastLib.create(rnd, adventurer_id.low, adventurer_state);
    let (packed_beast) = BeastLib.pack(beast_dynamic_);
    let (current_id) = total_supply.read();
    let (next_id, _) = uint256_add(current_id, Uint256(1, 0));
    beast_static.write(next_id, beast_static_);
    beast_dynamic.write(next_id, packed_beast);
    total_supply.write(next_id);
    return (next_id,);
}

// @notice Attack a beast with an adventurer, if beast not killed counter attack
// @param beast_token_id: Id of beast
@external
func attack{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_token_id: Uint256) -> (damage_to_beast: felt, damage_from_beast: felt) {
    alloc_locals;

    let (beast) = get_beast_by_id(beast_token_id);
    let adventurer_id = Uint256(beast.Adventurer, 0);
    assert_adventurer_owner(adventurer_id);

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);
    let (unpacked_adventurer) = get_adventurer_from_beast(beast_token_id);

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
    let (weapon) = ILoot.get_item_by_token_id(item_address, Uint256(unpacked_adventurer.WeaponId, 0));
    let (damage_dealt) = CombatStats.calculate_damage_to_beast(beast, weapon, unpacked_adventurer);
    // deduct health from beast
    let (beast_static_, beast_dynamic_) = BeastLib.split_data(beast);
    let (updated_health_beast) = BeastLib.deduct_health(damage_dealt, beast_dynamic_);
    let (packed_beast) = BeastLib.pack(updated_health_beast);
    beast_dynamic.write(beast_token_id, packed_beast);
    emit_beast_state(beast_token_id);

    // check if beast is still alive after the attack
    let beast_is_alive = is_not_zero(updated_health_beast.Health);

    // if the beast is alive
    if (beast_is_alive == TRUE) {
        // having been attacked, it automatically attacks back
        let (chest) = ILoot.get_item_by_token_id(item_address, Uint256(unpacked_adventurer.ChestId, 0));
        let (damage_taken) = CombatStats.calculate_damage_from_beast(beast, chest, unpacked_adventurer);

        IAdventurer.deduct_health(adventurer_address, adventurer_id, damage_taken);

        // check if beast counter attack killed adventurer
        let (updated_adventurer) = get_adventurer_from_beast(beast_token_id);
        // if the adventurer is dead
        if (updated_adventurer.Health == 0) {
            // calculate xp earned from killing adventurer (adventurers are rank 1)
            let (xp_gained) = CombatStats.calculate_xp_earned(1, updated_adventurer.Level);
            // increase beast xp and writes
            _increase_xp(beast_token_id, updated_health_beast, xp_gained);
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

        return (damage_dealt, damage_taken);
    } else {
        // update beast with slain details
        let (current_time) = get_block_timestamp();
        let (slain_updated_beast) = BeastLib.slay(current_time, updated_health_beast);

        // grant adventurer xp
        let (beast_level) = BeastLib.calculate_greatness(slain_updated_beast.Level);
        let (beast_rank) = BeastStats.get_rank_from_id(beast.Id);
        let (xp_gained) = CombatStats.calculate_xp_earned(beast_rank, beast_level);

        IAdventurer.increase_xp(adventurer_address, adventurer_id, xp_gained);

        // drop gold
        // TODO: Make dynamic somehow...
        // @distracteddev: add randomness to reward
        // formula: (xp_gained  - (xp_gained / 4)) * (rand % 4)
        let (rnd) = get_random_number();
        let (gold_reward) = BeastLib.calculate_gold_reward(rnd, xp_gained);
        _add_to_balance(adventurer_id, gold_reward);
        return (damage_dealt, 0);
    }
}

// @notice Counter attack an adventurer
// @param beast_token_id: Id of beast
@external
func counter_attack{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_token_id: Uint256) -> (damage: felt) {
    alloc_locals;

    Module.only_approved();

    let ZERO = Uint256(0, 0);

    with_attr error_message("Beast: Must provide non-zero beast token id") {
        let (is_beast_token_zero) = uint256_eq(beast_token_id, ZERO);
        assert is_beast_token_zero = FALSE;
    }

    // get address for Loot items
    let (item_address) = Module.get_module_address(ModuleIds.Loot);
    // get address for Adventurer
    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);

    // get beast from token id
    let (beast) = get_beast_by_id(beast_token_id);
    // get the adventurer token id associated with the beast
    let adventurer_token_id = Uint256(beast.Adventurer, 0);

    // verify adventurer is in battle mode
    with_attr error_message("Beast: Adventurer token id is zero") {
        let (is_adventurer_token_zero) = uint256_eq(adventurer_token_id, ZERO);
        assert is_adventurer_token_zero = FALSE;
    }

    // retreive unpacked adventurer
    let (unpacked_adventurer) = get_adventurer_from_beast(beast_token_id);
    let (chest) = ILoot.get_item_by_token_id(item_address, Uint256(unpacked_adventurer.ChestId, 0));
    let (damage_taken) = CombatStats.calculate_damage_from_beast(beast, chest, unpacked_adventurer);

    IAdventurer.deduct_health(adventurer_address, adventurer_token_id, damage_taken);
    // check if beast counter attack killed adventurer
    let (updated_adventurer) = get_adventurer_from_beast(beast_token_id);
    // if the adventurer is dead
    if (updated_adventurer.Health == 0) {
        // calculate xp earned from killing adventurer (adventurers are rank 1)
        let (xp_gained) = CombatStats.calculate_xp_earned(1, updated_adventurer.Level);
        // increase beast xp and writes
        let (_, beast_dynamic_) = BeastLib.split_data(beast);
        _increase_xp(beast_token_id, beast_dynamic_, xp_gained);

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

    return (damage_taken,);
}

// @notice Flee adventurer from beast
// @param beast_token_id: Id of beast
@external
func flee{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_token_id: Uint256) -> (fled: felt) {
    alloc_locals;

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);

    let (beast) = get_beast_by_id(beast_token_id);

    assert_adventurer_owner(Uint256(beast.Adventurer, 0));

    let (unpacked_adventurer) = IAdventurer.get_adventurer_by_id(
        adventurer_address, Uint256(beast.Adventurer, 0)
    );

    with_attr error_message("Beast: Adventurer must be in a battle") {
        assert unpacked_adventurer.Status = AdventurerStatus.Battle;
    }

    // Adventurer Speed is Dexterity - Weight of all equipped items
    // TODO: We need a function to calculate the weight of all the adventurer equipment
    let weight_of_equipment = 0;

    let adventurer_speed = unpacked_adventurer.Dexterity - weight_of_equipment;
    assert_nn(adventurer_speed);

    let (rnd) = get_random_number();

    // TODO Milestone2: Factor in beast health for the ambush chance and for flee chance
    // Short-term (while we are using rng) would be to base rng on beast health. The
    // lower the beast health, the lower the chance it will ambush and the easier
    // it will be to flee.
    // @distracteddev: simple calculation, random: (0,1) * (health/50): (0, 1, 2)
    let (ambush_chance) = BeastLib.calculate_ambush_chance(rnd, beast.Health);

    // Adventurer ambush resistance is based on wisdom plus luck
    let ambush_resistance = unpacked_adventurer.Wisdom + unpacked_adventurer.Luck;

    // adventurer is ambushed if their ambush resistance is less than random number
    let is_ambushed = is_le(ambush_chance, ambush_resistance);

    let (item_address) = Module.get_module_address(ModuleIds.Loot);

    // unless ambush occurs
    if (is_ambushed == TRUE) {
        let (chest) = ILoot.get_item_by_token_id(item_address, Uint256(unpacked_adventurer.ChestId, 0));
        // then calculate damage based on beast
        let (damage_taken) = CombatStats.calculate_damage_from_beast(beast, chest, unpacked_adventurer);
        IAdventurer.deduct_health(adventurer_address, Uint256(beast.Adventurer, 0), damage_taken);
        // check if beast counter attack killed adventurer
        let (updated_adventurer) = get_adventurer_from_beast(beast_token_id);
        // if the adventurer is dead
        if (updated_adventurer.Health == 0) {
            // calculate xp earned from killing adventurer (adventurers are rank 1)
            let (xp_gained) = CombatStats.calculate_xp_earned(1, updated_adventurer.Level);
            // increase beast xp and writes
            let (_, beast_dynamic_) = BeastLib.split_data(beast);
            _increase_xp(beast_token_id, beast_dynamic_, xp_gained);

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

    // TODO: MILESTONE2 Use Beast Speed Stats
    let (flee_chance) = BeastLib.get_random_flee(rnd);
    let can_flee = is_le(adventurer_speed + 1, flee_chance);
    if (can_flee == TRUE) {
        IAdventurer.update_status(
            adventurer_address, Uint256(beast.Adventurer, 0), AdventurerStatus.Idle
        );
        IAdventurer.assign_beast(adventurer_address, Uint256(beast.Adventurer, 0), 0);
        return (TRUE,);
    } else {
        return (FALSE,);
    }
}

// --------------------
// Setters
// --------------------

// @notice Set beast data by id
// @param token_id: Id of beast
// @param beast: Beast data from id
@external
func set_beast_by_id{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(token_id: Uint256, beast: Beast) {
    Module.only_approved();
    let (beast_static_, beast_dynamic_) = BeastLib.split_data(beast);
    let (packed_beast: felt) = BeastLib.pack(beast_dynamic_);
    beast_static.write(token_id, beast_static_);
    beast_dynamic.write(token_id, packed_beast);
    return ();
}

// --------------------
// Internal
// --------------------

// @notice increases the xp of the beast and increases level if appropriate
// @param: beast_token_id: token id of the beast
// @param: beast_dynamic_: of the beast you want to increase xp
// @return returned_beast_dynamic: an updated version of the provided beast
@external
func increase_xp{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_token_id: Uint256, beast_dynamic_: BeastDynamic, amount: felt) -> (
    returned_beast_dynamic: BeastDynamic
) {
    alloc_locals;

    Module.only_approved();

    return _increase_xp(beast_token_id, beast_dynamic_, amount);
}


func _increase_xp{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_token_id: Uint256, beast_dynamic_: BeastDynamic, amount: felt) -> (
    returned_beast_dynamic: BeastDynamic
) {
    alloc_locals;

    // increase beast xp
    let (updated_xp_beast) = BeastLib.increase_xp(amount, beast_dynamic_);

    // check if beast has reached the next level
    let (leveled_up) = CombatStats.check_for_level_increase(
        updated_xp_beast.XP, updated_xp_beast.Level
    );
    // if so
    if (leveled_up == TRUE) {
        let (updated_level_beast) = BeastLib.update_level(
            updated_xp_beast.Level + 1, updated_xp_beast
        );
        // pack beast for storage
        let (packed_beast) = BeastLib.pack(updated_level_beast);
        // write beast to chain
        beast_dynamic.write(beast_token_id, packed_beast);
        // emit beast level up event
        emit_beast_level_up(beast_token_id);
        // return the updated beast
        return (updated_level_beast,);
    } else {
        // pack beast for storage
        let (packed_beast) = BeastLib.pack(updated_xp_beast);
        // write beast to chain
        beast_dynamic.write(beast_token_id, packed_beast);
        // emit beast level up event
        emit_beast_state(beast_token_id);
        // return the updated beast
        return (updated_xp_beast,);
    }
}

// @notice Get xiroshiro random number
// @return dice_roll: Random number
func get_random_number{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}() -> (
    dice_roll: felt
) {
    alloc_locals;

    let (controller) = Module.controller_address();
    let (xoroshiro_address_) = IModuleController.get_xoroshiro(controller);
    let (rnd) = IXoroshiro.next(xoroshiro_address_);
    return (rnd,);
}

// @notice Revert if caller is not adventurer owner
// @param: adventurer_id: Id of adventurer
func assert_adventurer_owner{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_id: Uint256) {
    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);

    let (caller) = get_caller_address();
    let (owner) = IAdventurer.owner_of(adventurer_address, adventurer_id);

    with_attr error_message("Beast: Only adventurer owner can attack") {
        assert caller = owner;
    }
    return ();
}

// @notice Emit beast data
// @param: token_id: Id of beast
func emit_beast_state{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_token_id: Uint256) {
    // Get the beast
    let (beast) = get_beast_by_id(beast_token_id);
    NewBeastState.emit(beast_token_id, beast);
    return ();
}

// @notice Emit beast data
// @param: token_id: Id of beast
func emit_beast_level_up{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_token_id: Uint256) {
    // Get beast and emit level up event with beast details
    let (beast) = get_beast_by_id(beast_token_id);
    BeastLevelUp.emit(beast_token_id, beast);
    return ();
}

// --------------------
// Getters
// --------------------

// @notice Get beast data from id
// @param beast_token_id: The token id for the beast
// @return beast: The data of the beast
@view
func get_beast_by_id{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_token_id: Uint256) -> (beast: Beast) {
    alloc_locals;

    let (beast_static_) = beast_static.read(beast_token_id);
    let (packed_beast) = beast_dynamic.read(beast_token_id);

    // unpack
    let (unpacked_beast: BeastDynamic) = BeastLib.unpack(packed_beast);

    let (beast) = BeastLib.aggregate_data(beast_static_, unpacked_beast);

    return (beast,);
}

// @notice Get adventurer from beast id
// @param beast_token_id: The token id for the beast you want the adventurer for
// @return adventurer_state: The unpacked adventurer state associated with the beast token id
@view
func get_adventurer_from_beast{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_token_id: Uint256) -> (adventurerState: AdventurerState) {
    alloc_locals;

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);
    let (beast) = get_beast_by_id(beast_token_id);
    let adventurer_id = Uint256(beast.Adventurer, 0);
    let (adventurer_state) = IAdventurer.get_adventurer_by_id(adventurer_address, adventurer_id);
    return (adventurer_state,);
}

@view
func get_total_supply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    total_supply: Uint256
) {
    let (total_supply: Uint256) = ERC721Enumerable.total_supply();
    return (total_supply,);
}

// gold functions

@storage_var
func goldBalance(tokenId: Uint256) -> (balance: felt) {
}

@storage_var
func worldSupply() -> (balance: felt) {
}

@external
func add_to_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_token_id: Uint256, addition: felt
) {
    Module.only_approved();

    _add_to_balance(adventurer_token_id, addition);
    return ();
}

func _add_to_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_token_id: Uint256, addition: felt
) {
    let (current_balance) = balance_of(adventurer_token_id);

    goldBalance.write(adventurer_token_id, current_balance + addition);

    let (supply) = worldSupply.read();
    worldSupply.write(supply + addition);

    return ();
}

@external
func subtract_from_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_token_id: Uint256, subtraction: felt
) {
    Module.only_approved();

    _subtract_from_balance(adventurer_token_id, subtraction);

    return ();
}

func _subtract_from_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_token_id: Uint256, subtraction: felt
) {
    let (current_balance) = balance_of(adventurer_token_id);

    let negative = is_le(current_balance - subtraction, 0);

    // add in overflow assert so you can't spend more than what you have.
    with_attr error_message("Beast: Not enough gold in balance.") {
        assert negative = FALSE;
    }

    goldBalance.write(adventurer_token_id, current_balance - subtraction);

    let (supply) = worldSupply.read();
    let new_supply = supply - subtraction;
    assert_nn(new_supply);
    worldSupply.write(supply - subtraction);

    return ();
}

@view
func balance_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_token_id: Uint256
) -> (balance: felt) {
    return goldBalance.read(adventurer_token_id);
}

@view
func get_world_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (balance: felt) {
    return worldSupply.read();
}
