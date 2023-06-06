namespace ModuleIds {
    const Adventurer = 1;
    const Loot = 2;
    const Beast = 3;
}

namespace ExternalContractIds {
    const Realms = 1;
    const Lords = 2;
    const Treasury = 3;
}

const MINT_COST = 50000000000000000000;
const FRONT_END_PROVIDER_REWARD = 10000000000000000000;
const FIRST_PLACE_REWARD = 10000000000000000000;
const SECOND_PLACE_REWARD = 3000000000000000000;
const THIRD_PLACE_REWARD = 2000000000000000000;

const STARTING_GOLD = 40;
const MINIMUM_MARKET_FLOOR_PRICE = 3;

const VITALITY_HEALTH_BOOST = 20;
const SUFFIX_STAT_BOOST = 3;
const MAX_CRITICAL_HIT_CHANCE = 5;  // this results in a 1/2 chance of critical hit

const ITEM_RANK_MAX = 6;
const MINIMUM_ATTACK_DAMGE = 3;

// This setting controls the level at which adventurers can start
// taking damages from beasts and obstacles. The level will be two higher than
// this setting. So if this setting is 4, adventurers will be able to start
// taking damage at level 6. Prior to this adventurers will have 100% chance of avoiding
// obstacles, ambushes, and fleeing from beasts.
// The most difficult setting is 0 which would result in adventurers being eligible for damage at Level 2
// Another way to think about this setting is that it's a starting stat boost for
// intelligence, wisdom, and dexterity
const DIFFICULTY_CLIFF = 4;
