// -----------------------------------
//   Module.Adventurer
//   Adventurer logic
//
//
//
// -----------------------------------
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.3.2 (token/erc721/enumerable/presets/ERC721EnumerableMintableBurnable.cairo)

%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    uint256_eq,
    uint256_mul,
    uint256_unsigned_div_rem,
)
from starkware.cairo.common.math import (
    unsigned_div_rem,
    assert_not_equal,
    assert_not_zero,
    assert_in_range,
)
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
    get_block_number,
)

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.library.library_module import Module
from contracts.loot.adventurer.library import AdventurerLib
from contracts.loot.adventurer.metadata import AdventurerUri
from contracts.loot.constants.adventurer import (
    Adventurer,
    AdventurerSlotIds,
    AdventurerState,
    AdventurerStatic,
    AdventurerDynamic,
    PackedAdventurerState,
    AdventurerStatus,
    DiscoveryType,
    ItemDiscoveryType,
    ItemShift,
)
from contracts.loot.constants.beast import Beast
from contracts.loot.constants.obstacle import ObstacleUtils, ObstacleConstants
from contracts.loot.interfaces.imodules import IModuleController
from contracts.loot.loot.stats.combat import CombatStats
from contracts.loot.utils.general import _uint_to_felt
from contracts.loot.beast.interface import IBeast
from contracts.loot.loot.ILoot import ILoot
from contracts.loot.utils.constants import (
    ModuleIds,
    ExternalContractIds,
    MINT_COST,
    FRONT_END_PROVIDER_REWARD,
    FIRST_PLACE_REWARD,
    SECOND_PLACE_REWARD,
    THIRD_PLACE_REWARD,
    STARTING_GOLD,
    VITALITY_HEALTH_BOOST,
)
from contracts.loot.constants.item import ITEM_XP_MULTIPLIER

// Used to record top scores for distributing rewards
struct TopScore {
    address: felt,
    xp: felt,
    adventurer_id: Uint256,
}

// -----------------------------------
// Events
// -----------------------------------

@event
func MintAdventurer(adventurer_id: Uint256, owner: felt) {
}

@event
func UpdateAdventurerState(adventurer_id: Uint256, adventurer_state: AdventurerState) {
}

@event
func AdventurerLeveledUp(adventurer_id: Uint256, level: felt) {
}

@event
func Discovery(
    adventurer_id: Uint256,
    discovery_type: felt,
    sub_discovery_type: felt,
    entity_id: Uint256,
    output_amount: felt,
) {
}

@event
func HighScoreReward(top_score_holders: TopScore) {
}

@event
func NewTopScore(top_score_holders: TopScore) {
}

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func adventurer_static(adventurer_token_id: Uint256) -> (adventurer: AdventurerStatic) {
}

@storage_var
func adventurer_dynamic(adventurer_token_id: Uint256) -> (adventurer: PackedAdventurerState) {
}

// top scores used for rewarding top players
@storage_var
func top_scores(index: felt) -> (top_score: TopScore) {
}

@storage_var
func treasury_address() -> (address: felt) {
}

@storage_var
func adventurer_image(tokenId: Uint256) -> (image: felt) {
}

