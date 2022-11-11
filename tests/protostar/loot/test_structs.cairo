%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from contracts.loot.constants.adventurer import (
    Adventurer, 
    AdventurerStatic, 
    AdventurerDynamic, 
    AdventurerState, 
    PackedAdventurerState
)
from contracts.loot.constants.item import Item, ItemIds, ItemType, ItemSlot, ItemMaterial, State
from contracts.loot.constants.rankings import ItemRank

const TEST_WEAPON_TOKEN_ID = 20;

namespace TestAdventurerState {
    // immutable stats
    const Race = 1;  // 3
    const HomeRealm = 2;  // 13
    const Birthdate = 1662888731;
    const Name = 'loaf';

    // evolving stats
    const Health = 5000;  //

    const Level = 500;  //
    const Order = 12;  //

    // Physical
    const Strength = 1000;
    const Dexterity = 1000;
    const Vitality = 1000;

    // Mental
    const Intelligence = 1000;
    const Wisdom = 1000;
    const Charisma = 1000;

    // Meta Physical
    const Luck = 1000;

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
}

func get_adventurer_state{syscall_ptr: felt*, range_check_ptr}() -> (
    adventurer_static: AdventurerStatic, adventurer_dynamic: AdventurerDynamic
) {
    alloc_locals;

    return (
        AdventurerStatic(
            TestAdventurerState.Race,
            TestAdventurerState.HomeRealm,
            TestAdventurerState.Birthdate,
            TestAdventurerState.Name,
            TestAdventurerState.Order,
        ),
        AdventurerDynamic(
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
        )
    );
}

func get_item{syscall_ptr: felt*, range_check_ptr}() -> (item: Item) {
    alloc_locals;

    return (
        Item(
        ItemIds.Katana,
        ItemSlot.Katana,
        ItemType.Katana,
        ItemMaterial.Katana,
        ItemRank.Katana,
        1,
        1,
        1,
        20,
        1,
        1,
        0,
        0
        ),
    );
}
