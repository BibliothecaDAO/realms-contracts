// Game Structs
//   A struct that holds the Realm statistics.
//   Each module will need to add a struct with their metadata.
//
// MIT License
%lang starknet
from starkware.cairo.common.uint256 import Uint256

struct RealmData {
    regions: felt,
    cities: felt,
    harbours: felt,
    rivers: felt,
    resource_number: felt,
    resource_1: felt,
    resource_2: felt,
    resource_3: felt,
    resource_4: felt,
    resource_5: felt,
    resource_6: felt,
    resource_7: felt,
    wonder: felt,
    order: felt,
}

struct RealmBuildings {
    House: felt,
    StoreHouse: felt,
    Granary: felt,
    Farm: felt,
    FishingVillage: felt,
    Barracks: felt,
    MageTower: felt,
    ArcherTower: felt,
    Castle: felt,
}

namespace RealmBuildingsIds {
    const House = 1;
    const StoreHouse = 2;
    const Granary = 3;
    const Farm = 4;
    const FishingVillage = 5;
    const Barracks = 6;
    const MageTower = 7;
    const ArcherTower = 8;
    const Castle = 9;
}

// square meters
namespace RealmBuildingsSize {
    const House = 4;
    const StoreHouse = 2;
    const Granary = 3;
    const Farm = 3;
    const FishingVillage = 3;
    const Barracks = 16;
    const MageTower = 16;
    const ArcherTower = 16;
    const Castle = 16;
}

namespace BuildingsFood {
    const House = 2;
    const StoreHouse = 3;
    const Granary = 3;
    const Farm = 3;
    const FishingVillage = 3;
    const Barracks = 6;
    const MageTower = 6;
    const ArcherTower = 6;
    const Castle = 12;
}

namespace BuildingsCulture {
    const House = 2;
    const StoreHouse = 3;
    const Granary = 3;
    const Farm = 3;
    const FishingVillage = 3;
    const Barracks = 6;
    const MageTower = 6;
    const ArcherTower = 6;
    const Castle = 12;
}

namespace BuildingsPopulation {
    const House = 12;
    const StoreHouse = 3;
    const Granary = 3;
    const Farm = 3;
    const FishingVillage = 3;
    const Barracks = 5;
    const MageTower = 5;
    const ArcherTower = 5;
    const Castle = 5;
}

namespace BuildingsIntegrityLength {
    const House = 3600;
    const StoreHouse = 2000;
    const Granary = 2000;
    const Farm = 2000;
    const FishingVillage = 2000;
    const Barracks = 37319;
    const MageTower = 37319;
    const ArcherTower = 37319;
    const Castle = 37319;
}

namespace BuildingsTroopIndustry {
    const House = 0;
    const StoreHouse = 0;
    const Granary = 0;
    const Farm = 0;
    const FishingVillage = 0;
    const Barracks = 2;
    const MageTower = 2;
    const ArcherTower = 2;
    const Castle = 4;
}

namespace BuildingsDecaySlope {
    const House = 400;
    const StoreHouse = 400;
    const Granary = 400;
    const Farm = 400;
    const FishingVillage = 400;
    const Barracks = 400;
    const MageTower = 400;
    const ArcherTower = 400;
    const Castle = 200;
}

namespace ArmyCap {
    const House = 2;
    const StoreHouse = 3;
    const Granary = 3;
    const Farm = 3;
    const FishingVillage = 3;
    const Barracks = 6;
    const MageTower = 6;
    const ArcherTower = 6;
    const Castle = 12;
}

namespace ModuleIds {
    const Settling = 1;
    const Resources = 2;
    const Buildings = 3;
    const Calculator = 4;
    const L06_Combat = 6;
    const L07_Crypts = 7;
    const L08_Crypts_Resources = 8;
    const Relics = 12;
    const L10_Food = 13;
    const GoblinTown = 14;
    const Travel = 15;
    const Crypts_Token = 1001;
    const Lords_Token = 1002;
    const Realms_Token = 1003;
    const Resources_Token = 1004;
    const S_Crypts_Token = 1005;
    const S_Realms_Token = 1006;
}

