// Bag Structs
//
//
// MIT License

%lang starknet

from contracts.loot.constants.item import Item

struct Bag {
    Age: felt,  // Timestamp of when bag was created
    Type: felt,  // Provide opportunity for different bag types (i.e elemental)
    XP: felt,  // Bag experience
    Level: felt,  // Bag level
    Capacity: felt,  // Carrying capacity of the bag
    Items: Item*,  // items in the bags
}

struct BagState {
    Age: felt,  // Timestamp of when bag was created
    Type: felt,  // Provide opportunity for different bag types (i.e elemental)
    XP: felt,  // Bag experience
    Level: felt,  // Bag level
    Capacity: felt,  // Carrying capacity of the bag
    Items: felt*,  // Store ID of items only. Not the full Items.
}
