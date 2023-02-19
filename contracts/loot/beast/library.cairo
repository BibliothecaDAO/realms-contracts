%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.pow import pow

from contracts.settling_game.utils.general import unpack_data

from contracts.loot.constants.adventurer import Adventurer, AdventurerState
from contracts.loot.constants.beast import Beast, BeastStatic, BeastDynamic, SHIFT_P, BeastSlotIds
from contracts.loot.beast.stats.beast import BeastStats
from contracts.loot.loot.stats.item import ItemStats

const BASE_BEAST_LEVEL = 3;
namespace BeastLib {
    func create{syscall_ptr: felt*, range_check_ptr}(
        beast_id: felt,
        adventurer_id: felt,
        adventurer_state: AdventurerState,
        random_beast_level: felt,
    ) -> (beast_static: BeastStatic, beast_dynamic: BeastDynamic) {
        alloc_locals;
        // let (_, random_level) = unsigned_div_rem(random, 6);

        // let (_, r) = unsigned_div_rem(random, 17);

        let is_less_than_base_level = is_le(adventurer_state.Level, BASE_BEAST_LEVEL);
        if (is_less_than_base_level == TRUE) {
            tempvar beast_level = adventurer_state.Level;
        } else {
            tempvar beast_level = random_beast_level + (adventurer_state.Level - BASE_BEAST_LEVEL);
        }

        // let beast_id = r + 1;

        let BeastId = beast_id + 1;

        let Health = 100;
        let (Prefix_1) = ItemStats.item_name_prefix(1);
        let (Prefix_2) = ItemStats.item_name_suffix(1);
        let Adventurer = adventurer_id;
        let XP = 0;
        let Level = beast_level;
        let SlainOnDate = 0;

        return (
            BeastStatic(Id=BeastId, Prefix_1=Prefix_1, Prefix_2=Prefix_2),
            BeastDynamic(
                Health=Health, Adventurer=Adventurer, XP=XP, Level=Level, SlainOnDate=SlainOnDate
            ),
        );
    }

    func create_start_beast{syscall_ptr: felt*, range_check_ptr}(
        beast_id: felt, adventurer_id: felt, adventurer_state: AdventurerState
    ) -> (beast_static: BeastStatic, beast_dynamic: BeastDynamic) {
        alloc_locals;

        let BeastId = beast_id;
        let Health = 2;
        let (Prefix_1) = ItemStats.item_name_prefix(1);
        let (Prefix_2) = ItemStats.item_name_suffix(1);
        let Adventurer = adventurer_id;
        let XP = 0;
        let Level = 1;
        let SlainOnDate = 0;

        return (
            BeastStatic(Id=BeastId, Prefix_1=Prefix_1, Prefix_2=Prefix_2),
            BeastDynamic(
                Health=Health, Adventurer=Adventurer, XP=XP, Level=Level, SlainOnDate=SlainOnDate
            ),
        );
    }

    func aggregate_data{syscall_ptr: felt*, range_check_ptr}(
        beast_static: BeastStatic, beast_dynamic: BeastDynamic
    ) -> (beast: Beast) {
        let (AttackType) = BeastStats.get_attack_type_from_id(beast_static.Id);
        let (ArmorType) = BeastStats.get_armor_type_from_id(beast_static.Id);
        let (Rank) = BeastStats.get_rank_from_id(beast_static.Id);

        let beast = Beast(
            beast_static.Id,
            AttackType,
            ArmorType,
            Rank,
            beast_static.Prefix_1,
            beast_static.Prefix_2,
            beast_dynamic.Health,
            beast_dynamic.Adventurer,
            beast_dynamic.XP,
            beast_dynamic.Level,
            beast_dynamic.SlainOnDate,
        );

        return (beast,);
    }

    func split_data{syscall_ptr: felt*, range_check_ptr}(beast: Beast) -> (
        beast_static: BeastStatic, beast_dynamic: BeastDynamic
    ) {
        let beast_static = BeastStatic(beast.Id, beast.Prefix_1, beast.Prefix_2);

        let beast_dynamic = BeastDynamic(
            beast.Health, beast.Adventurer, beast.XP, beast.Level, beast.SlainOnDate
        );

        return (beast_static, beast_dynamic);
    }

    func pack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(unpacked_beast: BeastDynamic) -> (packed_beast: felt) {
        let Health = unpacked_beast.Health * SHIFT_P._1;
        let Adventurer = unpacked_beast.Adventurer * SHIFT_P._2;
        let XP = unpacked_beast.XP * SHIFT_P._3;
        let Level = unpacked_beast.Level * SHIFT_P._4;
        let Slain_On_Date = unpacked_beast.SlainOnDate * SHIFT_P._5;

        let packed_beast = Health + Adventurer + XP + Level + Slain_On_Date;

        return (packed_beast,);
    }

