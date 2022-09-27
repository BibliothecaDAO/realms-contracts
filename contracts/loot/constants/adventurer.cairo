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
    p4: felt,
}

namespace SHIFT_P_1 {
    const _1 = 2 ** 0;
    const _2 = 2 ** 3;
    const _3 = 2 ** 16;
    const _4 = 2 ** 65;
}

namespace SHIFT_P_2 {
    const _1 = 2 ** 0;
    const _2 = 2 ** 13;
    const _3 = 2 ** 22;
    const _4 = 2 ** 27;
    const _5 = 2 ** 37;
    const _6 = 2 ** 47;
    const _7 = 2 ** 57;
    const _8 = 2 ** 67;
    const _9 = 2 ** 77;
    const _10 = 2 ** 87;
    const _11 = 2 ** 97;
    const _12 = 2 ** 107;
    const _13 = 2 ** 117;
}

namespace AdventurerSlotIds {
    // immutable stats
    const Race = 0;  // 3
    const HomeRealm = 1;  // 13
    const Birthdate = 2;
    const Name = 3;

    // evolving stats
    const Health = 4;  //
    const Level = 5;  //
    const Order = 6;  //

    // Physical
    const Strength = 7;
    const Dexterity = 8;
    const Vitality = 9;

    // Mental
    const Intelligence = 10;
    const Wisdom = 11;
    const Charisma = 12;

    // Meta Physical
    const Luck = 13;

    // XP
    const XP = 14;  //
    // store item NFT id when equiped
    // Packed Stats p2
    const WeaponId = 15;
    const ChestId = 16;
    const HeadId = 17;
    const WaistId = 18;

    // Packed Stats p3
    const FeetId = 19;
    const HandsId = 20;
    const NeckId = 21;
    const RingId = 22;
}

// index for items - used in cast function to set values
const ItemShift = AdventurerSlotIds.WeaponId - 1;
const StatisticShift = AdventurerSlotIds.Strength - 1;
