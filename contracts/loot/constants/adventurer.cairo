# Item Structs
#   A struct that holds the Loot item statistics
#
#
# MIT License

%lang starknet

#import item consts
from contracts.loot.constants.item import Item
from contracts.loot.constants.bag import Bag

struct Adventurer:
    member Id : felt # primary key for adventurer

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

    # other unique state
    member Health : felt
    member Birthdate : felt # Birthdate/Age of Adventure
    member Name : felt  # Name of Adventurer
    member XP : felt # 
    member Level : felt
    member Order : felt
end

struct AdventurerState:
    # other unique state p1
    member Class : felt
    member Age : felt
    member Name : felt  # mint time
    member XP : felt
    member Order : felt

    # store item NFT id when equiped
    # Packed Stats p2
    member NeckId : felt
    member WeaponId : felt
    member RingId : felt
    member ChestId : felt

    # Packed Stats p3
    member HeadId : felt
    member WaistId : felt
    member FeetId : felt
    member HandsId : felt
end

struct PackedAdventurerStats:
    member p1 : felt
    member p2 : felt
    member p3 : felt
end