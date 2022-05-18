# Game Structs
#   A struct that holds the Realm statistics.
#   Each module will need to add a struct with their metadata.
#
# MIT License

%lang starknet

namespace TraitsIds:
    const Region = 1
    const City = 2
    const Harbour = 3
    const River = 4
end

struct RealmData:
    member regions : felt  #
    member cities : felt  #
    member harbours : felt  #
    member rivers : felt  #
    member resource_number : felt  #
    member resource_1 : felt  #
    member resource_2 : felt  #
    member resource_3 : felt  #
    member resource_4 : felt  #
    member resource_5 : felt  #
    member resource_6 : felt  #
    member resource_7 : felt  #
    member wonder : felt  #
    member order : felt  #
end

struct RealmBuildings:
    member Fairgrounds : felt
    member RoyalReserve : felt
    member GrandMarket : felt
    member Castle : felt
    member Guild : felt
    member OfficerAcademy : felt
    member Granary : felt
    member Housing : felt
    member Amphitheater : felt
    member ArcherTower : felt
    member School : felt
    member MageTower : felt
    member TradeOffice : felt
    member Architect : felt
    member ParadeGrounds : felt
    member Barracks : felt
    member Dock : felt
    member Fishmonger : felt
    member Farms : felt
    member Hamlet : felt
end

namespace RealmBuildingsIds:
    const Fairgrounds = 1
    const RoyalReserve = 2
    const GrandMarket = 3
    const Castle = 4
    const Guild = 5
    const OfficerAcademy = 6
    const Granary = 7
    const Housing = 8
    const Amphitheater = 9
    const ArcherTower = 10
    const School = 11
    const MageTower = 12
    const TradeOffice = 13
    const Architect = 14
    const ParadeGrounds = 15
    const Barracks = 16
    const Dock = 17
    const Fishmonger = 18
    const Farms = 19
    const Hamlet = 20
end

namespace RealmBuildingLimitTraitsIds:
    const Fairgrounds = TraitsIds.Region
    const RoyalReserve = TraitsIds.Region
    const GrandMarket = TraitsIds.Region
    const Castle = TraitsIds.Region
    const Guild = TraitsIds.Region
    const OfficerAcademy = TraitsIds.Region
    const Granary = TraitsIds.City
    const Housing = TraitsIds.City
    const Amphitheater = TraitsIds.City
    const ArcherTower = TraitsIds.City
    const School = TraitsIds.City
    const MageTower = TraitsIds.City
    const TradeOffice = TraitsIds.City
    const Architect = TraitsIds.City
    const ParadeGrounds = TraitsIds.City
    const Barracks = TraitsIds.City
    const Dock = TraitsIds.Harbour
    const Fishmonger = TraitsIds.Harbour
    const Farms = TraitsIds.River
    const Hamlet = TraitsIds.River
end

namespace BuildingsFood:
    const Fairgrounds = 5
    const RoyalReserve = 5
    const GrandMarket = 5
    const Castle = -1
    const Guild = -1
    const OfficerAcademy = -1
    const Granary = 3
    const Housing = -1
    const Amphitheater = -1
    const ArcherTower = -1
    const School = -1
    const MageTower = -1
    const TradeOffice = -1
    const Architect = -1
    const ParadeGrounds = -1
    const Barracks = -1
    const Dock = -1
    const Fishmonger = 2
    const Farms = 1
    const Hamlet = 1
end

namespace BuildingsCulture:
    const Fairgrounds = 5
    const RoyalReserve = 5
    const GrandMarket = 0
    const Castle = 5
    const Guild = 5
    const OfficerAcademy = 0
    const Granary = 0
    const Housing = 0
    const Amphitheater = 2
    const ArcherTower = 0
    const School = 3
    const MageTower = 0
    const TradeOffice = 1
    const Architect = 1
    const ParadeGrounds = 1
    const Barracks = 0
    const Dock = 0
    const Fishmonger = 0
    const Farms = 0
    const Hamlet = 0
end

namespace BuildingsPopulation:
    const Fairgrounds = -10
    const RoyalReserve = -10
    const GrandMarket = -10
    const Castle = -10
    const Guild = -10
    const OfficerAcademy = -10
    const Granary = -10
    const Housing = 75
    const Amphitheater = -10
    const ArcherTower = -10
    const School = -10
    const MageTower = -10
    const TradeOffice = -10
    const Architect = -10
    const ParadeGrounds = -10
    const Barracks = -10
    const Dock = -10
    const Fishmonger = -10
    const Farms = 10
    const Hamlet = 35
end

namespace ArmyCap:
    const Fairgrounds = 0
    const RoyalReserve = 5
    const GrandMarket = 0
    const Castle = 5
    const Guild = 5
    const OfficerAcademy = 5
    const Granary = 0
    const Housing = 0
    const Amphitheater = 2
    const ArcherTower = 0
    const School = 3
    const MageTower = 0
    const TradeOffice = 0
    const Architect = 1
    const ParadeGrounds = 2
    const Barracks = 1
    const Dock = 0
    const Fishmonger = 0
    const Farms = 0
    const Hamlet = 0
