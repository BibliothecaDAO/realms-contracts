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
from starkware.cairo.common.math import (
    unsigned_div_rem,
    assert_not_zero,
    assert_not_equal,
    assert_nn,
)
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_eq
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_number,
    get_block_timestamp,
)

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
    AdventurerDynamic,
    AdventurerStatus,
    AdventurerSlotIds,
)
from contracts.loot.constants.beast import Beast, BeastStatic, BeastDynamic, BeastIds
from contracts.loot.interfaces.imodules import IModuleController
from contracts.loot.loot.ILoot import ILoot
from contracts.loot.loot.stats.combat import CombatStats
from contracts.loot.utils.constants import ModuleIds, ExternalContractIds
from contracts.loot.constants.item import (
    ITEM_XP_MULTIPLIER,
    ITEM_NAME_SUFFIXES_COUNT,
    ITEM_NAME_PREFIXES_COUNT,
)

// -----------------------------------
// Events
// -----------------------------------

@event
func CreateBeast(beast_token_id: Uint256, beast_state: Beast) {
}

@event
func UpdateBeastState(beast_token_id: Uint256, beast_state: Beast) {
}

@event
func BeastLevelUp(beast_token_id: Uint256, beast_level: felt) {
}

@event
func BeastAttacked(
    beast_token_id: Uint256,
    adventurer_token_id: Uint256,
    damage: felt,
    beast_health: felt,
    xp_gained: felt,
    gold_reward: felt,
) {
}

@event
func AdventurerAttacked(
    beast_token_id: Uint256,
    adventurer_token_id: Uint256,
    damage: felt,
    adventurer_health: felt,
    xp_gained: felt,
    gold_reward: felt,
) {
}

@event
func FledBeast(beast_token_id: Uint256, adventurer_token_id: Uint256) {
}

@event
func AdventurerAmbushed(
    beast_token_id: Uint256, adventurer_token_id: Uint256, damage: felt, adventurer_health: felt
) {
}

@event
func UpdateGoldBalance(adventurer_token_id: Uint256, balance: felt) {
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
// @param adventurer_token_id: Id of adventurer
// @return beast_token_id: Id of beast
@external
func create{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256) -> (
    beast_token_id: Uint256, adventurer_dynamic: AdventurerDynamic
) {
    alloc_locals;
    Module.only_approved();

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);
    let (adventurer_state) = IAdventurer.get_adventurer_by_id(
        adventurer_address, adventurer_token_id
    );

    let (random) = get_random_number();

    let (beast_level_multi, _) = unsigned_div_rem(adventurer_state.Level, 5);
    let beast_level_range = (1 + beast_level_multi) * 4;
    let beast_health_range = (1 + beast_level_multi) * 15;

    let (_, beast_level_boost) = unsigned_div_rem(random, beast_level_range);
    let (_, beast_health_boost) = unsigned_div_rem(random, beast_health_range);
    let (_, beast_id) = unsigned_div_rem(random, BeastIds.MAX_ID);
    let (_, beast_name_prefix) = unsigned_div_rem(random, ITEM_NAME_PREFIXES_COUNT);
    let (_, beast_name_suffix) = unsigned_div_rem(random, ITEM_NAME_SUFFIXES_COUNT);

    let (beast_static_, beast_dynamic_) = BeastLib.create(
        beast_id,
        adventurer_token_id.low,
        adventurer_state,
        beast_level_boost,
        beast_health_boost,
        beast_name_prefix + 1,
        beast_name_suffix + 1,
    );

    let (beast_token_id) = _create(beast_static_, beast_dynamic_);

    let (return_adventurer) = process_ambush(
        adventurer_address, adventurer_token_id, adventurer_state, beast_token_id
    );

    return (beast_token_id, return_adventurer);
}

@external
func create_starting_beast{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, beast_id: felt) -> (beast_token_id: Uint256) {
    alloc_locals;
    Module.only_approved();

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);
    let (adventurer_state) = IAdventurer.get_adventurer_by_id(
        adventurer_address, adventurer_token_id
    );

    let (beast_static_, beast_dynamic_) = BeastLib.create_start_beast(
        beast_id, adventurer_token_id.low, adventurer_state
    );

    return _create(beast_static_, beast_dynamic_);
}

