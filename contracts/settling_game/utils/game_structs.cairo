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
    const L07_Crypts = 10
end

namespace ExternalContractIds:
    const Lords = 1
    const Realms = 2
    const S_Realms = 3
    const Resources = 4
    const Treasury = 5
    const Storage = 6
end