// -----------------------------------
// Initialize & upgrade
// -----------------------------------

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @return proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, address_of_controller: felt, proxy_admin: felt
) {
    // set as module
    Module.initializer(address_of_controller);

    // 721 setup
    ERC721.initializer(name, symbol);
    ERC721Enumerable.initializer();
    Proxy.initializer(proxy_admin);

    // initialize top three scores to treasury address
    let (treasury) = Module.get_external_contract_address(ExternalContractIds.Treasury);
    let default_top_score = TopScore(treasury, 0, Uint256(0, 0));
    top_scores.write(0, default_top_score);
    top_scores.write(1, default_top_score);
    top_scores.write(2, default_top_score);

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
// External Adventurer Specific
// -----------------------------

// @notice Mint an adventurer with null attributes
// @param to: Recipient of adventurer
// @param race: Race of adventurer
// @param home_realm: Home Realm of adventurer
// @param name: Name of adventurer
// @param order: Order of adventurer
@external
func mint{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    to: felt,
    race: felt,
    home_realm: felt,
    name: felt,
    order: felt,
    image_hash_1: felt,
    image_hash_2: felt,
    interface_address: felt,
) -> (adventurer_token_id: Uint256) {
    alloc_locals;

    assert_not_zero(interface_address);

    let (controller) = Module.controller_address();

    // create new adventurer based on provided parameters
    let (birth_time) = get_block_timestamp();
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.birth(
        race, home_realm, name, birth_time, order, image_hash_1, image_hash_2
    );

    // pack adventurer for storage
    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(adventurer_dynamic_);

    // increment current id
    let (current_id: Uint256) = totalSupply();
    let (new_adventurer_id, _) = uint256_add(current_id, Uint256(1, 0));

    // write adventurer to chain
    adventurer_static.write(new_adventurer_id, adventurer_static_);
    adventurer_dynamic.write(new_adventurer_id, packed_new_adventurer);

    // mint adventurer
    ERC721Enumerable._mint(to, new_adventurer_id);

    // distribute $lords rewards
    _distribute_rewards(interface_address);

    // emit mint adventurer event and emit adventurer state
    let (caller) = get_caller_address();
    MintAdventurer.emit(new_adventurer_id, caller);
    emit_adventurer_state(new_adventurer_id);

    // return new adventurer token id
    return (new_adventurer_id,);
}

@external
func mint_with_starting_weapon{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    to: felt,
    race: felt,
    home_realm: felt,
    name: felt,
    order: felt,
    image_hash_1: felt,
    image_hash_2: felt,
    weapon_id: felt,
    interface_address: felt,
) -> (adventurer_token_id: Uint256, item_token_id: Uint256) {
    alloc_locals;

    // Mint new adventurer
    let (adventurer_token_id) = mint(
        to, race, home_realm, name, order, image_hash_1, image_hash_2, interface_address
    );

    // Mint starting weapon for the adventurer (book, wand, club, short sword)
    let (loot_address) = Module.get_module_address(ModuleIds.Loot);
    let (item_token_id) = ILoot.mint_starter_weapon(
        loot_address, to, weapon_id, adventurer_token_id
    );

    // Equip the selected item to the adventurer
    equip_item(adventurer_token_id, item_token_id);

    // add STARTING_GOLD to balance
    let (beast_address) = Module.get_module_address(ModuleIds.Beast);
    IBeast.add_to_balance(beast_address, adventurer_token_id, STARTING_GOLD);
    emit_adventurer_state(adventurer_token_id);

    // Return adventurer token id and item token id
    return (adventurer_token_id, item_token_id);
}

// @notice Equip loot item to adventurer. If an item is already equipped to that item slot, this functions as a swap
// @param adventurer_token_id: Id of adventurer
// @param item_token_id: Id of loot item
@external
func equip_item{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, item_token_id: Uint256) -> (success: felt) {
    alloc_locals;

    // only adventurer owner can equip
    ERC721.assert_only_token_owner(adventurer_token_id);

    assert_not_dead(adventurer_token_id);

    // equip the item selected by the adventurer
    // note if this function will perform a swap if the adventurer
    // already has an item equipped to that item slot
    let (adventurer) = _equip_item(adventurer_token_id, item_token_id);

    // if the adventurer is in a battle
    if (adventurer.Status == AdventurerStatus.Battle) {
        // equipping consumes a turn so process the beasts counter attack
        _trigger_beast_counterattack(adventurer);
        return (TRUE,);
    }

    return (TRUE,);
}

// @notice Unquip loot item from adventurer
// @param adventurer_token_id: Id of adventurer
// @param item_token_id: Id of loot item
@external
func unequip_item{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, item_token_id: Uint256) -> (success: felt) {
    alloc_locals;

    // only adventurer owner can unequip
    ERC721.assert_only_token_owner(adventurer_token_id);

    assert_not_dead(adventurer_token_id);

    let (adventurer) = _unequip_item(adventurer_token_id, item_token_id);

    // if the adventurer is in a battle
    if (adventurer.Status == AdventurerStatus.Battle) {
        // unequipping consumes a turn so process the beasts counter attack
        _trigger_beast_counterattack(adventurer);
        return (TRUE,);
    }

    return (TRUE,);
}

// @notice Update status of adventurer
// @param adventurer_token_id: Id of adventurer
// @param status: Status value
@external
func update_status{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, status: felt) -> (success: felt) {
    alloc_locals;
    Module.only_approved();

    let (unpacked_adventurer) = get_adventurer_by_id(adventurer_token_id);
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(unpacked_adventurer);

    let (new_adventurer) = AdventurerLib.update_status(status, adventurer_dynamic_);

    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(new_adventurer);
    adventurer_dynamic.write(adventurer_token_id, packed_new_adventurer);

    emit_adventurer_state(adventurer_token_id);

    return (TRUE,);
}

// @notice Assign beast to adventurer
// @param adventurer_token_id: Id of adventurer
// @param value: Beast value
@external
func assign_beast{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, value: felt) -> (success: felt) {
    alloc_locals;
    Module.only_approved();

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(adventurer_token_id);
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(unpacked_adventurer);

    // deduct health
    let (new_adventurer) = AdventurerLib.assign_beast(value, adventurer_dynamic_);

    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(new_adventurer);
    adventurer_dynamic.write(adventurer_token_id, packed_new_adventurer);

    emit_adventurer_state(adventurer_token_id);

    return (TRUE,);
}

// @notice Deduct health from adventurer
// @param adventurer_token_id: Id of adventurer
// @param amount: Health amount to deduct
// @return success: Value indicating success
@external
func deduct_health{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, amount: felt) -> (adventurer_dynamic: AdventurerDynamic) {
    alloc_locals;

    Module.only_approved();
    let (updated_adventurer) = _deduct_health(adventurer_token_id, amount);
    return (updated_adventurer,);
}

// @notice Add health to adventurer
// @param adventurer_token_id: Id of adventurer
// @param amount: Health amount to add
// @return success: Value indicating success
@external
func add_health{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, amount: felt) -> (success: felt) {
    alloc_locals;

    Module.only_approved();
    _add_health(adventurer_token_id, amount);
    return (TRUE,);
}

// @notice Increase xp of adventurer
// @param adventurer_token_id: Id of adventurer
// @param amount: Amount of xp to increase
// @return success: Value indicating success
@external
func increase_xp{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, amount: felt) -> (success: felt) {
    alloc_locals;

    Module.only_approved();
    _increase_xp(adventurer_token_id, amount);

    return (TRUE,);
}

// @notice Updates the state of an adventurer based on the provided adventurer.
// @dev This function is external and can be called by any address.
// @param adventurer_token_id The unique identifier of the adventurer token.
// @param adventurer_dynamic The updated dynamic data of the adventurer.
@external
func update_adventurer{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, _adventurer_dynamic: AdventurerDynamic) {
    alloc_locals;

    // only approved modules can call this external function
    Module.only_approved();

    // pack adventurer
    let (packed_adventurer: PackedAdventurerState) = AdventurerLib.pack(_adventurer_dynamic);

    // write to chain
    adventurer_dynamic.write(adventurer_token_id, packed_adventurer);
    return ();
}

// @notice Upgrade stat of adventurer
// @param adventurer_token_id: Id of adventurer
// @param amount: Amount of xp to increase
// @return success: Value indicating success
@external
func upgrade_stat{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, stat: felt) -> (success: felt) {
    alloc_locals;
    // only adventurer owner can upgrade stat
    ERC721.assert_only_token_owner(adventurer_token_id);

    assert_not_dead(adventurer_token_id);

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(adventurer_token_id);
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(unpacked_adventurer);
    with_attr error_message("Adventurer: Adventurer must be upgradable") {
        assert adventurer_dynamic_.Upgrading = TRUE;
    }

    // check stat is upgradeable
    assert_in_range(stat, AdventurerSlotIds.Strength, AdventurerSlotIds.Luck);

    // upgrade stat
    let (updated_stat_adventurer) = AdventurerLib.update_statistics(stat, adventurer_dynamic_);

    // if stat chosen to upgrade is vitality then increase current health and max health by 20
    if (stat == AdventurerSlotIds.Vitality) {
        // we get max health based on vitality
        let max_health = 100 + (VITALITY_HEALTH_BOOST * updated_stat_adventurer.Vitality);
        let check_health_over_cap = is_le(
            max_health, updated_stat_adventurer.Health + VITALITY_HEALTH_BOOST
        );

        // cap health at 100 + (20 * vitality)
        if (check_health_over_cap == TRUE) {
            let add_amount = max_health - updated_stat_adventurer.Health;
            let (new_adventurer) = AdventurerLib.add_health(add_amount, updated_stat_adventurer);
            // reset upgrading param
            let (updated_upgrade_adventurer) = AdventurerLib.set_upgrading(FALSE, new_adventurer);
            let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(
                updated_upgrade_adventurer
            );
            adventurer_dynamic.write(adventurer_token_id, packed_new_adventurer);
            emit_adventurer_state(adventurer_token_id);
            return (TRUE,);
        } else {
            let (new_adventurer) = AdventurerLib.add_health(
                VITALITY_HEALTH_BOOST, updated_stat_adventurer
            );
            // reset upgrading param
            let (updated_upgrade_adventurer) = AdventurerLib.set_upgrading(FALSE, new_adventurer);
            let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(
                updated_upgrade_adventurer
            );
            adventurer_dynamic.write(adventurer_token_id, packed_new_adventurer);
            emit_adventurer_state(adventurer_token_id);
            return (TRUE,);
        }
    }
    // reset upgrading param
    let (updated_upgrade_adventurer) = AdventurerLib.set_upgrading(FALSE, updated_stat_adventurer);
    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(
        updated_upgrade_adventurer
    );
    adventurer_dynamic.write(adventurer_token_id, packed_new_adventurer);
    emit_adventurer_state(adventurer_token_id);
    return (TRUE,);
}

// @notice Purchase health for gold
// @param adventurer_token_id: Id of adventurer
// @param number: number of health potions to purchase
// @return success: Value indicating success
@external
func purchase_health{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, number: felt) -> (success: felt) {
    alloc_locals;

    let (adventurer_address) = Module.get_module_address(ModuleIds.Adventurer);
    // only adventurer owner can purchase health
    ERC721.assert_only_token_owner(adventurer_token_id);

    // check the adventurer can purchase health
    assert_not_dead(adventurer_token_id);

    let (unpacked_adventurer) = get_adventurer_by_id(adventurer_token_id);
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(unpacked_adventurer);

    with_attr error_message("Adventurer: Must be idle") {
        assert adventurer_dynamic_.Status = AdventurerStatus.Idle;
    }

    let (beast_address) = Module.get_module_address(ModuleIds.Beast);

    let discount = adventurer.Level - adventurer.Charisma;

    let discount_below_floor = is_le(discount, 3);

    if (discount_below_floor == TRUE) {
        // cannot be lower than 3
        tempvar cost_of_potion = 3;
    } else {
        tempvar cost_of_potion = 3 * discount;
    }

    IBeast.subtract_from_balance(beast_address, adventurer_token_id, cost_of_potion * number);

    // health potion adds 10 health
    _add_health(adventurer_token_id, 10 * number);

    return (TRUE,);
}

// @notice Explore for discoveries
// @param adventurer_token_id: Id of adventurer
// @return success: Value indicating success
@external
func explore{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256) -> (type: felt, id: felt) {
    alloc_locals;

    // only adventurer owner can explore
    ERC721.assert_only_token_owner(adventurer_token_id);

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(adventurer_token_id);
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(unpacked_adventurer);

    assert_not_dead(adventurer_token_id);

    // Only idle explorers can explore
    with_attr error_message("Adventurer: Adventurer must be idle") {
        assert unpacked_adventurer.Status = AdventurerStatus.Idle;
    }

    // Only adventurers without assigned beast
    with_attr error_message("Adventurer: Cannot explore while assigned beast") {
        assert unpacked_adventurer.Beast = 0;
    }

    let (beast_address) = Module.get_module_address(ModuleIds.Beast);

    // If this is a newbie adventurer
    if (unpacked_adventurer.Level == 1) {
        // we set their status to battle
        let (new_unpacked_adventurer) = AdventurerLib.update_status(
            AdventurerStatus.Battle, adventurer_dynamic_
        );

        // get weapon
        let (item_address) = Module.get_module_address(ModuleIds.Loot);
        let (weapon) = ILoot.get_item_by_token_id(
            item_address, Uint256(unpacked_adventurer.WeaponId, 0)
        );

        // We give them an easy starting beast (will also have weak armor for their weapon)
        let (starting_beast_id) = AdventurerLib.get_starting_beast_from_weapon(weapon.Id);

        // assert starting weapon
        let check_not_zero = is_not_zero(starting_beast_id);
        with_attr error_message("Adventurer: Not holding a starting weapon") {
            assert check_not_zero = TRUE;
        }

        // create beast according to the weapon the player has
        let (beast_id: Uint256) = IBeast.create_starting_beast(
            beast_address, adventurer_token_id, starting_beast_id
        );
        let (updated_adventurer) = AdventurerLib.assign_beast(
            beast_id.low, new_unpacked_adventurer
        );
        let (packed_adventurer) = AdventurerLib.pack(updated_adventurer);

        adventurer_dynamic.write(adventurer_token_id, packed_adventurer);

        emit_adventurer_state(adventurer_token_id);
        Discovery.emit(adventurer_token_id, DiscoveryType.Beast, 0, beast_id, 1);
        return (DiscoveryType.Beast, beast_id.low);
    }

    let (rnd) = get_random_number();
    let (discovery) = AdventurerLib.get_random_discovery(rnd);

    if (discovery == DiscoveryType.Beast) {
        // create beast which will process ambush and return a dynamic adventurer
        let (
            beast_id: Uint256, discovered_beast_adventurer_dynamic: AdventurerDynamic
        ) = IBeast.create(beast_address, adventurer_token_id);

        // assign the beast to the adventurer (this should probably be done as part of above)
        let (assigned_beast_adventurer_dynamic) = AdventurerLib.assign_beast(
            beast_id.low, discovered_beast_adventurer_dynamic
        );

        // we set their status to battle
        let (assigned_battle_status_dynamic_adventurer) = AdventurerLib.update_status(
            AdventurerStatus.Battle, assigned_beast_adventurer_dynamic
        );

        // pack adventurer
        let (packed_adventurer) = AdventurerLib.pack(assigned_battle_status_dynamic_adventurer);

        // write to chain
        adventurer_dynamic.write(adventurer_token_id, packed_adventurer);

        // emit adventurer state (this will read adventurer state from chain)
        emit_adventurer_state(adventurer_token_id);

        // emit discovery event
        Discovery.emit(adventurer_token_id, DiscoveryType.Beast, 0, beast_id, 1);

        // return type beast with low id bits
        return (DiscoveryType.Beast, beast_id.low);
    }

    if (discovery == DiscoveryType.Obstacle) {
        // TODO: Obstacle prefixes and greatness
        // @distracteddev: Picked
        let (rnd) = get_random_number();

        // generate random obstacle
        let (obstacle) = ObstacleUtils.generate_random_obstacle(unpacked_adventurer, rnd);

        // adventurer gets XP regardless of the outcome
        let (xp_gained) = CombatStats.calculate_xp_earned(obstacle.Rank, obstacle.Greatness);
        _increase_xp(adventurer_token_id, xp_gained);

        // To see if adventurer can dodge, we roll a dice
        let (dodge_rnd) = get_random_number();
        // between zero and the adventurers level
        let (_, dodge_chance) = unsigned_div_rem(dodge_rnd, unpacked_adventurer.Level);
        // if the adventurers intelligence
        let can_dodge = is_le(dodge_chance, unpacked_adventurer.Intelligence + 1);
        if (can_dodge == TRUE) {
            Discovery.emit(
                adventurer_token_id, DiscoveryType.Obstacle, obstacle.Id, Uint256(0, 0), 0
            );
            return (DiscoveryType.Obstacle, obstacle.Id);
        } else {
            // @distracteddev: Should be get equipped item by slot not get item by Id
            let (item_id) = AdventurerLib.get_item_id_at_slot(
                obstacle.DamageLocation, adventurer_dynamic_
            );
            let (item_address) = Module.get_module_address(ModuleIds.Loot);

            // calculate obstacle damage based on adventurer armor and obstacle stats
            let (armor) = ILoot.get_item_by_token_id(item_address, Uint256(item_id, 0));
            let (obstacle_damage) = CombatStats.calculate_damage_from_obstacle(obstacle, armor);
            _deduct_health(adventurer_token_id, obstacle_damage);

            // grant XP to items
            let xp_gained_items = obstacle_damage * ITEM_XP_MULTIPLIER;
            ILoot.allocate_xp_to_items(item_address, adventurer_token_id, xp_gained_items);

            // emit discovery event
            Discovery.emit(
                adventurer_token_id,
                DiscoveryType.Obstacle,
                obstacle.Id,
                Uint256(0, 0),
                obstacle_damage,
            );
            return (DiscoveryType.Obstacle, obstacle.Id);
        }
    }
    if (discovery == DiscoveryType.Item) {
        // generate another random 3 numbers
        // this could probably be better
        let (rnd) = get_random_number();
        let (discovery) = AdventurerLib.get_item_discovery(rnd);

        if (discovery == ItemDiscoveryType.Gold) {
            // add GOLD
            // @distracteddev: formula - 1 + (rnd % 4)
            let (rnd) = get_random_number();
            let (gold_discovery) = AdventurerLib.calculate_gold_discovery(
                rnd, adventurer_dynamic_.Level
            );
            let (beast_address) = Module.get_module_address(ModuleIds.Beast);
            IBeast.add_to_balance(beast_address, adventurer_token_id, gold_discovery);
            emit_adventurer_state(adventurer_token_id);
            Discovery.emit(
                adventurer_token_id,
                DiscoveryType.Item,
                ItemDiscoveryType.Gold,
                Uint256(0, 0),
                gold_discovery,
            );
            return (DiscoveryType.Item, ItemDiscoveryType.Gold);
        }

        if (discovery == ItemDiscoveryType.Loot) {
            // mint loot items
            let (loot_address) = Module.get_module_address(ModuleIds.Loot);
            let (owner) = owner_of(adventurer_token_id);
            let (loot_token_id) = ILoot.mint(loot_address, owner, adventurer_token_id);
            emit_adventurer_state(adventurer_token_id);
            Discovery.emit(
                adventurer_token_id, DiscoveryType.Item, ItemDiscoveryType.Loot, loot_token_id, 1
            );
            return (DiscoveryType.Item, ItemDiscoveryType.Loot);
        }
        if (discovery == ItemDiscoveryType.Health) {
            // add health
            // @distracteddev: formula - 10 + (5 * (rnd % 4))
            let (rnd) = get_random_number();
            let (health_discovery) = AdventurerLib.calculate_health_discovery(rnd);
            _add_health(adventurer_token_id, health_discovery);
            Discovery.emit(
                adventurer_token_id,
                DiscoveryType.Item,
                ItemDiscoveryType.Health,
                Uint256(0, 0),
                health_discovery,
            );
            return (DiscoveryType.Item, ItemDiscoveryType.Health);
        }

        // send item
        return (DiscoveryType.Item, 0);
    }

    // Discover 1-10XP
    let (rnd) = get_random_number();
    let (xp_discovery) = AdventurerLib.calculate_xp_discovery(rnd, adventurer_dynamic_.Level);
    _increase_xp(adventurer_token_id, xp_discovery);
    Discovery.emit(adventurer_token_id, DiscoveryType.Nothing, 0, Uint256(0, 0), xp_discovery);

    return (DiscoveryType.Nothing, 0);
}

// -----------------------------
// Internal Adventurer Specific
// -----------------------------

// @notice Revert if adventurer is dead
// @param adventurer_token_id: Id of adventurer
func assert_not_dead{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256) {
    let (adventurer: AdventurerState) = get_adventurer_by_id(adventurer_token_id);

    with_attr error_message("Adventurer: Adventurer is dead") {
        assert_not_zero(adventurer.Health);
    }

    return ();
}

// @notice Revert if adventurer is not item owner
// @param adventurer_token_id: Id of adventurer
// @param itemId: Id of the item
func assert_adventurer_is_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_token_id: Uint256, itemId: Uint256
) {
    alloc_locals;
    let (loot_address) = Module.get_module_address(ModuleIds.Loot);
    let (owner) = ILoot.item_owner(loot_address, itemId, adventurer_token_id);
    with_attr error_message("Adventurer: Adventurer is not item owner") {
        assert owner = TRUE;
    }
    return ();
}

