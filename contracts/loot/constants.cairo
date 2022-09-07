# Item Structs
#   A struct that holds the Loot item statistics
#
#
# MIT License

%lang starknet

struct State:
    member Bagged : felt # protected in a loot bag
    member Equipped : felt # equipped on an adventurer
    member Loose : felt # not in loot bag or equipped (i.e on a table at a market)
end

struct Bag:
    member Id : felt  # item id 1 - 100
    member Age : felt  # Timestamp of when bag was created
    member Type : felt # Provide opportunity for bag types such as elemental
    member XP : felt # Bag experience
    member Level : felt # Bag levle
    member Capacity : felt # Carrying capacity of the bag
    member Items : Item* # items in the bags
end
    
# Loot item shape. This is the on-chain metadata of each item.
struct Item:
    member Id : felt  # item id 1 - 100
    member Type : felt # weapon.blade, armor.foot, jewlery.ring
    member Material : felt # the material of the item
    member Rank : felt # 1 is best (Divine Robe = 1, Silk Robe = 2, Linen Robe = 3, Robe = 4, Shirt = 5)
    member Prefix_1 : felt  # First part of the name prefix (i.e Demon)
    member Prefix_2 : felt  # Second part of the name prefix (i.e Grasp)
    member Suffix : felt  # Stored value if item has a Suffix (i.e of Power)
    member Greatness : felt  # Stored value if item has a Greatness
    member Age : felt  # Timestamp of when item was created
    member XP : felt  # accured XP
    member State : State # the state of the item: {bagged, equipped, cooldown, etc}
end

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