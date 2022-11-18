%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc

from contracts.settling_game.utils.general import unpack_data
from contracts.loot.constants.adventurer import Adventurer
from contracts.loot.constants.beast import Beast, SHIFT_P, BeastSlotIds

namespace BeastLib {
    func pack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(unpacked_beast: Beast) -> (packed_beast: felt) {
        let Id = unpacked_beast.Id * SHIFT_P._1;
        let Health = unpacked_beast.Health * SHIFT_P._2;
        let Type = unpacked_beast.Type * SHIFT_P._3;
        let Rank = unpacked_beast.Rank * SHIFT_P._4;
        let Prefix_1 = unpacked_beast.Prefix_1 * SHIFT_P._5;
        let Prefix_2 = unpacked_beast.Prefix_2 * SHIFT_P._6;
        let Greatness = unpacked_beast.Greatness * SHIFT_P._7;
        let Adventurer = unpacked_beast.Adventurer * SHIFT_P._8;
        let XP = unpacked_beast.XP * SHIFT_P._9;
        let SlainBy = unpacked_beast.Adventurer * SHIFT_P._10;
        let SlainOnDate = unpacked_beast.Adventurer * SHIFT_P._11;

        let packed_beast = Id + Health + Type + Rank + Prefix_1 + Prefix_2 + Greatness + Adventurer + XP + SlainBy + SlainOnDate;

        return (packed_beast,);
    }

    func unpack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(packed_beast: felt) -> (packed_beast: Beast) {
        alloc_locals;
        let (Id) = unpack_data(packed_beast, 0, 127);
        let (Health) = unpack_data(packed_beast, 7, 1023);
        let (Type) = unpack_data(packed_beast, 17, 511);
        let (Rank) = unpack_data(packed_beast, 28, 7);
        let (Prefix_1) = unpack_data(packed_beast, 31, 127);
        let (Prefix_2) = unpack_data(packed_beast, 38, 31);
        let (Greatness) = unpack_data(packed_beast, 43, 31);
        let (Adventurer) = unpack_data(packed_beast, 48, 2199023255551);
        let (XP) = unpack_data(packed_beast, 89, 134217727);
        let (Slain_By) = unpack_data(packed_beast, 99, 2199023255551);
        let (Slain_On_Date) = unpack_data(packed_beast, 140, 8589934591);

        return (
            Beast(
            Id,
            Health,
            Type,
            Rank,
            Prefix_1,
            Prefix_2,
            Greatness,
            Adventurer,
            XP,
            Slain_By,
            Slain_On_Date,
            ),
        );
    }

    // helper to cast value to location in State
    func cast_state{syscall_ptr: felt*, range_check_ptr}(
        index: felt, value: felt, unpacked_beast: Beast
    ) -> (new_unpacked_beast: Beast) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        let (a) = alloc();

        memcpy(a, &unpacked_beast, index);
        memset(a + index, value, 1);
        memcpy(a + (index + 1), &unpacked_beast + (index + 1), Beast.SIZE - (index + 1));

        let cast_beast = cast(a, Beast*);

        return ([cast_beast],);
    }

    func deduct_health{syscall_ptr: felt*, range_check_ptr}(
        damage: felt, unpacked_beast: Beast
    ) -> (new_unpacked_beast: Beast) {
        alloc_locals;

        // check if damage dealt is less than health remaining
        let still_alive = is_le(damage, unpacked_beast.Health);

        // if adventurer is still alive
        if (still_alive == TRUE) {
            // set new health to previous health - damage dealt
            let (updated_beast: Beast) = cast_state(
                BeastSlotIds.Health, unpacked_beast.Health - damage, unpacked_beast
            );
        } else {
            // if damage dealt exceeds health remaining, set health to 0
            let (updated_beast: Beast) = cast_state(BeastSlotIds.Health, 0, unpacked_beast);
        }

        return (updated_beast,);
    }
}
