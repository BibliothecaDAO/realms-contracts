# -----------------------------------
# GoblinTown Library
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc

from contracts.settling_game.utils.constants import SHIFT_8_9, MAX_GOBLIN_TOWN_STRENGTH
from contracts.settling_game.utils.game_structs import RealmData, ResourceIds

namespace GoblinTown:
    func pack{range_check_ptr}(strength : felt, spawn_ts : felt) -> (packed : felt):
        let packed = strength + spawn_ts * SHIFT_8_9
        return (packed)
    end

    func unpack{range_check_ptr}(packed : felt) -> (strength : felt, spawn_ts : felt):
        let (spawn_ts, strength) = unsigned_div_rem(packed, SHIFT_8_9)
        return (strength, spawn_ts)
    end

    func calculate_strength{range_check_ptr}(realm_data : RealmData, rnd : felt) -> (
        strength : felt
    ):
        alloc_locals
        let (__fp__, _) = get_fp_and_pc()

        # find the most precious resource the Realm has
        let rd : felt* = &realm_data
        let precious : felt = rd[RealmData.resource_number + realm_data.resource_number]

        # associate the resource with the "default goblin town strength"
        # based on Realm's resources
        let (strength) = get_squad_strength_of_resource(precious)

        # add a random element to the calculated strength
        let strength = strength + rnd

        # cap it
        let (is_within_bounds) = is_le(strength, MAX_GOBLIN_TOWN_STRENGTH)
        if is_within_bounds == TRUE:
            return (strength)
        end

        return (MAX_GOBLIN_TOWN_STRENGTH)
    end

    func get_squad_strength_of_resource(resource : felt) -> (strength : felt):
        # Wood, Stone, Coal -> 1
        # Copper, Obsidian, Silver -> 2
        # Ironwood, ColdIron, Gold -> 3
        # Hartwood, Diamonds, Sapphire -> 4
        # Ruby, DeepCrystal, Ignium -> 5
        # EtherealSilica, TrueIce -> 6
        # TwilightQuartz, AlchemicalSilver -> 7
        # Adamantine, Mithral -> 8
        # Dragonhide -> 9

        if resource == ResourceIds.Wood:
            return (1)
        end
        if resource == ResourceIds.Stone:
            return (1)
        end
        if resource == ResourceIds.Coal:
            return (1)
        end

        if resource == ResourceIds.Copper:
            return (2)
        end
        if resource == ResourceIds.Obsidian:
            return (2)
        end
        if resource == ResourceIds.Silver:
            return (2)
        end
        if resource == ResourceIds.Ironwood:
            return (3)
        end
        if resource == ResourceIds.ColdIron:
            return (3)
        end
        if resource == ResourceIds.Gold:
            return (3)
        end
        if resource == ResourceIds.Hartwood:
            return (4)
        end
        if resource == ResourceIds.Diamonds:
            return (4)
        end
        if resource == ResourceIds.Sapphire:
            return (4)
        end
        if resource == ResourceIds.Ruby:
            return (5)
        end
        if resource == ResourceIds.DeepCrystal:
            return (5)
        end
        if resource == ResourceIds.Ignium:
            return (5)
        end
        if resource == ResourceIds.EtherealSilica:
            return (6)
        end
        if resource == ResourceIds.TrueIce:
            return (6)
        end
        if resource == ResourceIds.TwilightQuartz:
            return (7)
        end
        if resource == ResourceIds.AlchemicalSilver:
            return (7)
        end
        if resource == ResourceIds.Adamantine:
            return (8)
        end
        if resource == ResourceIds.Mithral:
            return (8)
        end
        if resource == ResourceIds.Dragonhide:
            return (9)
        end

        return (1)  # a fallback, just in case
    end
end