    func unpack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(packed_beast: felt) -> (packed_beast: BeastDynamic) {
        alloc_locals;
        let (Health) = unpack_data(packed_beast, 0, 1023);  // 10
        let (Adventurer) = unpack_data(packed_beast, 10, 2199023255551);  // 41
        let (XP) = unpack_data(packed_beast, 51, 134217727);  // 27
        let (Level) = unpack_data(packed_beast, 78, 1023);  // 10
        let (Slain_On_Date) = unpack_data(packed_beast, 88, 8589934591);  // 33

        return (BeastDynamic(Health, Adventurer, XP, Level, Slain_On_Date),);
    }

    // helper to cast value to location in State
    func cast_state{syscall_ptr: felt*, range_check_ptr}(
        index: felt, value: felt, unpacked_beast: BeastDynamic
    ) -> (new_unpacked_beast: BeastDynamic) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        let (a) = alloc();

        memcpy(a, &unpacked_beast, index);
        memset(a + index, value, 1);
        memcpy(a + (index + 1), &unpacked_beast + (index + 1), Beast.SIZE - (index + 1));

        let cast_beast = cast(a, BeastDynamic*);

        return ([cast_beast],);
    }

    func deduct_health{syscall_ptr: felt*, range_check_ptr}(
        damage: felt, unpacked_beast: BeastDynamic
    ) -> (new_unpacked_beast: BeastDynamic) {
        alloc_locals;

        // check if damage dealt is less than health remaining
        let still_alive = is_le(damage, unpacked_beast.Health);

        // if adventurer is still alive
        if (still_alive == TRUE) {
            // set new health to previous health - damage dealt
            let (updated_beast: BeastDynamic) = cast_state(
                BeastSlotIds.Health, unpacked_beast.Health - damage, unpacked_beast
            );
        } else {
            // if damage dealt exceeds health remaining, set health to 0
            let (updated_beast: BeastDynamic) = cast_state(BeastSlotIds.Health, 0, unpacked_beast);
        }

        return (updated_beast,);
    }

    func set_adventurer{syscall_ptr: felt*, range_check_ptr}(
        adventurer_id: felt, unpacked_beast: BeastDynamic
    ) -> (new_unpacked_beast: BeastDynamic) {
        alloc_locals;

        // set adventurer (tokenId) on the beast to the provided adventurerTokenId
        let (updated_beast: BeastDynamic) = cast_state(
            BeastSlotIds.Adventurer, adventurer_id, unpacked_beast
        );

        return (updated_beast,);
    }

    func slay{syscall_ptr: felt*, range_check_ptr}(
        slain_on_date: felt, unpacked_beast: BeastDynamic
    ) -> (new_beast: BeastDynamic) {
        // set slain on date on the beast to the provided adventurer id
        let (updated_slain_on_beast: BeastDynamic) = cast_state(
            BeastSlotIds.SlainOnDate, slain_on_date, unpacked_beast
        );

        return (updated_slain_on_beast,);
    }

    func get_random_flee{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
        xoroshiro_random: felt
    ) -> (discovery: felt) {
        alloc_locals;

        let (_, r) = unsigned_div_rem(xoroshiro_random, 2);
        return (r,);  // values from 0 to 1 inclusive
    }

    func calculate_greatness{syscall_ptr: felt*, range_check_ptr}(xp: felt) -> (greatness: felt) {
        // TODO: Some calculation of greatness based on xp
        // let (greatness, _) = unsigned_div_rem(xp, 1000);
        let greatness = xp;

        return (greatness,);
    }

    func increase_xp{syscall_ptr: felt*, range_check_ptr}(
        xp: felt, unpacked_beast: BeastDynamic
    ) -> (unpacked_beast_dynamic: BeastDynamic) {
        alloc_locals;

        // update adventurer xp
        let (updated_beast: BeastDynamic) = cast_state(BeastSlotIds.XP, xp, unpacked_beast);

        // return updated adventurer
        return (updated_beast,);
    }

    func update_level{syscall_ptr: felt*, range_check_ptr}(
        level: felt, unpacked_beast: BeastDynamic
    ) -> (unpacked_beast_dynamic: BeastDynamic) {
        alloc_locals;

        // update adventurer level
        let (updated_beast: BeastDynamic) = cast_state(BeastSlotIds.Level, level, unpacked_beast);

        // return updated adventurer
        return (updated_beast,);
    }

    func calculate_ambush_chance{syscall_ptr: felt*, range_check_ptr}(
        rnd: felt, beast_health: felt
    ) -> (ambush_chance: felt) {
        let (_, r) = unsigned_div_rem(rnd, 2);
        let (beast_health_multi, _) = unsigned_div_rem(beast_health, 50);
        let ambush_chance = r * (1 + beast_health_multi);

        return (ambush_chance,);
    }

    func calculate_gold_reward{syscall_ptr: felt*, range_check_ptr}(rnd: felt, xp_gained: felt) -> (
        gold_reward: felt
    ) {
        let (_, reward_multi) = unsigned_div_rem(rnd, 4);
        let (xp_correction, xp_factor) = unsigned_div_rem(xp_gained, 4);
        let xp_start = xp_gained - xp_correction;

        let gold_reward = xp_start + (xp_correction * reward_multi);

        return (gold_reward,);
    }
}
