from collections import namedtuple
from enum import IntEnum
from tests.shared import pack_values

Cost = namedtuple('Cost', 'resource_count bits packed_ids packed_amounts')


class ResourceIds(IntEnum):
    Wood = 1
    Stone = 2
    Coal = 3
    Copper = 4
    Obsidian = 5
    Silver = 6
    Ironwood = 7
    ColdIron = 8
    Gold = 9
    Hartwood = 10
    Diamonds = 11
    Sapphire = 12
    Ruby = 13
    DeepCrystal = 14
    Ignium = 15
    EtherealSilica = 16
    TrueIce = 17
    TwilightQuartz = 18
    AlchemicalSilver = 19
    Adamantine = 20
    Mithral = 21
    Dragonhide = 22


class BuildingId(IntEnum):
    Fairgrounds = 1
    RoyalReserve = 2
    GrandMarket = 3
    Castle = 4
    Guild = 5
    OfficerAcademy = 6
    Granary = 7
    Housing = 8
    Amphitheater = 9
    Carpenter = 10
    School = 11
    Symposium = 12
    LogisticsOffice = 13
    ExplorersGuild = 14
    ParadeGrounds = 15
    ResourceFacility = 16
    Dock = 17
    Fishmonger = 18
    Farms = 19
    Hamlet = 20