namespace ExternalContractIds {
    const Lords = 1;
    const Realms = 2;
    const S_Realms = 3;
    const Resources = 4;
    const Treasury = 5;
    const Storage = 6;
    const Crypts = 7;
    const S_Crypts = 8;
    const Loot = 9;
    const Adventurer = 10;
}

struct CryptData {
    resource: felt,  // uint256 - resource generated by this dungeon (23-28)
    environment: felt,  // uint256 - environment of the dungeon (1-6)
    legendary: felt,  // uint256 - flag if dungeon is legendary (0/1)
    size: felt,  // uint256 - size (e.g. 6x6) of dungeon. (6-25)
    num_doors: felt,  // uint256 - number of doors (0-12)
    num_points: felt,  // uint256 - number of points (0-12)
    affinity: felt,  // uint256 - affinity of the dungeon (0, 1-58)
    // member name : felt  # string - name of the dungeon
}

// struct holding the different environments for Crypts and Caverns dungeons
// we'll use this to determine how many resources to grant during staking
namespace EnvironmentIds {
    const DesertOasis = 1;
    const StoneTemple = 2;
    const ForestRuins = 3;
    const MountainDeep = 4;
    const UnderwaterKeep = 5;
    const EmbersGlow = 6;
}

namespace EnvironmentProduction {
    const DesertOasis = 170;
    const StoneTemple = 90;
    const ForestRuins = 80;
    const MountainDeep = 60;
    const UnderwaterKeep = 25;
    const EmbersGlow = 10;
}

namespace ResourceIds {
    // Realms Resources
    const Wood = 1;
    const Stone = 2;
    const Coal = 3;
    const Copper = 4;
    const Obsidian = 5;
    const Silver = 6;
    const Ironwood = 7;
    const ColdIron = 8;
    const Gold = 9;
    const Hartwood = 10;
    const Diamonds = 11;
    const Sapphire = 12;
    const Ruby = 13;
    const DeepCrystal = 14;
    const Ignium = 15;
    const EtherealSilica = 16;
    const TrueIce = 17;
    const TwilightQuartz = 18;
    const AlchemicalSilver = 19;
    const Adamantine = 20;
    const Mithral = 21;
    const Dragonhide = 22;
    // Crypts and Caverns Resources
    const DesertGlass = 23;
    const DivineCloth = 24;
    const CuriousSpore = 25;
    const UnrefinedOre = 26;
    const SunkenShekel = 27;
    const Demonhide = 28;
    // IMPORTANT: if you're adding to this enum
    // make sure the SIZE is one greater than the
    // maximal value; certain algorithms depend on that
    const wheat = 10000;
    const fish = 10001;
    const SIZE = 31;
}

namespace TroopId {
    const Skirmisher = 1;
    const Longbow = 2;
    const Crossbow = 3;
    const Pikeman = 4;
    const Knight = 5;
    const Paladin = 6;
    const Ballista = 7;
    const Mangonel = 8;
    const Trebuchet = 9;
    const Apprentice = 10;
    const Mage = 11;
    const Arcanist = 12;
    const Goblin = 13;
    // IMPORTANT: if you're adding to this enum
    // make sure the SIZE is one greater than the
    // maximal value; certain algorithms depend on that
    const SIZE = 14;
}

namespace TroopType {
    const RangedNormal = 1;
    const RangedMagic = 2;
    const Melee = 3;
    const Siege = 4;
}

struct Troop {
    id: felt,  // TroopId
    type: felt,  // TroopType
    tier: felt,
    building: felt,  // RealmBuildingsIds, the troop's production building
    agility: felt,
    attack: felt,
    armor: felt,
    vitality: felt,
    wisdom: felt,
}

