%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from contracts.loot.constants.adventurer import (
    Adventurer,
    AdventurerState,
    PackedAdventurerState,
    AdventurerStatus,
)
from contracts.loot.constants.item import Item, ItemIds, ItemType, ItemSlot, ItemMaterial, State
from contracts.loot.constants.rankings import ItemRank
from contracts.loot.constants.beast import Beast, BeastStatic, BeastDynamic
from contracts.loot.constants.obstacle import Obstacle, ObstacleUtils
from contracts.loot.beast.stats.beast import BeastStats
from contracts.loot.loot.stats.item import ItemStats

const TEST_WEAPON_TOKEN_ID = 20;
const TEST_DAMAGE_HEALTH_REMAINING = 50;
const TEST_DAMAGE_OVERKILL = 100;

namespace TestAdventurerState {
    // immutable stats
    const Race = 1;  // 3
    const HomeRealm = 2;  // 13
    const Birthdate = 1662888731;
    const Name = 'loaf';
    const Order = 12;  //
    const ImageHash1 = 'QmUn4BZtz4tw3rzpZHpT2oE';
    const ImageHash2 = 'o6guw2FxsiPEyvfRFnUJWzZ';

    // evolving stats
    const Health = 100;  //

    const Level = 1;  //

    // Physical
    const Strength = 0;
    const Dexterity = 0;
    const Vitality = 0;

    // Mental
    const Intelligence = 0;
    const Wisdom = 0;
    const Charisma = 0;

    // Meta Physical
    const Luck = 0;

    const XP = 1000000;  //

    // store item NFT id when equiped
    // Packed Stats p2
    const WeaponId = 1001;
    const ChestId = 1002;
    const HeadId = 1003;
    const WaistId = 1004;
    const FeetId = 1005;
    const HandsId = 1006;
    const NeckId = 1007;
    const RingId = 1008;

    // Packed Stats p3
    const Status = AdventurerStatus.Idle;
    const Beast = 0;
    const Upgrading = 0;
}

func get_adventurer_state{syscall_ptr: felt*, range_check_ptr}() -> (
    adventurer_state: AdventurerState
) {
    return (
        AdventurerState(
        TestAdventurerState.Race,
        TestAdventurerState.HomeRealm,
        TestAdventurerState.Birthdate,
        TestAdventurerState.Name,
        TestAdventurerState.Order,
        TestAdventurerState.ImageHash1,
        TestAdventurerState.ImageHash2,
        TestAdventurerState.Health,
        TestAdventurerState.Level,
        TestAdventurerState.Strength,
        TestAdventurerState.Dexterity,
        TestAdventurerState.Vitality,
        TestAdventurerState.Intelligence,
        TestAdventurerState.Wisdom,
        TestAdventurerState.Charisma,
        TestAdventurerState.Luck,
        TestAdventurerState.XP,
        TestAdventurerState.WeaponId,
        TestAdventurerState.ChestId,
        TestAdventurerState.HeadId,
        TestAdventurerState.WaistId,
        TestAdventurerState.FeetId,
        TestAdventurerState.HandsId,
        TestAdventurerState.NeckId,
        TestAdventurerState.RingId,
        TestAdventurerState.Status,
        TestAdventurerState.Beast,
        TestAdventurerState.Upgrading,
        ),
    );
}

namespace TestUtils {
    // create_item returns an Item corresponding to the provided item_id and greatness
    // parameters: item_id, greatness
    // returns: An Item
    func create_item{syscall_ptr: felt*, range_check_ptr}(item_id: felt, greatness: felt) -> (
        item: Item
    ) {
        alloc_locals;

        let (slot) = ItemStats.item_slot(item_id);
        let (type) = ItemStats.item_type(item_id);
        let (material) = ItemStats.item_material(item_id);
        let (rank) = ItemStats.item_rank(item_id);
        let prefix_1 = 1;
        let prefix_2 = 1;
        let suffix = 1;
        let created_block = 0;
        let xp = 0;
        let adventurer = 0;
        let bag = 0;

        return (
            Item(
            item_id,
            slot,
            type,
            material,
            rank,
            prefix_1,
            prefix_2,
            suffix,
            greatness,
            created_block,
            xp,
            adventurer,
            bag
            ),
        );
    }

    // @notice creates an empty item object
    // @return item: empty item
    func create_zero_item{syscall_ptr: felt*, range_check_ptr}() -> (item: Item) {
        let zero_item = Item(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

        return (zero_item,);
    }

    // create_beast returns a Beast corresponding to the provided beast_id
    // parameters: beast_id
    // returns: A Beast
    func create_beast{syscall_ptr: felt*, range_check_ptr}(beast_id: felt, level: felt) -> (
        beast: Beast
    ) {
        alloc_locals;

        let (attack_type) = BeastStats.get_attack_type_from_id(beast_id);
        let (armor_type) = BeastStats.get_armor_type_from_id(beast_id);
        let (rank) = BeastStats.get_rank_from_id(beast_id);
        let health = 100;
        let prefix_1 = 1;
        let prefix_2 = 1;
        let adventurer = 0;
        let xp = 0;
        let level = level;
        let slain_on_date = 0;
        return (
            Beast(
            beast_id,
            attack_type,
            armor_type,
            rank,
            prefix_1,
            prefix_2,
            health,
            adventurer,
            xp,
            level,
            slain_on_date
            ),
        );
    }

    // create_obstacle returns an Obstacle corresponding to the provided obstacle_id and greatness
    // parameters: obstacle_id, greatness
    // returns: An Obstacle
    func create_obstacle{syscall_ptr: felt*, range_check_ptr}(
        obstacle_id: felt, greatness: felt
    ) -> (obstacle: Obstacle) {
        alloc_locals;

        let (type) = ObstacleUtils.get_type_from_id(obstacle_id);
        let (rank) = ObstacleUtils.get_rank_from_id(obstacle_id);
        let (damage_location) = ObstacleUtils.get_damage_location_from_id(obstacle_id);
        let prefix_1 = 1;
        let prefix_2 = 1;

        return (
            Obstacle(
            obstacle_id,
            type,
            rank,
            prefix_1,
            prefix_2,
            greatness,
            damage_location
            ),
        );
    }
}