// @notice Get xoroshiro random number
// @return dice_roll: Xoroshiro random number
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

// @notice Emit state of adventurer
// @param adventurer_token_id: Id of adventurer
func emit_adventurer_state{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256) {
    // Get new adventurer
    let (new_adventurer) = get_adventurer_by_id(adventurer_token_id);

    UpdateAdventurerState.emit(adventurer_token_id, new_adventurer);

    return ();
}

// @notice Emits a leveled up event for the adventurer
// @param adventurer_token_id: the token id of the adventurer that leveled up
func emit_adventurer_leveled_up{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256) {
    // Get adventurer from token id
    let (new_adventurer) = get_adventurer_by_id(adventurer_token_id);
    // emit leveled up event
    AdventurerLeveledUp.emit(adventurer_token_id, new_adventurer.Level);
    return ();
}

// --------------------
// Getters
// --------------------

// @notice Get adventurer data from id
// @param adventurer_token_id: Id of adventurer
// @return adventurer: Data of adventurer
@view
func get_adventurer_by_id{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256) -> (adventurer: AdventurerState) {
    alloc_locals;

    let (adventurer_static_) = adventurer_static.read(adventurer_token_id);
    let (packed_adventurer) = adventurer_dynamic.read(adventurer_token_id);

    // unpack
    let (unpacked_adventurer: AdventurerDynamic) = AdventurerLib.unpack(packed_adventurer);
    let (adventurer) = AdventurerLib.aggregate_data(adventurer_static_, unpacked_adventurer);

    return (adventurer,);
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

@view
func tokenByIndex{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    index: Uint256
) -> (adventurer_token_id: Uint256) {
    let (adventurer_token_id: Uint256) = ERC721Enumerable.token_by_index(index);
    return (adventurer_token_id,);
}

@view
func token_of_owner_by_index{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, index: Uint256
) -> (adventurer_token_id: Uint256) {
    let (adventurer_token_id: Uint256) = ERC721Enumerable.token_of_owner_by_index(owner, index);
    return (adventurer_token_id,);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    let (success) = ERC165.supports_interface(interfaceId);
    return (success,);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name) = ERC721.name();
    return (name,);
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol) = ERC721.symbol();
    return (symbol,);
}

