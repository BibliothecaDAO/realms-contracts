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
    SHIFT_P_4,
    ItemShift,
    StatisticShift,
    AdventurerSlotIds,
    AdventurerStatus,
    DiscoveryType,
)

from contracts.loot.constants.item import Item
from contracts.settling_game.utils.general import unpack_data
from contracts.settling_game.utils.constants import SHIFT_41
from contracts.loot.constants.beast import Beast
from contracts.loot.loot.stats.combat import CombatStats

namespace AdventurerLib {
    func birth{syscall_ptr: felt*, range_check_ptr}(
        race: felt,
        home_realm: felt,
        name: felt,
        birth_date: felt,
        order: felt,
        image_hash_1: felt,
        image_hash_2: felt,
    ) -> (adventurer_static: AdventurerStatic, adventurer_dynamic: AdventurerDynamic) {
        alloc_locals;

        let Race = race;  // stored state
        let HomeRealm = home_realm;  // stored state
        let Birthdate = birth_date;  // stored state
        let Name = name;  // stored state
        let Order = order;  // stored state
        let ImageHash1 = image_hash_1;  // stored state
        let ImageHash2 = image_hash_2;  // stored state

        let Health = 100;  // stored state
        let XP = 0;  // stored state
        let Level = 1;  // stored state

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

        let Status = AdventurerStatus.Idle;
        let Beast = 0;

        return (
            AdventurerStatic(
                Race=Race,
                HomeRealm=HomeRealm,
                Birthdate=Birthdate,
                Name=Name,
                Order=Order,
                ImageHash1=ImageHash1,
                ImageHash2=ImageHash2,
            ),
            AdventurerDynamic(
                Health=Health,
                Level=Level,
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
                Status=Status,
                Beast=Beast,
            ),
        );
    }

    func aggregate_data{syscall_ptr: felt*, range_check_ptr}(
        adventurer_static: AdventurerStatic, adventurer_dynamic: AdventurerDynamic
    ) -> (adventurer: AdventurerState) {
        let adventurer = AdventurerState(
            adventurer_static.Race,
            adventurer_static.HomeRealm,
            adventurer_static.Birthdate,
            adventurer_static.Name,
            adventurer_static.Order,
            adventurer_static.ImageHash1,
            adventurer_static.ImageHash2,
            adventurer_dynamic.Health,
            adventurer_dynamic.Level,
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
            adventurer_dynamic.Status,
            adventurer_dynamic.Beast,
        );

        return (adventurer,);
    }

    func split_data{syscall_ptr: felt*, range_check_ptr}(adventurer: AdventurerState) -> (
        adventurer_static: AdventurerStatic, adventurer_dynamic: AdventurerDynamic
    ) {
        let adventurer_static = AdventurerStatic(
            adventurer.Race,
            adventurer.HomeRealm,
            adventurer.Birthdate,
            adventurer.Name,
            adventurer.Order,
            adventurer.ImageHash1,
            adventurer.ImageHash2,
        );

        let adventurer_dynamic = AdventurerDynamic(
            adventurer.Health,
            adventurer.Level,
            adventurer.Strength,
            adventurer.Dexterity,
            adventurer.Vitality,
            adventurer.Intelligence,
            adventurer.Wisdom,
            adventurer.Charisma,
            adventurer.Luck,
            adventurer.XP,
            adventurer.WeaponId,
            adventurer.ChestId,
            adventurer.HeadId,
            adventurer.WaistId,
            adventurer.FeetId,
            adventurer.HandsId,
            adventurer.NeckId,
            adventurer.RingId,
            adventurer.Status,
            adventurer.Beast,
        );

        return (adventurer_static, adventurer_dynamic);
    }

    func pack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(unpacked_adventurer_state: AdventurerDynamic) -> (packed_adventurer: PackedAdventurerState) {
        alloc_locals;
        // ---------- p1 ---------#
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

        let Status = unpacked_adventurer_state.Status * SHIFT_P_4._1;
        let Beast = unpacked_adventurer_state.Beast * SHIFT_P_4._2;

        // packing
        // let p1 = XP + Luck + Charisma + Wisdom + Intelligence + Vitality + Dexterity + Strength + Level + Health;
        let p1 = Health + Level + Strength + Dexterity + Vitality + Intelligence + Wisdom +
            Charisma + Luck + XP;
        // let p2 = Waist + Head + Chest + Weapon;
        let p2 = Weapon + Chest + Head + Waist;
        // let p3 = Ring + Neck + Hands + Feet;
        let p3 = Feet + Hands + Neck + Ring;
        let p4 = Status + Beast;

        let packedAdventurer = PackedAdventurerState(p1, p2, p3, p4);

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
        let (Health) = unpack_data(packed_adventurer.p1, 0, 1023);  // 10
        let (Level) = unpack_data(packed_adventurer.p1, 10, 1023);  // 10

        // Physical
        let (Strength) = unpack_data(packed_adventurer.p1, 20, 1023);  // 10
        let (Dexterity) = unpack_data(packed_adventurer.p1, 30, 1023);  // 10
        let (Vitality) = unpack_data(packed_adventurer.p1, 40, 1023);  // 10

        // Mental
        let (Intelligence) = unpack_data(packed_adventurer.p1, 50, 1023);  // 10
        let (Wisdom) = unpack_data(packed_adventurer.p1, 60, 1023);  // 10
        let (Charisma) = unpack_data(packed_adventurer.p1, 70, 1023);  // 10

        // Luck
        let (Luck) = unpack_data(packed_adventurer.p1, 80, 1023);  // 10

        // XP
        let (XP) = unpack_data(packed_adventurer.p1, 90, 134217727);  // 27

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

        // ---------- p4 ---------#
        let (Status) = unpack_data(packed_adventurer.p4, 0, 7);  // 3
        let (Beast) = unpack_data(packed_adventurer.p4, 3, 2199023255551);  // 41

        return (
            AdventurerDynamic(
                Health=Health,
                Level=Level,
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
                Status=Status,
                Beast=Beast,
            ),
        );
    }

