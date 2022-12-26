from collections import namedtuple
from enum import IntEnum
from realms_cli.utils import pack_values, uint

from realms_cli.binary_converter import decimal_to_binary

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
        9,
        decimal_to_binary(
            [ResourceIds.Wood,
             ResourceIds.Stone], 9),
        decimal_to_binary([40, 50], 9),
        0
    ),
    BuildingId.StoreHouse: CostWithLords(
        2,
        9,
        decimal_to_binary(
            [ResourceIds.Wood,
             ResourceIds.Stone], 9),
        decimal_to_binary([40, 50], 9),
        0
    ),
    BuildingId.Granary: CostWithLords(
        2,
        9,
        decimal_to_binary(
            [ResourceIds.Wood,
             ResourceIds.Stone], 9),
        decimal_to_binary([40, 50], 9),
        0
    ),
    BuildingId.Farm: CostWithLords(
        10,
        9,
        decimal_to_binary(
            [ResourceIds.Wood,
             ResourceIds.Stone,
             ResourceIds.Coal,
             ResourceIds.Copper,
             ResourceIds.Obsidian,
             ResourceIds.Silver,
             ResourceIds.Ironwood,
             ResourceIds.ColdIron,
             ResourceIds.Gold,
             ResourceIds.Hartwood], 9),
        decimal_to_binary([50, 40, 40, 30, 20, 20, 10, 10, 10, 10], 9),
        0
    ),
    BuildingId.FishingVillage: CostWithLords(
        7,
        9,
        decimal_to_binary(
            [ResourceIds.Wood,
             ResourceIds.Stone,
             ResourceIds.Coal,
             ResourceIds.Copper,
             ResourceIds.Obsidian,
             ResourceIds.Silver,
             ResourceIds.Ironwood,
             ResourceIds.ColdIron,
             ResourceIds.Gold,
             ResourceIds.Hartwood], 9),
        decimal_to_binary([60, 40, 40, 20, 30, 10, 20, 10, 10, 10], 9),
        0
    ),
    BuildingId.Barracks: CostWithLords(
        7,
        9,
        decimal_to_binary(
            [ResourceIds.ColdIron,
             ResourceIds.Gold,
             ResourceIds.Hartwood,
             ResourceIds.Sapphire,
             ResourceIds.DeepCrystal,
             ResourceIds.TrueIce,
             ResourceIds.Dragonhide], 9),
        decimal_to_binary([50, 40, 180, 220, 100, 120, 20], 9),
        0
    ),
    BuildingId.MageTower: CostWithLords(
        9,
        9,
        decimal_to_binary(
            [ResourceIds.Gold,
             ResourceIds.Hartwood,
             ResourceIds.Diamonds,
             ResourceIds.Ignium,
             ResourceIds.EtherealSilica,
             ResourceIds.TrueIce,
             ResourceIds.TwilightQuartz,
             ResourceIds.AlchemicalSilver,
             ResourceIds.Mithral], 9),
        decimal_to_binary([30, 120, 250, 60, 100, 50, 20, 30, 20], 9),
        0
    ),
    BuildingId.ArcherTower: CostWithLords(
        8,
        9,
        decimal_to_binary(
            [ResourceIds.ColdIron,
             ResourceIds.Gold,
             ResourceIds.Hartwood,
             ResourceIds.Sapphire,
             ResourceIds.Ruby,
             ResourceIds.DeepCrystal,
             ResourceIds.AlchemicalSilver,
             ResourceIds.Adamantine], 9),
        decimal_to_binary([50, 20, 100, 70, 120, 120, 70, 60], 9),
        0
    ),
    BuildingId.Castle: CostWithLords(
        8,
        9,
        decimal_to_binary(
            [ResourceIds.Gold,
             ResourceIds.Hartwood,
             ResourceIds.Diamonds,
             ResourceIds.Ruby,
             ResourceIds.Ignium,
             ResourceIds.EtherealSilica,
             ResourceIds.TwilightQuartz,
             ResourceIds.Mithral], 9),
        decimal_to_binary([10, 100, 100, 140, 100, 90, 100, 10], 9),
        0
    )
}