@view
func balance_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    let (balance: Uint256) = ERC721.balance_of(owner);
    return (balance,);
}

@view
func owner_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_token_id: Uint256
) -> (owner: felt) {
    let (owner: felt) = ERC721.owner_of(adventurer_token_id);
    return (owner,);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_token_id: Uint256
) -> (approved: felt) {
    let (approved: felt) = ERC721.get_approved(adventurer_token_id);
    return (approved,);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved,);
}

@view
func tokenURI{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}(tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
    alloc_locals;
    let (controller) = Module.controller_address();
    let (item_address) = Module.get_module_address(ModuleIds.Loot);
    let (beast_address) = Module.get_module_address(ModuleIds.Beast);
    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    );
    let (adventurer_data) = get_adventurer_by_id(tokenId);
    let (tokenURI_len, tokenURI: felt*) = AdventurerUri.build(
        tokenId, adventurer_data, item_address, beast_address, realms_address
    );
    return (tokenURI_len, tokenURI);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    let (owner: felt) = Ownable.owner();
    return (owner,);
}

//
// Externals
//

@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, adventurer_token_id: Uint256
) {
    ERC721.approve(to, adventurer_token_id);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    adventurer_token_id: Uint256
) {
    ERC721.assert_only_token_owner(adventurer_token_id);
    ERC721Enumerable._burn(adventurer_token_id);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}