    // helper to cast value to location in State
    func cast_state{syscall_ptr: felt*, range_check_ptr}(
        index: felt, value: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        let (a) = alloc();

        memcpy(a, &unpacked_adventurer, index);
        memset(a + index, value, 1);
        memcpy(
            a + (index + 1),
            &unpacked_adventurer + (index + 1),
            AdventurerDynamic.SIZE - (index + 1),
        );

        let cast_adventurer = cast(a, AdventurerDynamic*);

        return ([cast_adventurer],);
    }

    func equip_item{syscall_ptr: felt*, range_check_ptr}(
        item_token_id: felt, item: Item, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // pass index shift and Item slot to find what item to update
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            ItemShift + item.Slot, item_token_id, unpacked_adventurer
        );

        return (updated_adventurer,);
    }

    func unequip_item{syscall_ptr: felt*, range_check_ptr}(
        item: Item, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        // pass index shift and Item slot to find what item to update
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            ItemShift + item.Slot, 0, unpacked_adventurer
        );

        return (updated_adventurer,);
    }

    func deduct_health{syscall_ptr: felt*, range_check_ptr}(
        damage: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // check if damage dealt is less than health remaining
        let still_alive = is_le(damage, unpacked_adventurer.Health);

        // if adventurer is still alive
        if (still_alive == TRUE) {
            // set new health to previous health - damage dealt
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Health, unpacked_adventurer.Health - damage, unpacked_adventurer
            );
        } else {
            // if damage dealt exceeds health remaining, set health to 0
            let (updated_adventurer: AdventurerDynamic) = cast_state(
                AdventurerSlotIds.Health, 0, unpacked_adventurer
            );
        }

        return (updated_adventurer,);
    }

    // loaf
    func add_health{syscall_ptr: felt*, range_check_ptr}(
        health: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // set new health to previous health - damage dealt
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.Health, unpacked_adventurer.Health + health, unpacked_adventurer
        );

        return (updated_adventurer,);
    }

    func increase_xp{syscall_ptr: felt*, range_check_ptr}(
        xp: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // update adventurer xp
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.XP, xp, unpacked_adventurer
        );

        // return updated adventurer
        return (updated_adventurer,);
    }

    func update_level{syscall_ptr: felt*, range_check_ptr}(
        level: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // update adventurer level
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.Level, level, unpacked_adventurer
        );

        // return updated adventurer
        return (updated_adventurer,);
    }

    func update_status{syscall_ptr: felt*, range_check_ptr}(
        status: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // Make sure status is within allowable range
        assert_le(status, AdventurerStatus.Dead + 1);

        // update adventurer status
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.Status, status, unpacked_adventurer
        );

        // return updated adventurer
        return (updated_adventurer,);
    }

    func assign_beast{syscall_ptr: felt*, range_check_ptr}(
        beast_id: felt, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // update adventurer beast
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.Beast, beast_id, unpacked_adventurer
        );

        // return updated adventurer
        return (updated_adventurer,);
    }

    func remove_beast{syscall_ptr: felt*, range_check_ptr}(
        unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // zero out the beast associated with the adventurer
        let (updated_adventurer: AdventurerDynamic) = cast_state(
            AdventurerSlotIds.Beast, 0, unpacked_adventurer
        );

        // return updated adventurer
        return (updated_adventurer,);
    }

    func get_random_discovery{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
        xoroshiro_random: felt
    ) -> (discovery: felt) {
        alloc_locals;

        let (_, r) = unsigned_div_rem(xoroshiro_random, 4);
        return (r,);  // values from 0 to 3 inclusive
    }

    func update_statistics{syscall_ptr: felt*, range_check_ptr}(
        item_token_id: felt, item: Item, unpacked_adventurer: AdventurerDynamic
    ) -> (new_unpacked_adventurer: AdventurerDynamic) {
        alloc_locals;

        // cast state into felt array
        // make adjustment to felt at index
        // cast back into adventuerState

        return (0,);
    }
}
