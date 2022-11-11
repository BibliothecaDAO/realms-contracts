// BUILDINGS LIBRARY
//   functions for
//
//
// MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset

from contracts.loot.loot.stats.item import ItemStats

from contracts.loot.constants.adventurer import (
    Adventurer,
    AdventurerState,
    AdventurerStatic,
    AdventurerDynamic,
    PackedAdventurerState,
    SHIFT_P_1,
    ItemShift,
    StatisticShift,
    AdventurerSlotIds,
)

from contracts.loot.constants.item import Item
from contracts.settling_game.utils.general import unpack_data
from contracts.settling_game.utils.constants import SHIFT_41

namespace AdventurerLib {
    func birth{syscall_ptr: felt*, range_check_ptr}(
        race: felt, home_realm: felt, name: felt, birth_date: felt, order: felt
    ) -> (adventurer_static: AdventurerStatic, adventurer_dynamic: AdventurerDynamic) {
        alloc_locals;

        let Race = race; // stored static
        let HomeRealm = home_realm;  // stored static
        let Birthdate = birth_date;  // stored static
        let Name = name;  // stored static
        let Order = order;  // stored static

        let Health = 100;  // stored dynamic
        let XP = 0;  // stored dynamic
        let Level = 0;  // stored dynamic

        // Physical
        let Strength = 0; // stored dynamic
        let Dexterity = 0; // stored dynamic
        let Vitality = 0; // stored dynamic

        // Mental
        let Intelligence = 0; // stored dynamic
        let Wisdom = 0; // stored dynamic
        let Charisma = 0; // stored dynamic

        let Luck = 0; // stored dynamic

        let NeckId = 0; // stored dynamic
        let WeaponId = 0; // stored dynamic
        let RingId = 0; // stored dynamic
        let ChestId = 0; // stored dynamic
        let HeadId = 0; // stored dynamic
        let WaistId = 0; // stored dynamic
        let FeetId = 0; // stored dynamic
        let HandsId = 0; // stored dynamic

        return (
            AdventurerStatic(
                Race,
                HomeRealm,
                Birthdate,
                Name,
                Order
            ),
            AdventurerDynamic(
                Health,
                Level,
                Strength,
                Dexterity,
                Vitality,
                Intelligence,
                Wisdom,
                Charisma,
                Luck,
                XP,
                WeaponId,
                ChestId,
                HeadId,
                WaistId,
                FeetId,
                HandsId,
                NeckId,
                RingId,
            )
        );
    }

    func pack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(unpacked_adventurer_state: AdventurerDynamic) -> (packed_adventurer: PackedAdventurerState) {
        alloc_locals;

        let Health = unpacked_adventurer_state.Health * SHIFT_P_1._1;
        let Level = unpacked_adventurer_state.Level * SHIFT_P_1._2;

        // Physical
        let Strength = unpacked_adventurer_state.Strength * SHIFT_P_1._3;
        let Dexterity = unpacked_adventurer_state.Dexterity * SHIFT_P_1._4;
        let Vitality = unpacked_adventurer_state.Vitality * SHIFT_P_1._5;

        // Mental
        let Intelligence = unpacked_adventurer_state.Intelligence * SHIFT_P_1._6;
        let Wisdom = unpacked_adventurer_state.Wisdom * SHIFT_P_1._7;
        let Charisma = unpacked_adventurer_state.Charisma * SHIFT_P_1._8;

        let Luck = unpacked_adventurer_state.Luck * SHIFT_P_1._9;

        let XP = unpacked_adventurer_state.XP * SHIFT_P_1._10;

        // Items
        let Weapon = unpacked_adventurer_state.WeaponId * SHIFT_41._1;
        let Chest = unpacked_adventurer_state.ChestId * SHIFT_41._2;
        let Head = unpacked_adventurer_state.HeadId * SHIFT_41._3;
        let Waist = unpacked_adventurer_state.WaistId * SHIFT_41._4;

        let Feet = unpacked_adventurer_state.FeetId * SHIFT_41._1;
        let Hands = unpacked_adventurer_state.HandsId * SHIFT_41._2;
        let Neck = unpacked_adventurer_state.NeckId * SHIFT_41._3;
        let Ring = unpacked_adventurer_state.RingId * SHIFT_41._4;

        // packing
        let p1 = XP + Luck + Charisma + Wisdom + Intelligence + Vitality + Dexterity + Strength + Level + Health;
        let p2 = Waist + Head + Chest + Weapon;
        let p3 = Ring + Neck + Hands + Feet;

        let packedAdventurer = PackedAdventurerState(p1, p2, p3);

        return (packedAdventurer,);
    }

