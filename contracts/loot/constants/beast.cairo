// -----------------------------------
//   Loot.BeastConstants
//   Loot
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.registers import get_label_location
from contracts.loot.constants.item import Type
from starkware.cairo.common.cairo_builtins import HashBuiltin

struct Beast {
    Id: felt,  // beast id 1 - 100
    AttackType: felt,  // same as Loot weapons: magic, bludgeon, blade
    ArmorType: felt,  // same as Loot weapons: cloth, metal, hide
    Rank: felt,  // same as Loot weapons: 1 is the strongest
    Prefix_1: felt,  // First part of the name prefix (i.e Tear)
    Prefix_2: felt,  // Second part of the name prefix (i.e Bearer)
    Health: felt,  // health of the beast
    Adventurer: felt, // The token id of the adventurer the beast is battling
    XP: felt,  // the xp of the beast
    SlainBy: felt, // the tokenId of the adventurer that slayed this beast
    SlainOnDate: felt, // unix timestamp when the beast was slain
}

// Structure for the adventurer Beast primitive
struct BeastStatic {
    Id: felt,  // beast id 1 - 100
    Prefix_1: felt,  // First part of the name prefix (i.e Tear)
    Prefix_2: felt,  // Second part of the name prefix (i.e Bearer)
}

struct BeastDynamic {
    Health: felt,  // health of the beast
    Adventurer: felt, // The token id of the adventurer the beast is battling
    XP: felt,  // the xp of the beast
    SlainBy: felt, // the tokenId of the adventurer that slayed this beast
    SlainOnDate: felt, // unix timestamp when the beast was slain
}

namespace SHIFT_P {
    const _1 = 2 ** 0;
    const _2 = 2 ** 10;
    const _3 = 2 ** 51;
    const _4 = 2 ** 78;
    const _5 = 2 ** 119;
}

namespace BeastIds {
    const Phoenix = 1;
    const Griffin = 2;
    const Minotaur = 3;
    const Basilisk = 4;

    const Wraith = 5;
    const Ghoul = 6;
    const Goblin = 7;
    const Skeleton = 8;

    const Giant = 9;
    const Yeti = 10;
    const Orc = 11;
    const Beserker = 12;
    const Ogre = 13;

    const Dragon = 14;
    const Vampire = 15;
    const Werewolf = 16;
    const Spider = 17;
    const Rat = 18;
}

namespace BeastRank {
    const Phoenix = 1;
    const Griffin = 2;
    const Minotaur = 3;
    const Basilisk = 4;

    const Wraith = 1;
    const Ghoul = 2;
    const Goblin = 3;
    const Skeleton = 4;

    const Giant = 1;
    const Yeti = 2;
    const Orc = 3;
    const Beserker = 4;
    const Ogre = 5;

    const Dragon = 1;
    const Vampire = 2;
    const Werewolf = 3;
    const Spider = 4;
    const Rat = 5;
}

namespace BeastAttackType {
    const Phoenix = Type.Weapon.magic;
    const Griffin = Type.Weapon.magic;
    const Minotaur = Type.Weapon.magic;
    const Basilisk = Type.Weapon.magic;

    const Wraith = Type.Weapon.magic;
    const Ghoul = Type.Weapon.magic;
    const Goblin = Type.Weapon.magic;
    const Skeleton = Type.Weapon.magic;

    const Giant = Type.Weapon.bludgeon;
    const Yeti = Type.Weapon.bludgeon;
    const Orc = Type.Weapon.bludgeon;
    const Beserker = Type.Weapon.bludgeon;
    const Ogre = Type.Weapon.bludgeon;

    const Dragon = Type.Weapon.blade;
    const Vampire = Type.Weapon.blade;
    const Werewolf = Type.Weapon.blade;
    const Spider = Type.Weapon.blade;
    const Rat = Type.Weapon.blade;
}

namespace BeastArmorType {
    const Phoenix = Type.Armor.cloth;
    const Griffin = Type.Armor.cloth;
    const Minotaur = Type.Armor.cloth;
    const Basilisk = Type.Armor.cloth;

    const Wraith = Type.Armor.cloth;
    const Ghoul = Type.Armor.cloth;
    const Goblin = Type.Armor.cloth;
    const Skeleton = Type.Armor.cloth;

    const Giant = Type.Armor.metal;
    const Yeti = Type.Armor.metal;
    const Orc = Type.Armor.metal;
    const Beserker = Type.Armor.metal;
    const Ogre = Type.Armor.metal;

    const Dragon = Type.Armor.hide;
    const Vampire = Type.Armor.hide;
    const Werewolf = Type.Armor.hide;
    const Spider = Type.Armor.hide;
    const Rat = Type.Armor.hide;
}

namespace BeastSlotIds {
    const Health = 0;
    const Adventurer = 1;
    const XP = 2;
    const SlainBy = 3;
    const SlainOnDate = 4;
}