//
// INTERNAL
//

func _deduct_health{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, amount: felt) -> (adventurer_dynamic: AdventurerDynamic) {
    alloc_locals;

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(adventurer_token_id);
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(unpacked_adventurer);

    // deduct health
    let (new_adventurer) = AdventurerLib.deduct_health(amount, adventurer_dynamic_);

    // pack and store updated adventurer
    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(new_adventurer);
    adventurer_dynamic.write(adventurer_token_id, packed_new_adventurer);

    // emit adventurer state event
    emit_adventurer_state(adventurer_token_id);

    // if the adventurer is dead
    if (new_adventurer.Health == 0) {
        // zero out gold balance
        let (beast_address) = Module.get_module_address(ModuleIds.Beast);
        IBeast.zero_out_gold_balance(beast_address, adventurer_token_id);

        // check if the adventurer scored a new top score
        // by first checking if they are less than or equal to third place
        let (third_place_score) = top_scores.read(2);
        let not_top_three_score = is_le(new_adventurer.XP, third_place_score.xp);
        if (not_top_three_score == FALSE) {
            // if their score is not less than or equal to third place
            // it's a new top score
            let (player_address) = owner_of(adventurer_token_id);
            _update_top_scores(player_address, new_adventurer.XP, adventurer_token_id);
            return (new_adventurer,);
        }

        return (new_adventurer,);
    }

    // return updated adventurer
    return (new_adventurer,);
}