namespace TroopProps {
    namespace Type {
        const Skirmisher = TroopType.RangedNormal;
        const Longbow = TroopType.RangedNormal;
        const Crossbow = TroopType.RangedNormal;
        const Pikeman = TroopType.Melee;
        const Knight = TroopType.Melee;
        const Paladin = TroopType.Melee;
        const Ballista = TroopType.Siege;
        const Mangonel = TroopType.Siege;
        const Trebuchet = TroopType.Siege;
        const Apprentice = TroopType.RangedMagic;
        const Mage = TroopType.RangedMagic;
        const Arcanist = TroopType.RangedMagic;
        const Goblin = TroopType.Melee;
    }

    namespace Tier {
        const Skirmisher = 1;
        const Longbow = 2;
        const Crossbow = 3;
        const Pikeman = 1;
        const Knight = 2;
        const Paladin = 3;
        const Ballista = 1;
        const Mangonel = 2;
        const Trebuchet = 3;
        const Apprentice = 1;
        const Mage = 2;
        const Arcanist = 3;
        const Goblin = 1;
    }

    namespace Building {
        const Skirmisher = RealmBuildingsIds.ArcherTower;
        const Longbow = RealmBuildingsIds.ArcherTower;
        const Crossbow = RealmBuildingsIds.ArcherTower;
        const Pikeman = RealmBuildingsIds.Barracks;
        const Knight = RealmBuildingsIds.Barracks;
        const Paladin = RealmBuildingsIds.Barracks;
        const Ballista = RealmBuildingsIds.Castle;
        const Mangonel = RealmBuildingsIds.Castle;
        const Trebuchet = RealmBuildingsIds.Castle;
        const Apprentice = RealmBuildingsIds.MageTower;
        const Mage = RealmBuildingsIds.MageTower;
        const Arcanist = RealmBuildingsIds.MageTower;
        const Goblin = 0;
    }

    namespace Agility {
        const Skirmisher = 8;
        const Longbow = 10;
        const Crossbow = 12;
        const Pikeman = 2;
        const Knight = 3;
        const Paladin = 4;
        const Ballista = 5;
        const Mangonel = 3;
        const Trebuchet = 4;
        const Apprentice = 6;
        const Mage = 8;
        const Arcanist = 10;
        const Goblin = 3;
    }

    namespace Attack {
        const Skirmisher = 6;
        const Longbow = 8;
        const Crossbow = 10;
        const Pikeman = 6;
        const Knight = 8;
        const Paladin = 10;
        const Ballista = 8;
        const Mangonel = 10;
        const Trebuchet = 12;
        const Apprentice = 6;
        const Mage = 8;
        const Arcanist = 10;
        const Goblin = 8;
    }

    namespace Armor {
        const Skirmisher = 2;
        const Longbow = 3;
        const Crossbow = 4;
        const Pikeman = 4;
        const Knight = 6;
        const Paladin = 8;
        const Ballista = 2;
        const Mangonel = 3;
        const Trebuchet = 4;
        const Apprentice = 2;
        const Mage = 3;
        const Arcanist = 4;
        const Goblin = 2;
    }

    namespace Vitality {
        const Skirmisher = 30;
        const Longbow = 40;
        const Crossbow = 60;
        const Pikeman = 30;
        const Knight = 60;
        const Paladin = 80;
        const Ballista = 30;
        const Mangonel = 50;
        const Trebuchet = 70;
        const Apprentice = 40;
        const Mage = 50;
        const Arcanist = 80;
        const Goblin = 20;
    }

    namespace Wisdom {
        const Skirmisher = 3;
        const Longbow = 4;
        const Crossbow = 4;
        const Pikeman = 4;
        const Knight = 6;
        const Paladin = 8;
        const Ballista = 2;
        const Mangonel = 3;
        const Trebuchet = 4;
        const Apprentice = 6;
        const Mage = 8;
        const Arcanist = 10;
        const Goblin = 1;
    }
}

