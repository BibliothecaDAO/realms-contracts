// Adventurer Structs
//   A struct that holds the Loot item statistics
// MIT License

%lang starknet

// import item consts
from contracts.loot.constants.item import Item
from contracts.loot.constants.bag import Bag

// @notice This is viewable information of the Adventurer. We DO NOT store this on-chain.
//         This is the object that is returned when requesting the Adventurer by ID.
struct Adventurer {
    // Physical
    Strength: felt,
    Dexterity: felt,
    Vitality: felt,

    // Mental
    Intelligence: felt,
    Wisdom: felt,
    Charisma: felt,

    // Meta Physical
    Luck: felt,

    // store item NFT id when equiped
    Weapon: Item,
    Chest: Item,
    Head: Item,
    Waist: Item,
    Feet: Item,
    Hands: Item,
    Neck: Item,
    Ring: Item,

    // adventurers can carry multiple bags
    Bags: Bag*,

    // immutable stats
    Race: felt,  // 1 - 6
    HomeRealm: felt,  // The OG Realm the Adventurer was birthed on 1 - 8000
    Name: felt,  // Name of Adventurer - encoded name max 10 letters
    Birthdate: felt,  // Birthdate/Age of Adventure timestamp

    // evolving stats
    Health: felt,  // 1-1000
    XP: felt,  // 1 - 10000000
    Level: felt,  // 1- 100
    Order: felt,  // 1 - 16
}

// @notice This is immutable information stored on-chain
// We pack all this information tightly into felts
//    to save on storage costs.

// immutable stats
struct AdventurerStatic {
    Race: felt,
    HomeRealm: felt,
    Birthdate: felt,
    Name: felt,
    Order: felt,
}

// evolving stats
struct AdventurerDynamic {
    Health: felt,
    Level: felt,

    // Physical
    Strength: felt,
    Dexterity: felt,
    Vitality: felt,

    // Mental
    Intelligence: felt,
    Wisdom: felt,
    Charisma: felt,

    // Meta Physical
    Luck: felt,

    // XP
    XP: felt,
    // store item NFT id when equiped
    // Packed Stats p2
    WeaponId: felt,
    ChestId: felt,
    HeadId: felt,
    WaistId: felt,

    // Packed Stats p3
    FeetId: felt,
    HandsId: felt,
    NeckId: felt,
    RingId: felt,
}

struct AdventurerState {
    // immutable stats
    Race: felt,  // 3
    HomeRealm: felt,  // 13
    Birthdate: felt,
    Name: felt,

    // evolving stats
    Health: felt,  //
    Level: felt,  //
    Order: felt,  //

    // Physical
    Strength: felt,
    Dexterity: felt,
    Vitality: felt,

    // Mental
    Intelligence: felt,
    Wisdom: felt,
    Charisma: felt,

    // Meta Physical
    Luck: felt,

    // XP
    XP: felt,  //
    // store item NFT id when equiped
    // Packed Stats p2
    WeaponId: felt,
    ChestId: felt,
    HeadId: felt,
    WaistId: felt,

    // Packed Stats p3
    FeetId: felt,
    HandsId: felt,
    NeckId: felt,
    RingId: felt,
}

struct PackedAdventurerState {
    p1: felt,
    p2: felt,
    p3: felt,
}

namespace SHIFT_P_1 {
    const _1 = 2 ** 0;
    const _2 = 2 ** 13;
    const _3 = 2 ** 22;
    const _4 = 2 ** 32;
    const _5 = 2 ** 42;
    const _6 = 2 ** 52;
    const _7 = 2 ** 62;
    const _8 = 2 ** 72;
    const _9 = 2 ** 82;
    const _10 = 2 ** 92;
}

namespace AdventurerSlotIds {
    // evolving stats
    const Health = 0;  //
    const Level = 1;  //

    // Physical
    const Strength = 2;
    const Dexterity = 3;
    const Vitality = 4;

    // Mental
    const Intelligence = 5;
    const Wisdom = 6;
    const Charisma = 7;

    // Meta Physical
    const Luck = 8;

    // XP
    const XP = 9;  //
    // store item NFT id when equiped
    // Packed Stats p2
    const WeaponId = 10;
    const ChestId = 11;
    const HeadId = 12;
    const WaistId = 13;

    // Packed Stats p3
    const FeetId = 14;
    const HandsId = 15;
    const NeckId = 16;
    const RingId = 17;
}

// index for items - used in cast function to set values
const ItemShift = AdventurerSlotIds.WeaponId - 1;
const StatisticShift = AdventurerSlotIds.Strength - 1;
