// Item Structs
//   A struct that holds the Loot item statistics
//
//
// MIT License

%lang starknet

from contracts.loot.constants.item import ItemMaterial, Material, ItemType, Type

// psuedo enum
namespace WeaponEfficacy {
    const Low = 0;
    const Medium = 1;
    const High = 2;
}

// Controls damage multiplier
// NOTE: @loothero I've increased by 1, if low is 0, then all damage will be 0
// not sure this is what we want?
namespace WeaponEfficiacyDamageMultiplier {
    const Low = 1;
    const Medium = 2;
    const High = 3;
}