// one packed troop fits into 2 bytes (troop ID + vitality)
// one felt is ~31 bytes -> can hold 15 troops
// ==> the whole Squad can be packed into a single felt
struct Squad {
    // tier 1 troops
    t1_1: Troop,
    t1_2: Troop,
    t1_3: Troop,
    t1_4: Troop,
    t1_5: Troop,
    t1_6: Troop,
    t1_7: Troop,
    t1_8: Troop,
    t1_9: Troop,

    // tier 2 troops
    t2_1: Troop,
    t2_2: Troop,
    t2_3: Troop,
    t2_4: Troop,
    t2_5: Troop,

    // tier 3 troop
    t3_1: Troop,
}

struct SquadStats {
    agility: felt,
    attack: felt,
    armor: felt,
    vitality: felt,
    wisdom: felt,
}

// this struct holds everything related to a Realm & combat
// a Realm can have two squads, one used for attacking
// and another used for defending; this struct holds them
struct RealmCombatData {
    attacking_squad: felt,  // packed Squad
    defending_squad: felt,  // packed Squad
    last_attacked_at: felt,
}

// struct holding how much resources does it cost to build/buy a thing
struct Cost {
    // the count of unique ResourceIds necessary
    resource_count: felt,
    // how many bits are the packed members packed into
    bits: felt,
    // packed IDs of the necessary resources
    packed_ids: felt,
    // packed amounts of each resource
    packed_amounts: felt,
}

struct ResourceOutput {
    resource_1: felt,
    resource_2: felt,
    resource_3: felt,
    resource_4: felt,
    resource_5: felt,
    resource_6: felt,
    resource_7: felt,
}

// Packed Military Buildings
struct PackedBuildings {
    military: felt,
    economic: felt,
    housing: felt,
}

// Farm Harvest Types
namespace HarvestType {
    const Export = 1;
    const Store = 2;
}

struct FoodBuildings {
    number_built: felt,
    collections_left: felt,
    update_time: felt,
}

struct Point {
    x: felt,
    y: felt,
}

struct TravelInformation {
    destination_asset_id: felt,
    destination_token_id: Uint256,  // id of destination
    destination_nested_asset_id: felt,
    travel_time: felt,  // timestamp in the future
}

struct Battalion {
    quantity: felt,  // 1-23
    health: felt,  // 1-100
}

struct Army {
    light_cavalry: Battalion,
    heavy_cavalry: Battalion,
    archer: Battalion,
    longbow: Battalion,
    mage: Battalion,
    arcanist: Battalion,
    light_infantry: Battalion,
    heavy_infantry: Battalion,
}

struct ArmyStatistics {
    cavalry_attack: felt,  // (Light Cav Base Attack*Number of Attacking Light Cav Battalions)+(Heavy Cav Base Attack*Number of Attacking Heavy Cav Battalions)
    archery_attack: felt,  // (Archer Base Attack*Number of Attacking Archer Battalions)+(Longbow Base Attack*Number of Attacking Longbow Battalions)
    magic_attack: felt,  // (Mage Base Attack*Number of Attacking Mage Battalions)+(Arcanist Base Attack*Number of Attacking Arcanist Battalions)
    infantry_attack: felt,  // (Light Inf Base Attack*Number of Attacking Light Inf Battalions)+(Heavy Inf Base Attack*Number of Attacking Heavy Inf Battalions)

    cavalry_defence: felt,  // (Sum of all units Cavalry Defence*Percentage of Attacking Cav Battalions)
    archery_defence: felt,  // (Sum of all units Archery Defence*Percentage of Attacking Archery Battalions)
    magic_defence: felt,  // (Sum of all units Magic Cav Defence*Percentage of Attacking Magic Battalions)
    infantry_defence: felt,  // (Sum of all units Infantry Defence*Percentage of Attacking Infantry Battalions)
}

struct ArmyData {
    packed: felt,
    last_attacked: felt,
    XP: felt,
    level: felt,
    call_sign: felt,
}