TROOP_COSTS = {
    TroopId.LightCavalry: Cost(
        4,
        9,
        decimal_to_binary([ResourceIds.Wood, ResourceIds.Obsidian,
                           ResourceIds.ColdIron, ResourceIds.Sapphire], 9),
        decimal_to_binary([100, 50, 20, 20], 9),
    ),
    TroopId.HeavyCavalry: Cost(
        4,
        9,
        decimal_to_binary([ResourceIds.Stone, ResourceIds.Silver,
                           ResourceIds.Diamonds, ResourceIds.EtherealSilica], 9),
        decimal_to_binary([60, 100, 50, 10], 9),
    ),
    TroopId.Archer: Cost(
        4,
        9,
        decimal_to_binary([ResourceIds.Wood, ResourceIds.Coal,
                           ResourceIds.Silver, ResourceIds.Sapphire], 9),
        decimal_to_binary([100, 100, 20, 20], 9),
    ),
    TroopId.Longbow: Cost(
        5,
        9,
        decimal_to_binary([ResourceIds.Wood, ResourceIds.Stone,
                           ResourceIds.Obsidian, ResourceIds.Ironwood, ResourceIds.Ruby], 9),
        decimal_to_binary([50, 90, 100, 70, 40], 9),
    ),
    TroopId.Mage: Cost(
        3,
        9,
        decimal_to_binary(
            [ResourceIds.Coal, ResourceIds.ColdIron, ResourceIds.Ignium], 9),
        decimal_to_binary([120, 20, 20], 9),
    ),
    TroopId.Arcanist: Cost(
        4,
        9,
        decimal_to_binary([ResourceIds.Stone, ResourceIds.Copper, ResourceIds.Hartwood,
                           ResourceIds.DeepCrystal], 9),
        decimal_to_binary([100, 70, 50, 40], 9),
    ),
    TroopId.LightInfantry: Cost(
        3,
        9,
        decimal_to_binary(
            [ResourceIds.Copper, ResourceIds.ColdIron, ResourceIds.Ignium], 9),
        decimal_to_binary([100, 20, 20], 9),
    ),
    TroopId.HeavyInfantry: Cost(
        4,
        9,
        decimal_to_binary([ResourceIds.Wood, ResourceIds.Gold,
                           ResourceIds.EtherealSilica, ResourceIds.TrueIce], 9),
        decimal_to_binary([50, 50, 20, 20], 9),
    )
}

