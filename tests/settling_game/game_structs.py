from collections import namedtuple
from enum import IntEnum


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


Cost = namedtuple('Cost', 'resource_count packed_ids packed_amounts')
