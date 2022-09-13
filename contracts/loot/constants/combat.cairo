# Item Structs
#   A struct that holds the Loot item statistics
#
#
# MIT License

%lang starknet

from contracts.loot.constants.item import (
    ItemMaterial,
    Material,
    ItemType,
    Type,
)

# psuedo enum
namespace WeaponEfficacy:
    const Low = 0
    const Medium = 1
    const High = 2
end

# Controls damage multiplier
namespace WeaponEfficiacyDamageMultiplier:
    const Low = 0
    const Medium = 1
    const High = 2
end

