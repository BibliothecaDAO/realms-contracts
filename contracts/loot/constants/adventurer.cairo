# Adventurer Structs
#   A struct that holds the Loot item statistics
# MIT License

%lang starknet

# import item consts
from contracts.loot.constants.item import Item
from contracts.loot.constants.bag import Bag

# @notice This is viewable information of the Adventurer. We DO NOT store this on-chain.
#         This is the object that is returned when requesting the Adventurer by ID.
struct Adventurer:
    # Physical
    member Strength : felt
    member Dexterity : felt
    member Vitality : felt

    # Mental
    member Intelligence : felt
    member Wisdom : felt
    member Charisma : felt

    # Meta Physical
    member Luck : felt

    # store item NFT id when equiped
    member Weapon : Item
    member Chest : Item
    member Head : Item
    member Waist : Item
    member Feet : Item
    member Hands : Item
    member Neck : Item
    member Ring : Item

    # adventurers can carry multiple bags
    member Bags : Bag*

    # immutable stats
    member Race : felt  # 1 - 6
    member HomeRealm : felt  # The OG Realm the Adventurer was birthed on 1 - 8000
    member Name : felt  # Name of Adventurer - encoded name max 10 letters
    member Birthdate : felt  # Birthdate/Age of Adventure timestamp

    # evolving stats
    member Health : felt  # 1-1000
    member XP : felt  # 1 - 10000000
    member Level : felt  # 1- 100
    member Order : felt  # 1 - 16
end

# @notice This is immutable information stored on-chain
# We pack all this information tightly into felts
#    to save on storage costs.
struct AdventurerState:
    # immutable stats
    member Race : felt  # 3
    member HomeRealm : felt  # 13
    member Birthdate : felt
    member Name : felt

    # evolving stats
    member Health : felt  #
    member Level : felt  #
    member Order : felt  #

    # Physical
    member Strength : felt
    member Dexterity : felt
    member Vitality : felt

    # Mental
    member Intelligence : felt
    member Wisdom : felt
    member Charisma : felt

    # Meta Physical
    member Luck : felt

    # XP
    member XP : felt  #
    # store item NFT id when equiped
    # Packed Stats p2
    member WeaponId : felt
    member ChestId : felt
    member HeadId : felt
    member WaistId : felt

    # Packed Stats p3
    member FeetId : felt
    member HandsId : felt
    member NeckId : felt
    member RingId : felt
end

struct PackedAdventurerState:
    member p1 : felt
    member p2 : felt
    member p3 : felt
    member p4 : felt
end

namespace SHIFT_P_1:
    const _1 = 2 ** 0
    const _2 = 2 ** 3
    const _3 = 2 ** 16
    const _4 = 2 ** 65
end

namespace SHIFT_P_2:
    const _1 = 2 ** 0
    const _2 = 2 ** 13
    const _3 = 2 ** 22
    const _4 = 2 ** 27
    const _5 = 2 ** 37
    const _6 = 2 ** 47
    const _7 = 2 ** 57
    const _8 = 2 ** 67
    const _9 = 2 ** 77
    const _10 = 2 ** 87
    const _11 = 2 ** 97
    const _12 = 2 ** 107
    const _13 = 2 ** 117
end

namespace AdventurerSlotIds:
    # immutable stats
    const Race = 0  # 3
    const HomeRealm = 1  # 13
    const Birthdate = 2
    const Name = 3

    # evolving stats
    const Health = 4  #
    const Level = 5  #
    const Order = 6  #

    # Physical
    const Strength = 7
    const Dexterity = 8
    const Vitality = 9

    # Mental
    const Intelligence = 10
    const Wisdom = 11
    const Charisma = 12

    # Meta Physical
    const Luck = 13

    # XP
    const XP = 14  #
    # store item NFT id when equiped
    # Packed Stats p2
    const WeaponId = 15
    const ChestId = 16
    const HeadId = 17
    const WaistId = 18

    # Packed Stats p3
    const FeetId = 19
    const HandsId = 20
    const NeckId = 21
    const RingId = 22
end

# index for items - used in cast function to set values
const ItemShift = AdventurerSlotIds.WeaponId - 1
const StatisticShift = AdventurerSlotIds.Strength - 1
