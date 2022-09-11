from collections import namedtuple
from enum import IntEnum
from realms_cli.shared import pack_values

Cost = namedtuple('Cost', 'resource_count bits packed_ids packed_amounts')
CostWithLords = namedtuple(
    'Cost', 'resource_count bits packed_ids packed_amounts lords')
Troop = namedtuple('Troop', 'type tier agility attack defense vitality wisdom')


class TroopId(IntEnum):
    Skirmisher = 1
    Longbow = 2
    Crossbow = 3
    Pikeman = 4
    Knight = 5
    Paladin = 6
    Ballista = 7
    Mangonel = 8
    Trebuchet = 9
    Apprentice = 10
    Mage = 11
    Arcanist = 12


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
        9,
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
             ResourceIds.Gold]),
        pack_values([15, 10, 14, 7,	8, 4, 3, 2, 3]),
        0
    ),
    BuildingId.FishingVillage: CostWithLords(
        7,
        8,
        pack_values(
            [ResourceIds.Wood,
             ResourceIds.Stone,
             ResourceIds.Copper,
             ResourceIds.Silver,
             ResourceIds.Ironwood,
             ResourceIds.ColdIron,
             ResourceIds.Hartwood]),
        pack_values([15, 13, 7, 8, 4, 3, 3]),
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
        pack_values([10, 7, 18, 20, 10, 12, 2]),
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
        pack_values([45, 12, 25, 6, 10, 5, 2, 3, 2]),
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
        pack_values([10, 5, 10, 7, 12, 12, 7, 6]),
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
        pack_values([5, 10, 10, 14, 10, 9, 10, 1]),
        0
    )
}


TROOP_COSTS = {
    TroopId.Skirmisher: Cost(
        2,
        8,
        pack_values([ResourceIds.Copper, ResourceIds.Obsidian]),
        pack_values([4, 1]),
    ),
    TroopId.Longbow: Cost(
        1,
        8,
        pack_values([ResourceIds.Adamantine]),
        pack_values([1]),
    ),
    TroopId.Crossbow: Cost(
        4,
        8,
        pack_values([ResourceIds.Stone, ResourceIds.Gold,
                    ResourceIds.Mithral, ResourceIds.Dragonhide]),
        pack_values([20, 2, 1, 1]),
    ),
    TroopId.Pikeman: Cost(
        2,
        8,
        pack_values([ResourceIds.Ironwood, ResourceIds.Diamonds]),
        pack_values([1, 1]),
    ),
    TroopId.Knight: Cost(
        1,
        8,
        pack_values([ResourceIds.Sapphire]),
        pack_values([4]),
    ),
    TroopId.Paladin: Cost(
        6,
        8,
        pack_values([ResourceIds.Coal, ResourceIds.ColdIron, ResourceIds.Diamonds,
                    ResourceIds.Ruby, ResourceIds.DeepCrystal, ResourceIds.AlchemicalSilver]),
        pack_values([10, 6, 2, 4, 4, 1]),
    ),
    TroopId.Ballista: Cost(
        3,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal]),
        pack_values([6, 6, 6]),
    ),
    TroopId.Mangonel: Cost(
        4,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Stone,
                    ResourceIds.Coal, ResourceIds.Silver]),
        pack_values([5, 4, 8, 20]),
    ),
    TroopId.Trebuchet: Cost(
        7,
        8,
        pack_values([ResourceIds.Wood, ResourceIds.Copper, ResourceIds.Obsidian, ResourceIds.Silver,
                    ResourceIds.Ironwood, ResourceIds.Ignium, ResourceIds.EtherealSilica, ResourceIds.Adamantine]),
        pack_values([5, 20, 40, 10, 20, 2, 1]),
    ),
    TroopId.Apprentice: Cost(
        1,
        8,
        pack_values([ResourceIds.Ignium]),
        pack_values([1]),
    ),
    TroopId.Mage: Cost(
        2,
        8,
        pack_values([ResourceIds.ColdIron, ResourceIds.EtherealSilica]),
        pack_values([4, 2]),
    ),
    TroopId.Arcanist: Cost(
        4,
        8,
        pack_values([ResourceIds.Gold, ResourceIds.Hartwood,
                    ResourceIds.TrueIce, ResourceIds.TwilightQuartz]),
        pack_values([10, 15, 3, 2]),
    )
}
