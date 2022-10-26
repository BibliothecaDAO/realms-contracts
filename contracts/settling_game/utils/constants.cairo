// Constants utility contract
//   A set of constants that are used throughout the project
//   and/or not provided by cairo (e.g. TRUE / FALSE)
//
// MIT License

%lang starknet

// BIT SHIFTS
const SHIFT_8_1 = 2 ** 0;
const SHIFT_8_2 = 2 ** 8;
const SHIFT_8_3 = 2 ** 16;
const SHIFT_8_4 = 2 ** 24;
const SHIFT_8_5 = 2 ** 32;
const SHIFT_8_6 = 2 ** 40;
const SHIFT_8_7 = 2 ** 48;
const SHIFT_8_8 = 2 ** 56;
const SHIFT_8_9 = 2 ** 64;
const SHIFT_8_10 = 2 ** 72;
const SHIFT_8_11 = 2 ** 80;
const SHIFT_8_12 = 2 ** 88;
const SHIFT_8_13 = 2 ** 96;
const SHIFT_8_14 = 2 ** 104;
const SHIFT_8_15 = 2 ** 112;
const SHIFT_8_16 = 2 ** 120;
const SHIFT_8_17 = 2 ** 128;
const SHIFT_8_18 = 2 ** 136;
const SHIFT_8_19 = 2 ** 144;
const SHIFT_8_20 = 2 ** 152;

const SHIFT_6_1 = 2 ** 0;
const SHIFT_6_2 = 2 ** 6;
const SHIFT_6_3 = 2 ** 12;
const SHIFT_6_4 = 2 ** 18;
const SHIFT_6_5 = 2 ** 24;
const SHIFT_6_6 = 2 ** 30;
const SHIFT_6_7 = 2 ** 36;
const SHIFT_6_8 = 2 ** 42;
const SHIFT_6_9 = 2 ** 48;
const SHIFT_6_10 = 2 ** 54;
const SHIFT_6_11 = 2 ** 60;
const SHIFT_6_12 = 2 ** 66;
const SHIFT_6_13 = 2 ** 72;
const SHIFT_6_14 = 2 ** 78;
const SHIFT_6_15 = 2 ** 84;
const SHIFT_6_16 = 2 ** 90;
const SHIFT_6_17 = 2 ** 96;
const SHIFT_6_18 = 2 ** 102;
const SHIFT_6_19 = 2 ** 108;
const SHIFT_6_20 = 2 ** 114;

const SHIFT_NFT_1 = 2 ** 0;
const SHIFT_NFT_2 = 2 ** 7;
const SHIFT_NFT_3 = 2 ** 27;
const SHIFT_NFT_4 = 2 ** 52;
const SHIFT_NFT_5 = 2 ** 54;

namespace SHIFT_41 {
    const _1 = 2 ** 0;
    const _2 = 2 ** 41;
    const _3 = 2 ** 82;
    const _4 = 2 ** 123;
    const _5 = 2 ** 164;
}

// -----------------------------------
// Resources + vault
// -----------------------------------
const MAX_DAYS_ACCURED = 3;  // max amount of days that can accure without claiming
const BASE_RESOURCES_PER_DAY = 250;  // base resource production per day cycle
const WONDER_RATE = BASE_RESOURCES_PER_DAY / 10;  // resources generated by wonders set at 10% of regular realm

const VAULT_LENGTH = 7;  // length of day cycles
const DAY = 86400;  // day cycle length in secondary
const VAULT_LENGTH_SECONDS = VAULT_LENGTH * DAY;  // vault is always 7 * day cycle

const BASE_LORDS_PER_DAY = 25;  // base lords generated by goblins

const WORK_HUT_COST_IN_BP = 5;  // 1/5 of resource output
const WORK_HUT_COST = 75;  // 1/5 of resource output
const WORK_HUT_OUTPUT = 50;

// -----------------------------------
// Buildings
// -----------------------------------
const BASE_SQM = 100;  // base sqm of base
const STORE_HOUSE_SIZE = 10000;  // divisor to get sq of storehouse food

// -----------------------------------
// Food
// -----------------------------------
const BASE_HARVESTS = 24;
const MAX_HARVESTS = BASE_HARVESTS / 4;  // 4 full crops per farm to harvest per cycle
const HARVEST_LENGTH = DAY / 10;

const FARM_LENGTH = (DAY / 3) * BASE_HARVESTS;
const FISHING_TRAPS = (DAY / 3) * BASE_HARVESTS;
const BASE_FOOD_PRODUCTION = 14000;  // food production per unit

// -----------------------------------
// Combat
// -----------------------------------

namespace CCombat {
    // bp of successful pillage
    const PILLAGE_AMOUNT = 25;

    // a min delay between attacks on a Realm; it can't
    // be attacked again during cooldown
    const ATTACK_COOLDOWN_PERIOD = DAY / 10;  // 1 day unit

    // used to signal which side won the battle
    const COMBAT_OUTCOME_ATTACKER_WINS = 1;
    const COMBAT_OUTCOME_DEFENDER_WINS = 0;

    // used when adding or removing squads to Realms
    const ATTACKING_SQUAD_SLOT = 1;
    const DEFENDING_SQUAD_SLOT = 2;

    // when defending, how many population does it take
    // to inflict a single hit point on the attacker
    const POPULATION_PER_HIT_POINT = 50;

    // upper limit (inclusive) of how many hit points
    // can a defense wall inflict on the attacker
    const MAX_WALL_DEFENSE_HIT_POINTS = 5;

    // amount of $LORDS as a reward for tearing down a goblin town
    const GOBLINDOWN_REWARD = 20;

    // Army XP
    const DEFENDING_ARMY_XP = 30;
    const ATTACKING_ARMY_XP = 100;

    // total battalions
    const TOTAL_BATTALIONS = 30;

    // weight in bp
    const FIXED_DAMAGE_AMOUNT = 70;
}

// -----------------------------------
// Crypts
// -----------------------------------
const RESOURCES_PER_CRYPT = 1;  // We only generate one resource per crypt (vs up to 7 per realm)
const LEGENDARY_MULTIPLIER = 10;  // Legendary maps generate 10x resources as non-egendat

// -----------------------------------
// Misc
// -----------------------------------
const GENESIS_TIMESTAMP = 1645743897;

// -----------------------------------
// Goblin Town
// -----------------------------------
const GOBLIN_WELCOME_PARTY_STRENGTH = 1;
const MAX_GOBLIN_TOWN_STRENGTH = 12;

// -----------------------------------
// Coordinates
// -----------------------------------
const SECONDS_PER_KM = 200;

// -----------------------------------
// Calculator
// -----------------------------------

namespace CCalculator {
    // Base happiness level
    const BASE_HAPPINESS = 100;

    // Happiness loss effects
    const NO_RELIC_LOSS = 12;
    const NO_FOOD_LOSS = 5;
    const NO_DEFENDING_ARMY_LOSS = 5;

    // number of potentially random events
    const NUMBER_OF_RANDOM_EVENTS = 9;
}