func _increase_xp{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, amount: felt) -> (success: felt) {
    alloc_locals;

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(adventurer_token_id);
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(unpacked_adventurer);

    // increase xp
    let (updated_xp_adventurer) = AdventurerLib.increase_xp(amount, adventurer_dynamic_);

    // check if the adventurer  reached the next level
    let (leveled_up) = CombatStats.check_for_level_increase(
        updated_xp_adventurer.XP, updated_xp_adventurer.Level
    );

    // if it did
    if (leveled_up == TRUE) {
        // increase level
        let (updated_level_adventurer) = AdventurerLib.update_level(
            updated_xp_adventurer.Level + 1, updated_xp_adventurer
        );
        // allow adventurer to choose a stat to upgrade
        let (updated_upgrading_adventurer) = AdventurerLib.set_upgrading(
            TRUE, updated_level_adventurer
        );
        let (packed_updated_adventurer: PackedAdventurerState) = AdventurerLib.pack(
            updated_upgrading_adventurer
        );
        adventurer_dynamic.write(adventurer_token_id, packed_updated_adventurer);
        emit_adventurer_leveled_up(adventurer_token_id);
        return (TRUE,);
    } else {
        let (packed_updated_adventurer: PackedAdventurerState) = AdventurerLib.pack(
            updated_xp_adventurer
        );
        adventurer_dynamic.write(adventurer_token_id, packed_updated_adventurer);
        emit_adventurer_state(adventurer_token_id);
        return (TRUE,);
    }
}

