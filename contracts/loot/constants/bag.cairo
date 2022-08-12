# Item Structs
#   A struct that holds the Loot item statistics
#
#
# MIT License

%lang starknet

from contracts.loot.constants.item import Item

struct Bag:
    member Id : felt  # item id 1 - 100
    member Age : felt  # Timestamp of when bag was created
    member Type : felt # Provide opportunity for bag types such as elemental
    member XP : felt # Bag experience
    member Level : felt # Bag levle
    member Capacity : felt # Carrying capacity of the bag
    member Items : Item* # items in the bags
end