    func unpack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(packed_adventurer: PackedAdventurerState) -> (adventurer: AdventurerDynamic) {
        alloc_locals;

        // ---------- p1 ---------#
        let (Health) = unpack_data(packed_adventurer.p1, 0, 8191);
        let (Level) = unpack_data(packed_adventurer.p1, 13, 511);

        // Physical
        let (Strength) = unpack_data(packed_adventurer.p1, 22, 1023);
        let (Dexterity) = unpack_data(packed_adventurer.p1, 32, 1023);
        let (Vitality) = unpack_data(packed_adventurer.p1, 42, 1023);

        // Mental
        let (Intelligence) = unpack_data(packed_adventurer.p1, 52, 1023);
        let (Wisdom) = unpack_data(packed_adventurer.p1, 62, 1023);
        let (Charisma) = unpack_data(packed_adventurer.p1, 72, 1023);

        // Luck
        let (Luck) = unpack_data(packed_adventurer.p1, 82, 1023);

        // XP
        let (XP) = unpack_data(packed_adventurer.p1, 92, 134217727);  // the rest of the felt

        // ---------- p2 ---------#
        let (WeaponId) = unpack_data(packed_adventurer.p2, 0, 2199023255551);  // 41
        let (ChestId) = unpack_data(packed_adventurer.p2, 41, 2199023255551);  // 41
        let (HeadId) = unpack_data(packed_adventurer.p2, 82, 2199023255551);  // 41
        let (WaistId) = unpack_data(packed_adventurer.p2, 123, 2199023255551);  // 41

        // ---------- p3 ---------#
        let (FeetId) = unpack_data(packed_adventurer.p3, 0, 2199023255551);  // 41
        let (HandsId) = unpack_data(packed_adventurer.p3, 41, 2199023255551);  // 41
        let (NeckId) = unpack_data(packed_adventurer.p3, 82, 2199023255551);  // 41
        let (RingId) = unpack_data(packed_adventurer.p3, 123, 2199023255551);  // 41

        return (
            AdventurerDynamic(
                Health,
                Level,
                Strength,
                Dexterity,
                Vitality,
                Intelligence,
                Wisdom,
                Charisma,
                Luck,
                XP,
                WeaponId,
                ChestId,
                HeadId,
                WaistId,
                FeetId,
                HandsId,
                NeckId,
                RingId,
            ),
        );
    }

    // TODO: Equip Item
    // TODO: update stats
    // TODO: increase XP
    // TODO: effect health function

    // helper to cast value to location in State
    func cast_dynamic{syscall_ptr: felt*, range_check_ptr}(
        index: felt, value: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        let (a) = alloc();

        memcpy(a, &unpacked_adventurer, index);
        memset(a + index, value, 1);
        memcpy(
            a + (index + 1), &unpacked_adventurer + (index + 1), AdventurerDynamic.SIZE - (index + 1)
        );

        let cast_adventurer = cast(a, AdventurerDynamic*);

        return ([cast_adventurer],);
    }

    // helper to cast value to location in State
    func cast_state{syscall_ptr: felt*, range_check_ptr}(
        adventurer_static: AdventurerStatic, adventurer_dynamic: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerState) {

        let cast_adventurer = AdventurerState(
            adventurer_static.Race,
            adventurer_static.HomeRealm,
            adventurer_static.Birthdate,
            adventurer_static.Name,
            adventurer_dynamic.Health,
            adventurer_dynamic.Level,
            adventurer_static.Order,
            adventurer_dynamic.Strength,
            adventurer_dynamic.Dexterity,
            adventurer_dynamic.Vitality,
            adventurer_dynamic.Intelligence,
            adventurer_dynamic.Wisdom,
            adventurer_dynamic.Charisma,
            adventurer_dynamic.Luck,
            adventurer_dynamic.XP,
            adventurer_dynamic.WeaponId,
            adventurer_dynamic.ChestId,
            adventurer_dynamic.HeadId,
            adventurer_dynamic.WaistId,
            adventurer_dynamic.FeetId,
            adventurer_dynamic.HandsId,
            adventurer_dynamic.NeckId,
            adventurer_dynamic.RingId,
        );

        return (cast_adventurer,);
    }

    func equip_item{syscall_ptr: felt*, range_check_ptr}(
        item_token_id: felt, item: Item, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // pass index shift and Item slot to find what item to update
        let (updated_adventurer: AdventurerDynamic) = cast_dynamic(
            ItemShift + item.Slot, item_token_id, unpacked_adventurer
        );

        return (updated_adventurer,);
    }

    func adjust_health{syscall_ptr: felt*, range_check_ptr}(
        health_change: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // check if negative unpacked_adventurer.Health - health_change

        // if Negative then set 0 and KILL
        let (updated_adventurer: AdventurerDynamic) = cast_dynamic(
            AdventurerSlotIds.Health,
            unpacked_adventurer.Health - health_change,
            unpacked_adventurer,
        );

        return (updated_adventurer,);
    }

    func increase_xp{syscall_ptr: felt*, range_check_ptr}(
        item_token_id: felt, item: Item, unpacked_adventurer: AdventurerState
    ) -> (new_unpacked_adventurer: AdventurerState) {
        alloc_locals;

        // cast state into felt array
        // make adjustment to felt at index
        // cast back into adventuerState

        return (0,);
    }

    func update_statistics{syscall_ptr: felt*, range_check_ptr}(
        item_token_id: felt, item: Item, unpacked_adventurer: AdventurerState
    ) -> (new_unpacked_adventurer: AdventurerState) {
        alloc_locals;

        // cast state into felt array
        // make adjustment to felt at index
        // cast back into adventuerState

        return (0,);
    }
}