func _create{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_static_: BeastStatic, beast_dynamic_: BeastDynamic) -> (beast_token_id: Uint256) {
    alloc_locals;

    let (packed_beast) = BeastLib.pack(beast_dynamic_);

    let (current_id) = total_supply.read();

    let (next_id, _) = uint256_add(current_id, Uint256(1, 0));

    beast_static.write(next_id, beast_static_);

    beast_dynamic.write(next_id, packed_beast);

    total_supply.write(next_id);

    let (beast) = BeastLib.aggregate_data(beast_static_, beast_dynamic_);

    CreateBeast.emit(next_id, beast);

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
    let adventurer_token_id = Uint256(beast.Adventurer, 0);
    assert_adventurer_owner(adventurer_token_id);

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
    let (weapon) = ILoot.get_item_by_token_id(
        item_address, Uint256(unpacked_adventurer.WeaponId, 0)
    );
    let (rnd) = get_random_number();
    let (damage_dealt) = CombatStats.calculate_damage_to_beast(
        beast, weapon, unpacked_adventurer, rnd
    );
    // deduct health from beast
    let (beast_static_, beast_dynamic_) = BeastLib.split_data(beast);
    let (updated_health_beast) = BeastLib.deduct_health(damage_dealt, beast_dynamic_);
    let (packed_beast) = BeastLib.pack(updated_health_beast);
    beast_dynamic.write(beast_token_id, packed_beast);
    emit_beast_state(beast_token_id);

    // check if beast is still alive after the attack
    let beast_is_alive = is_not_zero(updated_health_beast.Health);

    // if the beast is alive, it automatically counter attacks
    if (beast_is_alive == TRUE) {
        BeastAttacked.emit(
            beast_token_id, adventurer_token_id, damage_dealt, updated_health_beast.Health, 0, 0
        );
        // get the location the beast attacks
        let (beast_attack_location) = BeastStats.get_attack_location_from_id(beast.Id);

        let (critical_damage_rnd) = get_random_number();

        // get the armor the adventurer is wearing at the location the beast attacks
        // @distracteddev: Should be get equipped item by slot not get item by Id
        let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(
            unpacked_adventurer
        );
        let (item_id) = AdventurerLib.get_item_id_at_slot(
            beast_attack_location, adventurer_dynamic_
        );
        let (armor) = ILoot.get_item_by_token_id(item_address, Uint256(item_id, 0));

        // adventurer level will be used for beast stats such as Luck
        let (damage_taken) = CombatStats.calculate_damage_from_beast(
            beast, armor, critical_damage_rnd, adventurer_dynamic_.Level
        );

        // deduct health from adventurer (this writes result to chain)
        let (updated_adventurer) = IAdventurer.deduct_health(
            adventurer_address, adventurer_token_id, damage_taken
        );

        // if the adventurer is dead
        if (updated_adventurer.Health == 0) {
            // grant xp to beast
            grant_beast_xp(adventurer_token_id, beast_token_id, beast, damage_taken);
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
        } else {
            AdventurerAttacked.emit(
                beast_token_id, adventurer_token_id, damage_taken, updated_adventurer.Health, 0, 0
            );
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
        let (packed_slain_beast) = BeastLib.pack(slain_updated_beast);
        beast_dynamic.write(beast_token_id, packed_slain_beast);

        // calculate earned XP
        let (beast_level) = BeastLib.calculate_greatness(slain_updated_beast.Level);
        let (beast_rank) = BeastStats.get_rank_from_id(beast.Id);

        // if the adventurer is level 1 we give them 10 XP to get them to level 2 after defeating their first beast
        if (unpacked_adventurer.Level == 1) {
            tempvar xp_gained = 10;
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
            // after level 1 XP earned is based on beast rank and level
        } else {
            let (xp_gained) = CombatStats.calculate_xp_earned(beast_rank, beast_level);
            tempvar xp_gained = xp_gained;
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
        }

        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;

        tempvar xp_gained_adventurer = xp_gained;
        // give xp to adventurer
        IAdventurer.increase_xp(adventurer_address, adventurer_token_id, xp_gained_adventurer);

        // and to items
        // items use a multplier of adventurer XP to allow them to level faster (3x at time of this writing)
        tempvar xp_gained_items = xp_gained_adventurer * ITEM_XP_MULTIPLIER;
        ILoot.allocate_xp_to_items(item_address, adventurer_token_id, xp_gained_items);

        // drop gold
        // @distracteddev: add randomness to reward
        // formula: (xp_gained  - (xp_gained / 4)) + ((xp_gained / 4) * (rand % 4))
        let (rnd) = get_random_number();
        let (gold_reward) = BeastLib.calculate_gold_reward(rnd, xp_gained_adventurer);
        _add_to_balance(adventurer_token_id, gold_reward);
        BeastAttacked.emit(
            beast_token_id,
            adventurer_token_id,
            damage_dealt,
            updated_health_beast.Health,
            xp_gained_adventurer,
            gold_reward,
        );

        IAdventurer.update_status(
            adventurer_address, Uint256(beast.Adventurer, 0), AdventurerStatus.Idle
        );
        IAdventurer.assign_beast(adventurer_address, Uint256(beast.Adventurer, 0), 0);

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
    let (damage) = _counter_attack(beast_token_id);
    return (damage,);
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

    //
    // Core Flee Logic
    //
    // TODO: Calculate the weight of all the adventurer equipment:
    // let weight_of_equipment = getEquipmentWeight(adventurer_token_id)
    // as part of the above, we need to add attack and defense modifier to heavier equipment to offset weight cost
    let weight_of_equipment = 0;

    // adventurer speed is dexterity minus weight of equipment
    let adventurer_speed = unpacked_adventurer.Dexterity - weight_of_equipment;
    assert_nn(adventurer_speed);

    // To see if adventurer can flee, we roll a dice
    let (flee_rnd) = get_random_number();
    // between zero and the adventurers level
    let (_, flee_chance) = unsigned_div_rem(flee_rnd, unpacked_adventurer.Level);

    // if the adventurers speed is greater than the dice roll
    let can_flee = is_le(flee_chance, adventurer_speed + 2);
    if (can_flee == TRUE) {
        // they get away so set their status back to idle
        IAdventurer.update_status(
            adventurer_address, Uint256(beast.Adventurer, 0), AdventurerStatus.Idle
        );
        // zero out the beast assigned to the adventurer
        IAdventurer.assign_beast(adventurer_address, Uint256(beast.Adventurer, 0), 0);

        FledBeast.emit(beast_token_id, Uint256(beast.Adventurer, 0));
        return (TRUE,);
    } else {
        // failing to flee results in beast counter attacking
        _counter_attack(beast_token_id);
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

// @notice A function that simulates a beast's counter-attack against an adventurer.
// @dev This function performs various checks and emits an event after the attack.//
// @param pedersen_ptr Reference to the Pedersen Hashing Engine.
// @param syscall_ptr Reference to the syscall interface.
// @param range_check_ptr Reference for range checking.
// @param bitwise_ptr Reference to the Bitwise operations interface.
// @param beast_token_id The unique identifier of the beast performing the counter-attack.
//
// @return damage The amount of damage inflicted on the adventurer by the beast's counter-attack.
func _counter_attack{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_token_id: Uint256) -> (damage: felt) {
    alloc_locals;

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
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(unpacked_adventurer);

    // get the armor the adventurer has at the armor slot the beast is attacking
    // get the location this beast attacks
    let (beast_attack_location) = BeastStats.get_attack_location_from_id(beast.Id);
    let (item_id) = AdventurerLib.get_item_id_at_slot(beast_attack_location, adventurer_dynamic_);
    let (armor) = ILoot.get_item_by_token_id(item_address, Uint256(item_id, 0));
    let (rnd) = get_random_number();
    let (damage_taken) = CombatStats.calculate_damage_from_beast(
        beast, armor, rnd, adventurer_dynamic_.Level
    );

    // deduct heatlh from adventurer
    IAdventurer.deduct_health(adventurer_address, adventurer_token_id, damage_taken);

    // check if beast counter attack killed adventurer
    let (updated_adventurer) = get_adventurer_from_beast(beast_token_id);
    // if the adventurer is dead
    if (updated_adventurer.Health == 0) {
        // grant beast xp
        grant_beast_xp(adventurer_token_id, beast_token_id, beast, damage_taken);
        return (damage_taken,);
    } else {
        AdventurerAttacked.emit(
            beast_token_id, adventurer_token_id, damage_taken, updated_adventurer.Health, 0, 0
        );
        return (damage_taken,);
    }
}

// @title Grant Beast Experience
// @param adventurer_token_id The token ID of the adventurer attacked by the beast.
// @param beast_token_id The token ID of the beast that attacked the adventurer.
// @param beast The Beast data structure containing the beast's information.
// @param damage_taken The amount of damage the adventurer took from the beast's attack.
// @return This function does not return a value.
// @dev The function first retrieves the adventurer state associated with the given adventurer token ID.
// It then calculates the experience gained by the beast for attacking the adventurer (considering adventurers as rank 1 entities).
// The beast's experience is then increased by the calculated amount using the `_increase_xp` function.
// Finally, an 'AdventurerAttacked' event is emitted, which includes the beast token ID, adventurer token ID, damage taken by the adventurer, the adventurer's remaining health, experience gained by the beast, and the amount of loot dropped (which is zero in this case).
func grant_beast_xp{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, beast_token_id: Uint256, beast: Beast, damage_taken: felt) {
    alloc_locals;

    // get adventurer from token id
    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);
    let (adventurer_state) = IAdventurer.get_adventurer_by_id(
        adventurer_address, adventurer_token_id
    );

    // grant beast xp for slaying adventurer (adventurers are rank 1)
    let (xp_gained) = CombatStats.calculate_xp_earned(1, adventurer_state.Level);
    let (_, beast_dynamic_) = BeastLib.split_data(beast);
    _increase_xp(beast_token_id, beast_dynamic_, xp_gained);

    // emit event
    AdventurerAttacked.emit(
        beast_token_id, adventurer_token_id, damage_taken, adventurer_state.Health, xp_gained, 0
    );

    return ();
}

// @notice Get xiroshiro random number
// @return dice_roll: Random number
func get_random_number{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}() -> (
    dice_roll: felt
) {
    alloc_locals;

    // let (block) = get_block_number();

    let (controller) = Module.controller_address();
    let (xoroshiro_address_) = IModuleController.get_xoroshiro(controller);
    let (rnd) = IXoroshiro.next(xoroshiro_address_);
    return (rnd,);
}

// @notice Revert if caller is not adventurer owner
// @param: adventurer_token_id: Id of adventurer
func assert_adventurer_owner{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256) {
    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);

    let (caller) = get_caller_address();
    let (owner) = IAdventurer.owner_of(adventurer_address, adventurer_token_id);

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
    UpdateBeastState.emit(beast_token_id, beast);
    return ();
}

// @notice Emit beast data
// @param: token_id: Id of beast
func emit_beast_level_up{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(beast_token_id: Uint256) {
    // Get beast and emit level up event with beast details
    let (beast) = get_beast_by_id(beast_token_id);
    UpdateBeastState.emit(beast_token_id, beast);
    BeastLevelUp.emit(beast_token_id, beast.Level);
    return ();
}

// @title process_ambush
// @notice This function processes an ambush between an adventurer and a beast.
// @param adventurer_address The address of the adventurer.
// @param adventurer_token_id The unique identifier of the adventurer.
// @param unpacked_adventurer The adventurer's state.
// @param beast_token_id The unique identifier of the beast.
// @return adventurer_dynamic The dynamic state of the adventurer after processing the ambush.
//
// @dev This function fetches the beast and adventurer data, calculates the ambush chance,
//      compares it with the adventurer's wisdom to see if they avoid the ambush, and if not,
//      calculates the damage taken from the beast, updates the adventurer's health, and checks
//      if the adventurer is dead. If the adventurer is dead, it performs the necessary tasks
//      such as zeroing out gold balance. Then, it emits an Ambushed event with the relevant data.
//      If the adventurer avoids the ambush, it emits an Ambushed event with no damage and returns
//      the dynamic component of the adventurer.
func process_ambush{
    range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}(
    adventurer_address: felt,
    adventurer_token_id: Uint256,
    unpacked_adventurer: AdventurerState,
    beast_token_id: Uint256,
) -> (adventurer_dynamic: AdventurerDynamic) {
    alloc_locals;

    // get beast and adventurer
    let (beast) = get_beast_by_id(beast_token_id);
    let (original_adventurer) = get_adventurer_from_beast(beast_token_id);
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(original_adventurer);

    // Ambush rng is scoped between zero and (adventurers level -1)
    let (ambush_rnd) = get_random_number();
    let (_, ambush_chance) = unsigned_div_rem(ambush_rnd, unpacked_adventurer.Level);

    // if the adventurers wisdom is higher than the ambush rnd, they avoid ambush
    let avoided_ambush = is_le(ambush_chance, unpacked_adventurer.Wisdom + 2);

    // if they do not avoid, they take damage
    if (avoided_ambush == FALSE) {
        // get loot item address
        let (item_address) = Module.get_module_address(ModuleIds.Loot);

        // get the armor the adventurer is wearing at the location the beast attacks
        let (beast_attack_location) = BeastStats.get_attack_location_from_id(beast.Id);
        let (item_id) = AdventurerLib.get_item_id_at_slot(
            beast_attack_location, adventurer_dynamic_
        );
        let (armor) = ILoot.get_item_by_token_id(item_address, Uint256(item_id, 0));

        let (critical_damage_rnd) = get_random_number();

        // calculate damage taken from beast
        let (damage_taken) = CombatStats.calculate_damage_from_beast(
            beast, armor, critical_damage_rnd, adventurer_dynamic_.Level
        );

        // update adventurer health
        let (deducted_health_adventurer) = IAdventurer.deduct_health(
            adventurer_address, Uint256(beast.Adventurer, 0), damage_taken
        );

        // emit ambush event
        AdventurerAmbushed.emit(
            beast_token_id,
            Uint256(beast.Adventurer, 0),
            damage_taken,
            deducted_health_adventurer.Health,
        );

        // if the adventurer is dead
        if (deducted_health_adventurer.Health == 0) {
            // grant beast xp
            grant_beast_xp(adventurer_token_id, beast_token_id, beast, damage_taken);
            return (deducted_health_adventurer,);
        }

        return (deducted_health_adventurer,);
    }

    AdventurerAmbushed.emit(
        beast_token_id, Uint256(beast.Adventurer, 0), 0, original_adventurer.Health
    );

    // return dynamic component
    return (adventurer_dynamic_,);
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
    let adventurer_token_id = Uint256(beast.Adventurer, 0);
    let (adventurer_state) = IAdventurer.get_adventurer_by_id(
        adventurer_address, adventurer_token_id
    );
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

    UpdateGoldBalance.emit(adventurer_token_id, current_balance + addition);

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

    let check_balance = is_le(0, current_balance - subtraction);

    // add in overflow assert so you can't spend more than what you have.
    with_attr error_message("Beast: Not enough gold in balance.") {
        assert check_balance = TRUE;
    }

    goldBalance.write(adventurer_token_id, current_balance - subtraction);

    UpdateGoldBalance.emit(adventurer_token_id, current_balance - subtraction);

    let (supply) = worldSupply.read();
    let new_supply = supply - subtraction;
    assert_nn(new_supply);
    worldSupply.write(supply - subtraction);

    return ();
}

@external
func zero_out_gold_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_token_id: Uint256
) {
    Module.only_approved();

    _zero_out_gold_balance(adventurer_token_id);

    return ();
}

// @title Zero Out Gold Balance
// @dev This function zeros out the gold balance of a specified adventurer.
// @notice This is an internal function, hence not directly callable by end-users.
// @param adventurer_token_id The token ID of the adventurer whose gold balance is to be zeroed out.
// @return This function does not return a value.
// @dev This function first retrieves the current gold balance of the specified adventurer.
// Then, it updates the gold balance of the adventurer to zero.
// An event, 'UpdateGoldBalance', is then emitted with the adventurer's token ID and the new balance (which is zero).
// Finally, the world supply of gold is updated to account for the reduction in gold, ensuring the total supply is always accurate.
// If the new supply is a negative number, an error will be thrown, which should not occur in normal conditions as it would mean an adventurer has a negative gold balance.
func _zero_out_gold_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_token_id: Uint256
) {
    // get current gold balance
    let (current_balance) = balance_of(adventurer_token_id);

    // zero out balance
    goldBalance.write(adventurer_token_id, 0);

    // generate gold balance event
    UpdateGoldBalance.emit(adventurer_token_id, 0);

    // update world supply to account for this gold being removed from game
    let (supply) = worldSupply.read();
    let new_supply = supply - current_balance;
    assert_nn(new_supply);
    worldSupply.write(new_supply);

    return ();
}

@view
func balance_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_token_id: Uint256
) -> (balance: felt) {
    let (gold_balance) = goldBalance.read(adventurer_token_id);
    return (gold_balance,);
}

@view
func get_world_supply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    balance: felt
) {
    return worldSupply.read();
}