func _add_health{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, amount: felt) -> (success: felt) {
    alloc_locals;

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(adventurer_token_id);
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(unpacked_adventurer);

    // we get max health based on vitality
    let max_health = 100 + (VITALITY_HEALTH_BOOST * adventurer_dynamic_.Vitality);
    let check_health_over_cap = is_le(max_health, adventurer_dynamic_.Health + amount);

    // cap health at 100 + (20 * vitality)
    if (check_health_over_cap == TRUE) {
        let add_amount = max_health - adventurer_dynamic_.Health;
        let (new_adventurer) = AdventurerLib.add_health(add_amount, adventurer_dynamic_);
        let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(new_adventurer);
        adventurer_dynamic.write(adventurer_token_id, packed_new_adventurer);
        emit_adventurer_state(adventurer_token_id);
        return (TRUE,);
    } else {
        let (new_adventurer) = AdventurerLib.add_health(amount, adventurer_dynamic_);
        let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(new_adventurer);
        adventurer_dynamic.write(adventurer_token_id, packed_new_adventurer);
        emit_adventurer_state(adventurer_token_id);
        return (TRUE,);
    }
}

func _set_upgradable{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, upgradable: felt) {
    alloc_locals;

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(adventurer_token_id);
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(unpacked_adventurer);

    // set upgrading
    let (updated_adventurer) = AdventurerLib.set_upgrading(upgradable, adventurer_dynamic_);

    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(updated_adventurer);
    adventurer_dynamic.write(adventurer_token_id, packed_new_adventurer);

    emit_adventurer_state(adventurer_token_id);

    return ();
}

