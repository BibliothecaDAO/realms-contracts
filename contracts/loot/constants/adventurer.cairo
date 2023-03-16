// Adventurer Structs
//   A struct that holds the Loot item statistics
// MIT License

%lang starknet

// import item consts
from contracts.loot.constants.item import Item
from contracts.loot.constants.bag import Bag
from contracts.loot.constants.beast import Beast

from starkware.cairo.common.uint256 import Uint256

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

    Status: felt,  // {Idle, Battling, Traveling, Questing, Dead}
    Beast: felt,  // tokenId of the beast the adventurer is battling
    Upgrading: felt,

    // TODO: Consider storing adventurer location information
}

// @notice This is immutable information stored on-chain
// We pack all this information tightly into felts
//    to save on storage costs.
struct AdventurerState {
    // immutable stats
    Race: felt,
    HomeRealm: felt,
    Birthdate: felt,
    Name: felt,
    Order: felt,
    ImageHash1: felt,
    ImageHash2: felt,

    // evolving stats
    Health: felt,  //
    Level: felt,  //

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

    Status: felt,
    Beast: felt,
    Upgrading: felt,
}

// @notice This is immutable information stored on-chain
// We pack all this information tightly into felts
//    to save on storage costs.
struct AdventurerStatic {
    // immutable stats
    Race: felt,
    HomeRealm: felt,
    Birthdate: felt,
    Name: felt,
    Order: felt,
    ImageHash1: felt,
    ImageHash2: felt,
}

// @notice This is immutable information stored on-chain
// We pack all this information tightly into felts
//    to save on storage costs.
struct AdventurerDynamic {
    // evolving stats
    Health: felt,  //
    Level: felt,  //

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

    Status: felt,
    Beast: felt,
    Upgrading: felt,
}

struct ThiefState {
    AdventurerId: Uint256,
    StartTime: felt,
}

struct PackedAdventurerState {
    p1: felt,
    p2: felt,
    p3: felt,
    p4: felt,
}

namespace SHIFT_P_1 {
    const _1 = 2 ** 0;
    const _2 = 2 ** 10;
    const _3 = 2 ** 20;
    const _4 = 2 ** 30;
    const _5 = 2 ** 40;
    const _6 = 2 ** 50;
    const _7 = 2 ** 60;
    const _8 = 2 ** 70;
    const _9 = 2 ** 80;
    const _10 = 2 ** 90;
}

namespace SHIFT_P_4 {
    const _1 = 2 ** 0;
    const _2 = 2 ** 3;
    const _3 = 2 ** 44;
}

namespace AdventurerSlotIds {
    // evolving stats
    const Health = 0;
    const Level = 1;

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
    const XP = 9;

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

    // Packed Stats p4
    const Status = 18;
    const Beast = 19;
    const Upgrading = 20;
}

namespace AdventurerStatus {
    const Idle = 0;
    const Battle = 1;
    const Travel = 2;
    const Quest = 3;
    const Dead = 4;
}

namespace DiscoveryType {
    const Nothing = 0;
    const Beast = 1;
    const Obstacle = 2;
    const Item = 3;
    const Adventurer = 4;
}

namespace ItemDiscoveryType {
    const Gold = 0;
    const Loot = 1;
    const Health = 2;
}

// index for items - used in cast function to set values
const ItemShift = AdventurerSlotIds.WeaponId - 1;
const StatisticShift = AdventurerSlotIds.Strength - 1;