end

namespace ModuleIds:
    const L01_Settling = 1
    # const S01_Settling = 2
    const L02_Resources = 2
    # const S02_Resources = 4
    const L03_Buildings = 3
    # const S03_Buildings = 6
    const L04_Calculator = 4
    const L05_Wonders = 5
    # const S05_Wonders = 9
    const L06_Combat = 6
    # const S06_Combat = 12
end

namespace ExternalContractIds:
    const Lords = 1
    const Realms = 2
    const S_Realms = 3
    const Resources = 4
    const Treasury = 5
    const Storage = 6
end

namespace ResourceIds:
    const Wood = 1
    const Stone = 2
    const Coal = 3
    const Copper = 4
    const Obsidian = 5
    const Silver = 6
    const Ironwood = 7
    const ColdIron = 8
    const Gold = 9
    const Hartwood = 10
    const Diamonds = 11
    const Sapphire = 12
    const Ruby = 13
    const DeepCrystal = 14
    const Ignium = 15
    const EtherealSilica = 16
    const TrueIce = 17
    const TwilightQuartz = 18
    const AlchemicalSilver = 19
    const Adamantine = 20
    const Mithral = 21
    const Dragonhide = 22
    # IMPORTANT: if you're adding to this enum
    # make sure the SIZE is one greater than the
    # maximal value; certain algorithms depend on that
    const SIZE = 23
end

namespace TroopId:
    const Watchman = 1
    const Guard = 2
    const GuardCaptain = 3
    const Squire = 4
    const Knight = 5
    const KnightCommander = 6
    const Scout = 7
    const Archer = 8
    const Sniper = 9
    const Scorpio = 10
    const Ballista = 11
    const Catapult = 12
    const Apprentice = 13
    const Mage = 14
    const Arcanist = 15
    const GrandMarshal = 16
end

namespace TroopType:
    const Melee = 1
    const Ranged = 2
    const Siege = 3
end

struct Troop:
    member type : felt  # TroopType
    member tier : felt
    member agility : felt
    member attack : felt
    member defense : felt
    member vitality : felt
    member wisdom : felt
end

# TODO: add a t4 Troop that's a Character from our Character module;
#       it should be optional
struct Squad:
    # tier 1 troops
    member t1_1 : Troop
    member t1_2 : Troop
    member t1_3 : Troop
    member t1_4 : Troop
    member t1_5 : Troop
    member t1_6 : Troop
    member t1_7 : Troop
    member t1_8 : Troop
    member t1_9 : Troop
    member t1_10 : Troop
    member t1_11 : Troop
    member t1_12 : Troop
    member t1_13 : Troop
    member t1_14 : Troop
    member t1_15 : Troop
    member t1_16 : Troop

    # tier 2 troops
    member t2_1 : Troop
    member t2_2 : Troop
    member t2_3 : Troop
    member t2_4 : Troop
    member t2_5 : Troop
    member t2_6 : Troop
    member t2_7 : Troop
    member t2_8 : Troop

    # tier 3 troop
    member t3_1 : Troop
end

struct PackedSquad:
    # one packed troop fits into 7 bytes
    # one felt is ~31 bytes -> can hold 4 troops
    # a squad has 25 troops -> fits into 7 felts when packed
    member p1 : felt  # packed Troops t1_1 ... t1_4
    member p2 : felt  # packed Troops t1_5 ... t1_8
    member p3 : felt  # packed Troops t1_9 ... t1_12
    member p4 : felt  # packed Troops t1_13 ... t1_16
    member p5 : felt  # packed Troops t2_1 ... t2_4
    member p6 : felt  # packed Troops t2_5 ... t2_8
    member p7 : felt  # packed Troop t3_1
end

struct SquadStats:
    member agility : felt
    member attack : felt
    member defense : felt
    member vitality : felt
    member wisdom : felt
end

# this struct holds everything related to a Realm & combat
# a Realm can have two squads, one used for attacking
# and another used for defending; this struct holds them
struct RealmCombatData:
    member attacking_squad : PackedSquad
    member defending_squad : PackedSquad
    member last_attacked_at : felt
end

# struct holding how much resources does it cost to build/buy a thing
struct Cost:
    # the count of unique ResourceIds necessary
    member resource_count : felt
    # how many bits are the packed members packed into
    member bits : felt
    # packed IDs of the necessary resources
    member packed_ids : felt
    # packed amounts of each resource
    member packed_amounts : felt
end

struct ResourceOutput:
    member resource_1 : felt
    member resource_2 : felt
    member resource_3 : felt
    member resource_4 : felt
    member resource_5 : felt
    member resource_6 : felt
    member resource_7 : felt
end    