%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc
from starkware.cairo.common.uint256 import uint256_eq

from contracts.settling_game.utils.general import unpack_data

from contracts.loot.constants.adventurer import Adventurer
from contracts.loot.constants.beast import (
    Beast, 
    BeastStatic, 
    BeastDynamic, 
    SHIFT_P, 
    BeastSlotIds
)
from contracts.loot.beast.stats.beast import BeastStats

namespace BeastLib {

    func create{syscall_ptr: felt*, range_check_ptr}(xoroshiro_random: felt, adventurer_id: felt) -> (beast_static: BeastStatic, beast_dynamic: BeastDynamic) {

        let (_, r) = unsigned_div_rem(xoroshiro_random, 17);
        let beast_id = r + 1;

        let BeastId = beast_id;
        let Health = 100;
        let (Type) = BeastStats.get_type_from_id(beast_id);
        let (Rank) = BeastStats.get_rank_from_id(beast_id);
        let Prefix_1 = 0;
        let Prefix_2 = 0;
        let Adventurer = adventurer_id;
        let XP = 0;
        let SlainBy = 0;
        let SlainOnDate = 0;

        return (
            BeastStatic(
                Id=BeastId,
                Type=Type,
                Prefix_1=Prefix_1,
                Prefix_2=Prefix_2,
                SlainBy=SlainBy,
                SlainOnDate=SlainOnDate,
            ),
            BeastDynamic(
                Health=Health,
                Rank=Rank,
                Adventurer=Adventurer,
                XP=XP
            )
        );
    }

    func pack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(unpacked_beast: BeastDynamic) -> (packed_beast: felt) {
        let Health = unpacked_beast.Health * SHIFT_P._1;
        let Rank = unpacked_beast.Rank * SHIFT_P._2;
        let Adventurer = unpacked_beast.Adventurer * SHIFT_P._3;
        let XP = unpacked_beast.XP * SHIFT_P._4;
        

        let packed_beast = Health + Rank + Adventurer + XP;

        return (packed_beast,);
    }

    func unpack{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(packed_beast: felt) -> (packed_beast: BeastDynamic) {
        alloc_locals;
        let (Health) = unpack_data(packed_beast, 0, 1023);
        let (Rank) = unpack_data(packed_beast, 10, 7);
        let (Adventurer) = unpack_data(packed_beast, 13, 2199023255551);
        let (XP) = unpack_data(packed_beast, 54, 134217727);

        return (
            BeastDynamic(
                Health,
                Rank,
                Adventurer,
                XP,
            ),
        );
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

    func calculate_greatness{syscall_ptr: felt*, range_check_ptr}(xp: felt) -> (greatness: felt) {

        let (greatness, _) = unsigned_div_rem(xp, 1000);

        return (greatness,);
    }
}