BUILDING_COSTS = {
    BuildingId.Fairgrounds: Cost(
        3,
        8,
        pack_values(
            [ResourceIds.Wood, ResourceIds.Copper, ResourceIds.Silver]),
        pack_values([100, 90, 80]),
    ),
    BuildingId.RoyalReserve: Cost(
        5,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Silver,
                ResourceIds.Ironwood,
                ResourceIds.ColdIron,
                ResourceIds.Gold,
            ]
        ),
        pack_values([60, 50, 60, 50, 50]),
    ),
    BuildingId.GrandMarket: Cost(
        4,
        8,
        pack_values(
            [ResourceIds.Wood, ResourceIds.Gold,
                ResourceIds.Hartwood, ResourceIds.Adamantine]
        ),
        pack_values([30, 70, 80, 10]),
    ),
    BuildingId.Castle: Cost(
        3,
        8,
        pack_values(
            [ResourceIds.Wood, ResourceIds.Copper, ResourceIds.Silver]),
        pack_values([100, 90, 80]),
    ),
    BuildingId.Guild: Cost(
        5,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Silver,
                ResourceIds.Ironwood,
                ResourceIds.ColdIron,
                ResourceIds.Gold,
            ]
        ),
        pack_values([60, 50, 60, 50, 50]),
    ),
    BuildingId.OfficerAcademy: Cost(
        9,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Gold,
                ResourceIds.Hartwood,
                ResourceIds.Ruby,
                ResourceIds.DeepCrystal,
                ResourceIds.Ignium,
                ResourceIds.TrueIce,
                ResourceIds.Adamantine,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([30, 70, 80, 2, 20, 20, 20, 10, 1]),
    ),
    BuildingId.Granary: Cost(
        3,
        8,
        pack_values(
            [ResourceIds.Wood, ResourceIds.Copper, ResourceIds.Silver]),
        pack_values([100, 90, 80]),
    ),
    BuildingId.Housing: Cost(
        6,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Silver,
                ResourceIds.Ironwood,
                ResourceIds.ColdIron,
                ResourceIds.Gold,
                ResourceIds.Mithral,
            ]
        ),
        pack_values([60, 50, 60, 50, 50, 1]),
    ),
    BuildingId.Amphitheater: Cost(
        6,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Gold,
                ResourceIds.Hartwood,
                ResourceIds.DeepCrystal,
                ResourceIds.EtherealSilica,
                ResourceIds.Adamantine,
            ]
        ),
        pack_values([30, 70, 80, 20, 20, 10]),
    ),
    BuildingId.Carpenter: Cost(
        7,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Obsidian,
                ResourceIds.Silver,
                ResourceIds.Ironwood,
                ResourceIds.Gold,
                ResourceIds.Ignium,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([50, 50, 50, 30, 50, 10, 1]),
    ),
    BuildingId.School: Cost(
        8,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Stone,
                ResourceIds.Copper,
                ResourceIds.Gold,
                ResourceIds.Hartwood,
                ResourceIds.Sapphire,
                ResourceIds.DeepCrystal,
                ResourceIds.TrueIce,
                ResourceIds.AlchemicalSilver,
            ]
        ),
        pack_values([110, 110, 110, 90, 90, 110, 10, 110, 10]),
    ),
    BuildingId.Symposium: Cost(
        3,
        8,
        pack_values(
            [ResourceIds.Wood, ResourceIds.Silver, ResourceIds.TrueIce]),
        pack_values([20, 40, 10]),
    ),
    BuildingId.LogisticsOffice: Cost(
        5,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Silver,
                ResourceIds.Ironwood,
                ResourceIds.Gold,
                ResourceIds.TwilightQuartz,
            ]
        ),
        pack_values([10, 40, 10, 70, 10]),
    ),
    BuildingId.ExplorersGuild: Cost(
        7,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Coal,
                ResourceIds.Copper,
                ResourceIds.Gold,
                ResourceIds.Hartwood,
                ResourceIds.AlchemicalSilver,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([70, 110, 110, 100, 100, 10, 1]),
    ),
    BuildingId.ParadeGrounds: Cost(
        9,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Silver,
                ResourceIds.ColdIron,
                ResourceIds.Gold,
                ResourceIds.Diamonds,
                ResourceIds.Sapphire,
                ResourceIds.Ruby,
                ResourceIds.Mithral,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([120, 100, 100, 100, 20, 20, 20, 10, 1]),
    ),
    BuildingId.ResourceFacility: Cost(
        9,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Silver,
                ResourceIds.ColdIron,
                ResourceIds.Gold,
                ResourceIds.Diamonds,
                ResourceIds.Sapphire,
                ResourceIds.Ruby,
                ResourceIds.Mithral,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([120, 100, 100, 100, 20, 20, 20, 10, 1]),
    ),
    BuildingId.Dock: Cost(
        9,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Silver,
                ResourceIds.ColdIron,
                ResourceIds.Gold,
                ResourceIds.Diamonds,
                ResourceIds.Sapphire,
                ResourceIds.Ruby,
                ResourceIds.Mithral,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([120, 100, 100, 100, 20, 20, 20, 10, 1]),
    ),
    BuildingId.Fishmonger: Cost(
        9,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Silver,
                ResourceIds.ColdIron,
                ResourceIds.Gold,
                ResourceIds.Diamonds,
                ResourceIds.Sapphire,
                ResourceIds.Ruby,
                ResourceIds.Mithral,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([120, 100, 100, 100, 20, 20, 20, 10, 1]),
    ),
    BuildingId.Farms: Cost(
        9,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Silver,
                ResourceIds.ColdIron,
                ResourceIds.Gold,
                ResourceIds.Diamonds,
                ResourceIds.Sapphire,
                ResourceIds.Ruby,
                ResourceIds.Mithral,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([120, 100, 100, 100, 20, 20, 20, 10, 1]),
    ),
    BuildingId.Hamlet: Cost(
        9,
        8,
        pack_values(
            [
                ResourceIds.Wood,
                ResourceIds.Silver,
                ResourceIds.ColdIron,
                ResourceIds.Gold,
                ResourceIds.Diamonds,
                ResourceIds.Sapphire,
                ResourceIds.Ruby,
                ResourceIds.Mithral,
                ResourceIds.Dragonhide,
            ]
        ),
        pack_values([120, 100, 100, 100, 20, 20, 20, 10, 1]),
    )
}


RESOURCE_UPGRADE_COST = {
    ResourceIds.Wood: Cost(
        5,
        8,
        pack_values(
            [ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal, ResourceIds.Copper, ResourceIds.Obsidian]),
        pack_values([20, 20, 20, 20, 20]),
    ),
    ResourceIds.Stone: Cost(
        5,
        8,
        pack_values(
            [ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal, ResourceIds.Copper, ResourceIds.Obsidian]),
        pack_values([20, 20, 20, 20, 20]),
    ),
    ResourceIds.Coal: Cost(
        5,
        8,
        pack_values(
            [ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal, ResourceIds.Copper, ResourceIds.Obsidian]),
        pack_values([20, 20, 20, 20, 20]),
    ),
    ResourceIds.Copper: Cost(
        5,
        8,
        pack_values(
            [ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal, ResourceIds.Copper, ResourceIds.Obsidian]),
        pack_values([20, 20, 20, 20, 20]),
    ),
}