// @title Reward Distribution Function
// @notice Distributes $lords token rewards to the front-end provider, top 3 adventurers, and the treasury.
// @dev This function transfers $lords tokens from the caller to specified recipients.
// @param interface_address The address of the front-end provider receiving the reward.
func _distribute_rewards{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(interface_address: felt) {
    alloc_locals;

    // get lords address
    let (lords_address) = Module.get_external_contract_address(ExternalContractIds.Lords);
    let (caller) = get_caller_address();

    // send $lords reward to the front-end provider
    IERC20.transferFrom(
        lords_address, caller, interface_address, Uint256(FRONT_END_PROVIDER_REWARD, 0)
    );

    // send $lords rewards to the adventurer with the highest score
    let (first_place) = top_scores.read(0);
    IERC20.transferFrom(lords_address, caller, first_place.address, Uint256(FIRST_PLACE_REWARD, 0));

    // send $lords rewards to the adventurer with the second highest score
    let (second_place) = top_scores.read(1);
    IERC20.transferFrom(
        lords_address, caller, second_place.address, Uint256(SECOND_PLACE_REWARD, 0)
    );

    // send $lords rewards to the adventurer with the third highest score
    let (third_place) = top_scores.read(2);
    IERC20.transferFrom(lords_address, caller, third_place.address, Uint256(THIRD_PLACE_REWARD, 0));

    // send the remainder of the $lords to treasury
    let (treasury) = Module.get_external_contract_address(ExternalContractIds.Treasury);
    let remaining_lords = MINT_COST - FRONT_END_PROVIDER_REWARD - FIRST_PLACE_REWARD -
        SECOND_PLACE_REWARD - THIRD_PLACE_REWARD;
    IERC20.transferFrom(lords_address, caller, treasury, Uint256(remaining_lords, 0));

    return ();
}

// @title Update Top Three Scoreboard
// @notice Updates the top 3 scores of adventurers based on the input address and experience points (xp).
// @dev This function compares the input xp with existing top scores and updates the leaderboard accordingly.
// @param address The address of the adventurer whose score is being updated.
// @param xp The experience points of the adventurer.
// @return score_board_updated Returns TRUE if the scoreboard was updated, otherwise returns FALSE.
func _update_top_scores{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(address: felt, new_score_xp: felt, adventurer_token_id: Uint256) -> (score_board_updated: felt) {
    alloc_locals;

    let new_score = TopScore(address, new_score_xp, adventurer_token_id);

    // this is a temporary event to prevent having to reindex during active alpha testing
    // This can and should be removed as soon as it's conveinent to update our indexer
    HighScoreReward.emit(new_score);
    // "NewTopScore" is a more descriptive name for this event
    NewTopScore.emit(new_score);

    let (current_first_place) = top_scores.read(0);
    let (current_second_place) = top_scores.read(1);
    let (current_third_place) = top_scores.read(2);

    // if the score is equal to the current top score
    if (current_first_place.xp == new_score_xp) {
        // the original highscore stays in first

        // move the second place into third (index 2)
        top_scores.write(2, current_second_place);

        // new score is second (index 1)
        top_scores.write(1, new_score);

        return (TRUE,);
    }

    // if the current high score is less than the new score (we checked equal above)
    let new_high_score = is_le(current_first_place.xp, new_score_xp);
    if (new_high_score == TRUE) {
        // move second place to third place (index 2)
        top_scores.write(2, current_second_place);

        // move first place to second place (index 1)
        top_scores.write(1, current_first_place);

        // set new top score (index 0)
        top_scores.write(0, new_score);

        return (TRUE,);
    }

    // if the new score is equal to the current second place score
    if (current_second_place.xp == new_score_xp) {
        // original second place score keeps second

        // new score is third (index 2)
        top_scores.write(2, new_score);

        return (TRUE,);
    }

    // if the current second place score is less than the new score (we checked equal above)
    let higher_than_second_place = is_le(current_second_place.xp, new_score_xp);
    if (higher_than_second_place == TRUE) {
        // move second place to third place (index 2)
        top_scores.write(2, current_second_place);

        // new score is second (index 1)
        top_scores.write(1, new_score);
        return (TRUE,);
    }

    // if the current third place score is equal to the new score
    if (current_third_place.xp == new_score_xp) {
        // the original third place score stays in third
        // nothing to do, return FALSE to indicate no change was made to scoreboard
        return (FALSE,);
    }

    // if the current third place score is less than the new score (we checked equal above)
    let higher_than_third_place = is_le(current_third_place.xp, new_score_xp);
    if (higher_than_third_place == TRUE) {
        // new score is now third (index 2)
        top_scores.write(2, new_score);
        return (TRUE,);
    }

    return (FALSE,);
}

func _unequip_item{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, item_token_id: Uint256) -> (adventurer_dynamic: AdventurerDynamic) {
    alloc_locals;

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(adventurer_token_id);
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(unpacked_adventurer);

    // Get Item from Loot contract
    let (loot_address) = Module.get_module_address(ModuleIds.Loot);

    let (item) = ILoot.get_item_by_token_id(loot_address, item_token_id);

    assert item.Adventurer = adventurer_token_id.low;

    // Check item is owned by caller
    let (owner) = IERC721.ownerOf(loot_address, item_token_id);
    let (caller) = get_caller_address();
    assert owner = caller;

    // Convert token to Felt
    let (token_to_felt) = _uint_to_felt(item_token_id);

    // Unequip Item
    let (unequiped_adventurer) = AdventurerLib.unequip_item(item, adventurer_dynamic_);

    // Remove item stat boost
    let (stat_boost_removed_adventurer) = AdventurerLib.remove_item_stat_modifier(
        item, unequiped_adventurer
    );

    // Pack adventurer
    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(
        stat_boost_removed_adventurer
    );
    adventurer_dynamic.write(adventurer_token_id, packed_new_adventurer);

    // Update item
    ILoot.update_adventurer(loot_address, item_token_id, 0);

    // Emit event
    emit_adventurer_state(adventurer_token_id);

    return (stat_boost_removed_adventurer,);
}

func _equip_item{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer_token_id: Uint256, item_token_id: Uint256) -> (adventurer_dynamic: AdventurerDynamic) {
    alloc_locals;

    // unpack adventurer
    let (unpacked_adventurer) = get_adventurer_by_id(adventurer_token_id);
    let (adventurer_static_, adventurer_dynamic_) = AdventurerLib.split_data(unpacked_adventurer);

    // Get Item from Loot contract
    let (loot_address) = Module.get_module_address(ModuleIds.Loot);

    // Get Item from Loot contract
    let (item) = ILoot.get_item_by_token_id(loot_address, item_token_id);

    assert item.Adventurer = 0;
    assert item.Bag = 0;

    // Check item owned by Adventurer
    assert_adventurer_is_owner(adventurer_token_id, item_token_id);

    // Check item is owned by caller
    let (owner) = IERC721.ownerOf(loot_address, item_token_id);
    let (caller) = get_caller_address();
    assert owner = caller;

    // Check the adventurer does not currently hold anything in slot
    let (equipped_item) = AdventurerLib.get_item(item, adventurer_dynamic_);

    let check_equipped_item = is_not_zero(equipped_item);

    if (check_equipped_item == TRUE) {
        // unequipping the item will result in the stat modifiers being removed and the adventurer
        // being updated on-chain. For the purposes of this function however, we still have more work
        // to do so we'll take the returned dynamic adventurer and continue modifying it, eventually
        // performing another write.
        let (temp_unequipped_dynamic_adventurer: AdventurerDynamic) = _unequip_item(
            adventurer_token_id, Uint256(equipped_item, 0)
        );

        tempvar temp_unequipped_dynamic_adventurer = temp_unequipped_dynamic_adventurer;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
    } else {
        tempvar temp_unequipped_dynamic_adventurer = adventurer_dynamic_;
        tempvar pedersen_ptr: HashBuiltin* = pedersen_ptr;
        tempvar syscall_ptr: felt* = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
    }

    tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;

    tempvar unequipped_dynamic_adventurer = temp_unequipped_dynamic_adventurer;

    // Convert token to Felt
    let (token_to_felt) = _uint_to_felt(item_token_id);

    // Equip Item
    let (equiped_adventurer) = AdventurerLib.equip_item(
        token_to_felt, item, unequipped_dynamic_adventurer
    );

    // Add item stat boost
    let (stat_boosted_adventurer) = AdventurerLib.apply_item_stat_modifier(
        item, equiped_adventurer
    );

    // Pack adventurer and write to chain
    let (packed_new_adventurer: PackedAdventurerState) = AdventurerLib.pack(
        stat_boosted_adventurer
    );
    adventurer_dynamic.write(adventurer_token_id, packed_new_adventurer);

    let (adventurer_to_felt) = _uint_to_felt(adventurer_token_id);

    // Update item
    ILoot.update_adventurer(loot_address, item_token_id, adventurer_to_felt);

    // Emit event
    emit_adventurer_state(adventurer_token_id);

    return (stat_boosted_adventurer,);
}

func _trigger_beast_counterattack{
    pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(adventurer: AdventurerDynamic) {
    alloc_locals;

    // equipping consumes a turn so process the beasts counter attack
    let (beast_address) = Module.get_module_address(ModuleIds.Beast);
    let beast_token_id = Uint256(adventurer.Beast, 0);
    IBeast.counter_attack(beast_address, beast_token_id);
    return ();
}
