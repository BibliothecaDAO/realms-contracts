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

// Structure for the adventurer Beast primitive
struct Beast {
    Id: felt,  // item id 1 - 100
    Health: felt,  // health of the beast
    Type: felt,  // same as Loot weapons: magic, bludgeon, blade
    Rank: felt,  // same as Loot weapons: 1 is the strongest
    Prefix_1: felt,  // First part of the name prefix (i.e Tear)
    Prefix_2: felt,  // Second part of the name prefix (i.e Bearer)
    Adventurer: felt, // The token id of the adventurer the beast is battling
    XP: felt,  // the xp of the beast
    SlainBy: felt, // the tokenId of the adventurer that slayed this beast
    SlainOnDate: felt, // unix timestamp when the beast was slain
}

namespace BeastConstants {
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

    namespace BeastType {
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
}

namespace BeastUtils {
    func get_rank_from_id{syscall_ptr: felt*, range_check_ptr}(beast_id: felt) -> (rank: felt) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + beast_id - 1],);

        labels:
        dw BeastConstants.BeastRank.Phoenix;
        dw BeastConstants.BeastRank.Griffin;
        dw BeastConstants.BeastRank.Minotaur;
        dw BeastConstants.BeastRank.Basilisk;
        dw BeastConstants.BeastRank.Wraith;
        dw BeastConstants.BeastRank.Ghoul;
        dw BeastConstants.BeastRank.Goblin;
        dw BeastConstants.BeastRank.Skeleton;
        dw BeastConstants.BeastRank.Giant;
        dw BeastConstants.BeastRank.Yeti;
        dw BeastConstants.BeastRank.Orc;
        dw BeastConstants.BeastRank.Beserker;
        dw BeastConstants.BeastRank.Ogre;
        dw BeastConstants.BeastRank.Dragon;
        dw BeastConstants.BeastRank.Vampire;
        dw BeastConstants.BeastRank.Werewolf;
        dw BeastConstants.BeastRank.Spider;
        dw BeastConstants.BeastRank.Rat;
    }

    func get_type_from_id{syscall_ptr: felt*, range_check_ptr}(beast_id: felt) -> (type: felt) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + beast_id - 1],);

        labels:
        dw BeastConstants.BeastType.Phoenix;
        dw BeastConstants.BeastType.Griffin;
        dw BeastConstants.BeastType.Minotaur;
        dw BeastConstants.BeastType.Basilisk;
        dw BeastConstants.BeastType.Wraith;
        dw BeastConstants.BeastType.Ghoul;
        dw BeastConstants.BeastType.Goblin;
        dw BeastConstants.BeastType.Skeleton;
        dw BeastConstants.BeastType.Giant;
        dw BeastConstants.BeastType.Yeti;
        dw BeastConstants.BeastType.Orc;
        dw BeastConstants.BeastType.Beserker;
        dw BeastConstants.BeastType.Ogre;
        dw BeastConstants.BeastType.Dragon;
        dw BeastConstants.BeastType.Vampire;
        dw BeastConstants.BeastType.Werewolf;
        dw BeastConstants.BeastType.Spider;
        dw BeastConstants.BeastType.Rat;
    }

    // TODO: 
    // 1. Make this actually random
    // 2. Provide options to specify greatness, rank, and/or type
    //    i.e allow someone to pick a weak magical beast when needed
    func get_random_beast{syscall_ptr: felt*, range_check_ptr}() -> (beast: Beast, health: felt,
    type: felt, rank: felt, greatness: felt) {
        alloc_locals;


        // if input parameters are zero, generate random values
        // our forest beasts will be rank=5, greatness 1, type random, health 100, prefix 0


        // TODO: replace this with xorshiro rng
        local beastId;
        %{
             import random
             ids.beastId = random.randint(1, Rat)
         %}

        return (
            Beast(
            Id=beastId,
            Health=100,
            Type=1,
            Rank=1,
            Prefix_1=0,
            Greatness=10,
            ),
        );
    }
}
