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

namespace WeaponEfficacy:
    const Low = 0
    const Medium = 1
    const High = 2
end

func weapon_vs_armor_efficacy{syscall_ptr : felt*, range_check_ptr}(
        weapon_id : felt, armor_id : felt
    ) -> (class : felt):
        alloc_locals

        # Get weapon_type (see Type and ItemType from item.cairo) from passed in itemId
        # Get armor type (see Type and ItemType from item.cairo) from passed in item
        
        if weapon_type == blade {
            if armor_type == cloth { return WeaponEfficacy.High}
            if armor_type == hide {return WeaponEfficacy.Medium}
            if armor_type == metal {return WeaponEfficacy.Low}
        } else if weapon_type == bludgeon {
            if armor_type == cloth { return WeaponEfficacy.Low}
            if armor_type == hide {return WeaponEfficacy.High}
            if armor_type == metal {return WeaponEfficacy.Medium}
        } else if weapon_type == magic {
            if armor_type == cloth { return WeaponEfficacy.Medium}
            if armor_type == hide {return WeaponEfficacy.Low}
            if armor_type == metal {return WeaponEfficacy.High}
        }
}