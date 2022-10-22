from collections import namedtuple
from enum import IntEnum
from realms_cli.utils import pack_values

Cost = namedtuple('Cost', 'resource_count bits packed_ids packed_amounts')
CostWithLords = namedtuple(
    'Cost', 'resource_count bits packed_ids packed_amounts lords')
Troop = namedtuple('Troop', 'type tier agility attack defense vitality wisdom')


class TroopId(IntEnum):
    LightCavalry = 1
    HeavyCavalry = 2
    Archer = 3
    Longbow = 4
    Mage = 5
    Arcanist = 6
    LightInfantry = 7
    HeavyInfantry = 8


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
    DesertGlass = 23
    DivineCloth = 24
    CuriousSpore = 25
    UnrefinedOre = 26
    SunkenShekel = 27
    Demonhide = 28


class BuildingId(IntEnum):
    WorkHut = 1
    StoreHouse = 2
    Granary = 3
    Farm = 4
    FishingVillage = 5
    Barracks = 6
    MageTower = 7
    ArcherTower = 8
    Castle = 9


BUILDING_COSTS = {
    BuildingId.WorkHut: CostWithLords(
        2,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone]),
        pack_values([40, 50]),
        0
    ),
    BuildingId.StoreHouse: CostWithLords(
        2,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone]),
        pack_values([40, 50]),
        0
    ),
    BuildingId.Granary: CostWithLords(
        2,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone]),
        pack_values([40, 50]),
        0
    ),
    BuildingId.Farm: CostWithLords(
        10,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone,
             ResourceIds.Coal,
             ResourceIds.Copper,
             ResourceIds.Obsidian,
             ResourceIds.Silver,
             ResourceIds.Ironwood,
             ResourceIds.ColdIron,
             ResourceIds.Gold,
             ResourceIds.Hartwood]),
        pack_values([5, 4, 4, 3, 2, 2, 1, 1, 1, 1]),
        0
    ),
    BuildingId.FishingVillage: CostWithLords(
        7,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone,
             ResourceIds.Coal,
             ResourceIds.Copper,
             ResourceIds.Obsidian,
             ResourceIds.Silver,
             ResourceIds.Ironwood,
             ResourceIds.ColdIron,
             ResourceIds.Gold,
             ResourceIds.Hartwood]),
        pack_values([6, 4, 4, 2, 3, 1, 2, 1, 1, 1]),
        0
    ),
    BuildingId.Barracks: CostWithLords(
        7,
        8,
        pack_values(
            [ResourceIds.ColdIron,
             ResourceIds.Gold,
             ResourceIds.Hartwood,
             ResourceIds.Sapphire,
             ResourceIds.DeepCrystal,
             ResourceIds.TrueIce,
             ResourceIds.Dragonhide]),
        pack_values([5, 4, 18, 22, 10, 12, 2]),
        0
    ),
    BuildingId.MageTower: CostWithLords(
        9,
        8,
        pack_values(
            [ResourceIds.Gold,
             ResourceIds.Hartwood,
             ResourceIds.Diamonds,
             ResourceIds.Ignium,
             ResourceIds.EtherealSilica,
             ResourceIds.TrueIce,
             ResourceIds.TwilightQuartz,
             ResourceIds.AlchemicalSilver,
             ResourceIds.Mithral]),
        pack_values([3, 12, 25, 6, 10, 5, 2, 3, 2]),
        0
    ),
    BuildingId.ArcherTower: CostWithLords(
        8,
        8,
        pack_values(
            [ResourceIds.ColdIron,
             ResourceIds.Gold,
             ResourceIds.Hartwood,
             ResourceIds.Sapphire,
             ResourceIds.Ruby,
             ResourceIds.DeepCrystal,
             ResourceIds.AlchemicalSilver,
             ResourceIds.Adamantine]),
        pack_values([5, 2, 10, 7, 12, 12, 7, 6]),
        0
    ),
    BuildingId.Castle: CostWithLords(
        8,
        8,
        pack_values(
            [ResourceIds.Gold,
             ResourceIds.Hartwood,
             ResourceIds.Diamonds,
             ResourceIds.Ruby,
             ResourceIds.Ignium,
             ResourceIds.EtherealSilica,
             ResourceIds.TwilightQuartz,
             ResourceIds.Mithral]),
        pack_values([1, 10, 10, 14, 10, 9, 10, 1]),
        0
    )
}


TROOP_COSTS = {
    TroopId.LightCavalry: Cost(
        4,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Obsidian,
                    ResourceIds.ColdIron, ResourceIds.Sapphire]),
        pack_values([10, 5, 2, 2]),
    ),
    TroopId.HeavyCavalry: Cost(
        4,
        8,
        pack_values([ResourceIds.Stone, ResourceIds.Silver,
                    ResourceIds.Diamonds, ResourceIds.EtherealSilica]),
        pack_values([6, 10, 5, 1]),
    ),
    TroopId.Archer: Cost(
        4,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Coal,
                    ResourceIds.Silver, ResourceIds.Sapphire]),
        pack_values([10, 10, 2, 2]),
    ),
    TroopId.Longbow: Cost(
        5,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone,
                    ResourceIds.Obsidian, ResourceIds.Ironwood, ResourceIds.Ruby]),
        pack_values([5, 9, 10, 7, 4]),
    ),
    TroopId.Mage: Cost(
        3,
        8,
        pack_values(
            [ResourceIds.Coal, ResourceIds.ColdIron, ResourceIds.Ignium]),
        pack_values([12, 2, 2]),
    ),
    TroopId.Arcanist: Cost(
        4,
        8,
        pack_values([ResourceIds.Stone, ResourceIds.Copper, ResourceIds.Hartwood,
                    ResourceIds.DeepCrystal]),
        pack_values([10, 7, 5, 4]),
    ),
    TroopId.LightInfantry: Cost(
        3,
        8,
        pack_values(
            [ResourceIds.Copper, ResourceIds.ColdIron, ResourceIds.Ignium]),
        pack_values([10, 2, 2]),
    ),
    TroopId.HeavyInfantry: Cost(
        4,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Gold,
                    ResourceIds.EtherealSilica, ResourceIds.TrueIce]),
        pack_values([5, 5, 2, 2]),
    )
}