LABOR_COST = {
    ResourceIds.Wood: Cost(
        7,
        11,
        decimal_to_binary(
            [ResourceIds.Stone, ResourceIds.Coal, ResourceIds.Copper,
             ResourceIds.Obsidian, ResourceIds.Silver, ResourceIds.Ironwood,
             ResourceIds.ColdIron], 11),
        decimal_to_binary([98,	96,	66,	55,	43,	29,	24], 11),
    ),
    ResourceIds.Stone: Cost(
        7,
        11,
        decimal_to_binary(
            [ResourceIds.Wood, ResourceIds.Coal, ResourceIds.Copper,
             ResourceIds.Obsidian, ResourceIds.Silver, ResourceIds.Ironwood,
             ResourceIds.ColdIron], 11),
        decimal_to_binary([159,		122,	84,	70,	55, 37,	30], 11),
    ),
    ResourceIds.Coal: Cost(
        7,
        11,
        decimal_to_binary(
            [ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Copper,
             ResourceIds.Obsidian, ResourceIds.Silver, ResourceIds.Ironwood,
             ResourceIds.ColdIron], 11),
        decimal_to_binary([164,	129,	86, 72,	57,	38, 31], 11),
    ),
    ResourceIds.Copper: Cost(
        7,
        11,
        decimal_to_binary(
            [ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal,
             ResourceIds.Obsidian, ResourceIds.Silver, ResourceIds.Ironwood,
             ResourceIds.ColdIron], 11),
        decimal_to_binary([237,	186,	181,		105,	82,	56,	45], 11),
    ),
    ResourceIds.Obsidian: Cost(
        7,
        11,
        decimal_to_binary(
            [ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal,
             ResourceIds.Copper, ResourceIds.Silver, ResourceIds.Ironwood,
             ResourceIds.ColdIron], 11),
        decimal_to_binary([283,	222,	216,	149,	98,	67,	54], 11),
    ),
    ResourceIds.Silver: Cost(
        7,
        11,
        decimal_to_binary(
            [ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal,
             ResourceIds.Copper, ResourceIds.Obsidian, ResourceIds.Ironwood,
             ResourceIds.ColdIron], 11),
        decimal_to_binary([360,	283,	275,	190,	159,	85,	69], 11),
    ),
    ResourceIds.Ironwood: Cost(
        7,
        11,
        decimal_to_binary(
            [ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal,
             ResourceIds.Copper, ResourceIds.Obsidian, ResourceIds.Silver,
             ResourceIds.ColdIron], 11),
        decimal_to_binary([532,	418,	406,	280, 235,	185,		101], 11),
    ),
    ResourceIds.ColdIron: Cost(
        7,
        11,
        decimal_to_binary(
            [ResourceIds.Wood, ResourceIds.Stone, ResourceIds.Coal,
             ResourceIds.Copper, ResourceIds.Obsidian, ResourceIds.Silver,
             ResourceIds.Ironwood], 11),
        decimal_to_binary([655,	515,	501,	345, 289,	227,	154], 11),
    ),
    ResourceIds.Gold: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.Hartwood, ResourceIds.Diamonds, ResourceIds.Sapphire,
             ResourceIds.Ruby, ResourceIds.DeepCrystal, ResourceIds.Ignium], 11),
        decimal_to_binary([95,	48,	39,	38,	38,	27], 11),
    ),
    ResourceIds.Hartwood: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.Gold, ResourceIds.Diamonds, ResourceIds.Sapphire,
             ResourceIds.Ruby, ResourceIds.DeepCrystal, ResourceIds.Ignium], 11),
        decimal_to_binary([224,		74,	61,	59,	59,	42], 11),
    ),
    ResourceIds.Diamonds: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.Gold, ResourceIds.Hartwood, ResourceIds.Sapphire,
             ResourceIds.Ruby, ResourceIds.DeepCrystal, ResourceIds.Ignium], 11),
        decimal_to_binary([444,	289,		120,	116,	116,	84], 11),
    ),
    ResourceIds.Sapphire: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.Gold, ResourceIds.Hartwood, ResourceIds.Diamonds,
             ResourceIds.Ruby, ResourceIds.DeepCrystal, ResourceIds.Ignium], 11),
        decimal_to_binary([540,	351,	177,		141,	141,	102], 11),
    ),
    ResourceIds.Ruby: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.Gold, ResourceIds.Hartwood, ResourceIds.Diamonds,
             ResourceIds.Sapphire, ResourceIds.DeepCrystal, ResourceIds.Ignium], 11),
        decimal_to_binary([558,	362,	183,	151,		146,	105], 11),
    ),
    ResourceIds.DeepCrystal: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.Gold, ResourceIds.Hartwood, ResourceIds.Diamonds,
             ResourceIds.Sapphire, ResourceIds.Ruby, ResourceIds.Ignium], 11),
        decimal_to_binary([558,	362,	183,	151,	146,	105], 11),
    ),
    ResourceIds.Ignium: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.Gold, ResourceIds.Hartwood, ResourceIds.Diamonds,
             ResourceIds.Sapphire, ResourceIds.Ruby, ResourceIds.DeepCrystal], 11),
        decimal_to_binary([775,	504,	254,	209,	203,	203], 11),
    ),
    # tier 1
    ResourceIds.EtherealSilica: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.TrueIce, ResourceIds.TwilightQuartz, ResourceIds.AlchemicalSilver,
             ResourceIds.Adamantine, ResourceIds.Mithral, ResourceIds.Dragonhide], 11),
        decimal_to_binary([12,	100,	84,	50,	33,	21], 11),
    ),
    ResourceIds.TrueIce: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.EtherealSilica, ResourceIds.TwilightQuartz, ResourceIds.AlchemicalSilver,
             ResourceIds.Adamantine, ResourceIds.Mithral, ResourceIds.Dragonhide], 11),
        decimal_to_binary([170,		116,	98,	58,	39,	24], 11),
    ),
    ResourceIds.TwilightQuartz: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.EtherealSilica, ResourceIds.TrueIce, ResourceIds.AlchemicalSilver,
             ResourceIds.Adamantine, ResourceIds.Mithral, ResourceIds.Dragonhide], 11),
        decimal_to_binary([213,	183,		122,	72,	49,	30], 11),
    ),
    ResourceIds.AlchemicalSilver: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.EtherealSilica, ResourceIds.TrueIce, ResourceIds.TwilightQuartz,
             ResourceIds.Adamantine, ResourceIds.Mithral, ResourceIds.Dragonhide], 11),
        decimal_to_binary([254,	218, 174,		86,	58,	36], 11),
    ),
    ResourceIds.Adamantine: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.EtherealSilica, ResourceIds.TrueIce, ResourceIds.AlchemicalSilver,
             ResourceIds.AlchemicalSilver, ResourceIds.Mithral, ResourceIds.Dragonhide], 11),
        decimal_to_binary([430,	369,	294,	247, 98,	61], 11),
    ),
    ResourceIds.Mithral: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.EtherealSilica, ResourceIds.TrueIce, ResourceIds.AlchemicalSilver,
             ResourceIds.AlchemicalSilver, ResourceIds.Adamantine, ResourceIds.Dragonhide], 11),
        decimal_to_binary([639,	548,	437,	367,	217,		91], 11),
    ),
    ResourceIds.Dragonhide: Cost(
        6,
        11,
        decimal_to_binary(
            [ResourceIds.EtherealSilica, ResourceIds.TrueIce, ResourceIds.AlchemicalSilver,
             ResourceIds.AlchemicalSilver, ResourceIds.Adamantine, ResourceIds.Mithral], 11),
        decimal_to_binary([1027,	881,	704,	590,	349,	235], 11),
    )
}
