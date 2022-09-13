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
    PackedAdventurerState,
    SHIFT_P_1,
    SHIFT_P_2,
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
    ) -> (adventurer: AdventurerState) {
        alloc_locals;

        let Race = race;  // stored state
        let HomeRealm = home_realm;  // stored state
        let Birthdate = birth_date;  // stored state
        let Name = name;  // stored state

        let Health = 100;  // stored state
        let XP = 0;  // stored state
        let Level = 0;  // stored state
        let Order = order;  // stored state

        // Physical
        let Strength = 0;
        let Dexterity = 0;
        let Vitality = 0;

        // Mental
        let Intelligence = 0;
        let Wisdom = 0;
        let Charisma = 0;

        let Luck = 0;

        let NeckId = 0;
        let WeaponId = 0;
        let RingId = 0;
        let ChestId = 0;
        let HeadId = 0;
        let WaistId = 0;
        let FeetId = 0;
        let HandsId = 0;

        return (
            AdventurerState(
            Race=Race,
            HomeRealm=HomeRealm,
            Birthdate=Birthdate,
            Name=Name,
            Health=Health,
            Level=Level,
            Order=Order,
            Strength=Strength,
            Dexterity=Dexterity,
            Vitality=Vitality,
            Intelligence=Intelligence,
            Wisdom=Wisdom,
            Charisma=Charisma,
            Luck=Luck,
            XP=XP,
            WeaponId=WeaponId,
            ChestId=ChestId,
            HeadId=HeadId,
            WaistId=WaistId,
            FeetId=FeetId,
            HandsId=HandsId,
            NeckId=NeckId,
            RingId=RingId,
            ),
        );
    }

    func pack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(unpacked_adventurer_state: AdventurerState) -> (packed_adventurer: PackedAdventurerState) {
        alloc_locals;
        // ---------- p1 ---------#
        let Race = unpacked_adventurer_state.Race * SHIFT_P_1._1;
        let HomeRealm = unpacked_adventurer_state.HomeRealm * SHIFT_P_1._2;
        let Birthdate = unpacked_adventurer_state.Birthdate * SHIFT_P_1._3;
        let Name = unpacked_adventurer_state.Name * SHIFT_P_1._4;

        let Health = unpacked_adventurer_state.Health * SHIFT_P_2._1;
        let Level = unpacked_adventurer_state.Level * SHIFT_P_2._2;
        let Order = unpacked_adventurer_state.Order * SHIFT_P_2._3;

        // Physical
        let Strength = unpacked_adventurer_state.Strength * SHIFT_P_2._4;
        let Dexterity = unpacked_adventurer_state.Dexterity * SHIFT_P_2._5;
        let Vitality = unpacked_adventurer_state.Vitality * SHIFT_P_2._6;

        // Mental
        let Intelligence = unpacked_adventurer_state.Intelligence * SHIFT_P_2._7;
        let Wisdom = unpacked_adventurer_state.Wisdom * SHIFT_P_2._8;
        let Charisma = unpacked_adventurer_state.Charisma * SHIFT_P_2._9;

        let Luck = unpacked_adventurer_state.Luck * SHIFT_P_2._10;

        let XP = unpacked_adventurer_state.XP * SHIFT_P_2._11;

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
        let p1 = Name + Birthdate + HomeRealm + Race;
        let p2 = XP + Luck + Charisma + Wisdom + Intelligence + Vitality + Dexterity + Strength + Order + Level + Health;
        let p3 = Waist + Head + Chest + Weapon;
        let p4 = Ring + Neck + Hands + Feet;

        let packedAdventurer = PackedAdventurerState(p1, p2, p3, p4);

        return (packedAdventurer,);
    }

    func unpack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(packed_adventurer: PackedAdventurerState) -> (adventurer: AdventurerState) {
        alloc_locals;

        // ---------- p1 ---------#
        let (Race) = unpack_data(packed_adventurer.p1, 0, 15);  // 3
        let (HomeRealm) = unpack_data(packed_adventurer.p1, 3, 8191);  // 13
        let (Birthdate) = unpack_data(packed_adventurer.p1, 16, 8589934591);  // 36
        let (Name) = unpack_data(packed_adventurer.p1, 65, 562949953421311);  // 59

        // ---------- p2 ---------#
        let (Health) = unpack_data(packed_adventurer.p2, 0, 8191);
        let (Level) = unpack_data(packed_adventurer.p2, 13, 511);
        let (Order) = unpack_data(packed_adventurer.p2, 22, 31);

        // Physical
        let (Strength) = unpack_data(packed_adventurer.p2, 27, 1023);
        let (Dexterity) = unpack_data(packed_adventurer.p2, 37, 1023);
        let (Vitality) = unpack_data(packed_adventurer.p2, 47, 1023);

        // Mental
        let (Intelligence) = unpack_data(packed_adventurer.p2, 57, 1023);
        let (Wisdom) = unpack_data(packed_adventurer.p2, 67, 1023);
        let (Charisma) = unpack_data(packed_adventurer.p2, 77, 1023);

        // Luck
        let (Luck) = unpack_data(packed_adventurer.p2, 87, 1023);

        // XP
        let (XP) = unpack_data(packed_adventurer.p2, 97, 134217727);  // the rest of the felt

        // ---------- p3 ---------#
        let (WeaponId) = unpack_data(packed_adventurer.p3, 0, 2199023255551);  // 41
        let (ChestId) = unpack_data(packed_adventurer.p3, 41, 2199023255551);  // 41
        let (HeadId) = unpack_data(packed_adventurer.p3, 82, 2199023255551);  // 41
        let (WaistId) = unpack_data(packed_adventurer.p3, 123, 2199023255551);  // 41

        // ---------- p4 ---------#
        let (FeetId) = unpack_data(packed_adventurer.p4, 0, 2199023255551);  // 41
        let (HandsId) = unpack_data(packed_adventurer.p4, 41, 2199023255551);  // 41
        let (NeckId) = unpack_data(packed_adventurer.p4, 82, 2199023255551);  // 41
        let (RingId) = unpack_data(packed_adventurer.p4, 123, 2199023255551);  // 41

        return (
            AdventurerState(
            Race=Race,
            HomeRealm=HomeRealm,
            Birthdate=Birthdate,
            Name=Name,
            Health=Health,
            Level=Level,
            Order=Order,
            Strength=Strength,
            Dexterity=Dexterity,
            Vitality=Vitality,
            Intelligence=Intelligence,
            Wisdom=Wisdom,
            Charisma=Charisma,
            Luck=Luck,
            XP=XP,
            WeaponId=WeaponId,
            ChestId=ChestId,
            HeadId=HeadId,
            WaistId=WaistId,
            FeetId=FeetId,
            HandsId=HandsId,
            NeckId=NeckId,
            RingId=RingId,
            ),
        );
    }

    // TODO: Equip Item
    // TODO: update stats
    // TODO: increase XP
    // TODO: effect health function

    // helper to cast value to location in State
    func cast_state{syscall_ptr: felt*, range_check_ptr}(
        index: felt, value: felt, unpacked_adventurer: AdventurerState
    ) -> (new_unpacked_adventurer: AdventurerState) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        let (a) = alloc();

        memcpy(a, &unpacked_adventurer, index);
        memset(a + index, value, 1);
        memcpy(
            a + (index + 1), &unpacked_adventurer + (index + 1), AdventurerState.SIZE - (index + 1)
        );

        let cast_adventurer = cast(a, AdventurerState*);

        return ([cast_adventurer],);
    }

    func equip_item{syscall_ptr: felt*, range_check_ptr}(
        item_token_id: felt, item: Item, unpacked_adventurer: AdventurerState
    ) -> (new_unpacked_adventurer: AdventurerState) {
        alloc_locals;

        // pass index shift and Item slot to find what item to update
        let (updated_adventurer: AdventurerState) = cast_state(
            ItemShift + item.Slot, item_token_id, unpacked_adventurer
        );

        return (updated_adventurer,);
    }

    func adjust_health{syscall_ptr: felt*, range_check_ptr}(
        health_change: felt, unpacked_adventurer: AdventurerState
    ) -> (new_unpacked_adventurer: AdventurerState) {
        alloc_locals;

        // check if negative unpacked_adventurer.Health - health_change

        // if Negative then set 0 and KILL
        let (updated_adventurer: AdventurerState) = cast_state(
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
