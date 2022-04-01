%lang starknet

# A struct that holds the Realm statistics.

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

struct ResourceUpgradeValues:
    member resource_1 : felt
    member resource_2 : felt
    member resource_3 : felt
    member resource_4 : felt
    member resource_5 : felt
    member resource_1_values : felt
    member resource_2_values : felt
    member resource_3_values : felt
    member resource_4_values : felt
    member resource_5_values : felt
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
    member Carpenter : felt
    member School : felt
    member Symposium : felt
    member LogisticsOffice : felt
    member ExplorersGuild : felt
    member ParadeGrounds : felt
    member ResourceFacility : felt
    member Dock : felt
    member Fishmonger : felt
    member Farms : felt
    member Hamlet : felt
end

struct RealmBuildingCostIds:
    member resource_1 : felt
    member resource_2 : felt
    member resource_3 : felt
    member resource_4 : felt
    member resource_5 : felt
    member resource_6 : felt
    member resource_7 : felt
    member resource_8 : felt
    member resource_9 : felt
    member resource_10 : felt
end

struct RealmBuildingCostValues:
    member resource_1_values : felt
    member resource_2_values : felt
    member resource_3_values : felt
    member resource_4_values : felt
    member resource_5_values : felt
    member resource_6_values : felt
    member resource_7_values : felt
    member resource_8_values : felt
    member resource_9_values : felt
    member resource_10_values : felt
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
    const Carpenter = 10
    const School = 11
    const Symposium = 12
    const LogisticsOffice = 13
    const ExplorersGuild = 14
    const ParadeGrounds = 15
    const ResourceFacility = 16
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
    const Carpenter = TraitsIds.City
    const School = TraitsIds.City
    const Symposium = TraitsIds.City
    const LogisticsOffice = TraitsIds.City
    const ExplorersGuild = TraitsIds.City
    const ParadeGrounds = TraitsIds.City
    const ResourceFacility = TraitsIds.City
    const Dock = TraitsIds.Harbour
    const Fishmonger = TraitsIds.Harbour
    const Farms = TraitsIds.River
    const Hamlet = TraitsIds.River
end

namespace ModuleIds:
    const L01_Settling = 1
    const S01_Settling = 2
    const L02_Resources = 3
    const S02_Resources = 4
    const L03_Buildings = 5
    const S03_Buildings = 6
    const L04_Calculator = 7
    const L05_Wonders = 8
    const S05_Wonders = 9
    const L06_Combat = 11
    const S06_Combat = 12
end

namespace ExternalContractIds:
    const Lords = 1
    const Realms = 2
    const S_Realms = 3
    const Resources = 4
    const Treasury = 5
    const Storage = 6
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
