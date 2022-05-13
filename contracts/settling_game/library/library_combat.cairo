%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_zero, assert_le, split_int, unsigned_div_rem
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset

from contracts.settling_game.utils.game_structs import (
    Squad,
    PackedSquad,
    SquadStats,
    Troop,
    TroopType,
    TroopId,
)

# used for packing
const SHIFT = 0x100

namespace COMBAT:
    func compute_squad_stats(s : Squad) -> (stats : SquadStats):
        let agility = s.t1_1.agility + s.t1_2.agility + s.t1_3.agility + s.t1_4.agility +
            s.t1_5.agility + s.t1_6.agility + s.t1_7.agility + s.t1_8.agility + s.t1_9.agility +
            s.t1_10.agility + s.t1_11.agility + s.t1_12.agility + s.t1_13.agility + s.t1_14.agility +
            s.t1_15.agility + s.t1_16.agility + s.t2_1.agility + s.t2_2.agility + s.t2_3.agility +
            s.t2_4.agility + s.t2_5.agility + s.t2_6.agility + s.t2_7.agility + s.t2_8.agility +
            s.t3_1.agility

        let attack = s.t1_1.attack + s.t1_2.attack + s.t1_3.attack + s.t1_4.attack +
            s.t1_5.attack + s.t1_6.attack + s.t1_7.attack + s.t1_8.attack + s.t1_9.attack +
            s.t1_10.attack + s.t1_11.attack + s.t1_12.attack + s.t1_13.attack + s.t1_14.attack +
            s.t1_15.attack + s.t1_16.attack + s.t2_1.attack + s.t2_2.attack + s.t2_3.attack +
            s.t2_4.attack + s.t2_5.attack + s.t2_6.attack + s.t2_7.attack + s.t2_8.attack +
            s.t3_1.attack

        let defense = s.t1_1.defense + s.t1_2.defense + s.t1_3.defense + s.t1_4.defense +
            s.t1_5.defense + s.t1_6.defense + s.t1_7.defense + s.t1_8.defense + s.t1_9.defense +
            s.t1_10.defense + s.t1_11.defense + s.t1_12.defense + s.t1_13.defense + s.t1_14.defense +
            s.t1_15.defense + s.t1_16.defense + s.t2_1.defense + s.t2_2.defense + s.t2_3.defense +
            s.t2_4.defense + s.t2_5.defense + s.t2_6.defense + s.t2_7.defense + s.t2_8.defense +
            s.t3_1.defense

        let vitality = s.t1_1.vitality + s.t1_2.vitality + s.t1_3.vitality + s.t1_4.vitality +
            s.t1_5.vitality + s.t1_6.vitality + s.t1_7.vitality + s.t1_8.vitality + s.t1_9.vitality +
            s.t1_10.vitality + s.t1_11.vitality + s.t1_12.vitality + s.t1_13.vitality + s.t1_14.vitality +
            s.t1_15.vitality + s.t1_16.vitality + s.t2_1.vitality + s.t2_2.vitality + s.t2_3.vitality +
            s.t2_4.vitality + s.t2_5.vitality + s.t2_6.vitality + s.t2_7.vitality + s.t2_8.vitality +
            s.t3_1.vitality

        let wisdom = s.t1_1.wisdom + s.t1_2.wisdom + s.t1_3.wisdom + s.t1_4.wisdom +
            s.t1_5.wisdom + s.t1_6.wisdom + s.t1_7.wisdom + s.t1_8.wisdom + s.t1_9.wisdom +
            s.t1_10.wisdom + s.t1_11.wisdom + s.t1_12.wisdom + s.t1_13.wisdom + s.t1_14.wisdom +
            s.t1_15.wisdom + s.t1_16.wisdom + s.t2_1.wisdom + s.t2_2.wisdom + s.t2_3.wisdom +
            s.t2_4.wisdom + s.t2_5.wisdom + s.t2_6.wisdom + s.t2_7.wisdom + s.t2_8.wisdom +
            s.t3_1.wisdom

        return (
            SquadStats(agility=agility, attack=attack, defense=defense, vitality=vitality, wisdom=wisdom),
        )
    end

    func pack_squad{range_check_ptr}(s : Squad) -> (p : PackedSquad):
        alloc_locals

        # p1
        let (pt1_1) = pack_troop(s.t1_1)
        let (pt1_2) = pack_troop(s.t1_2)
        let (pt1_3) = pack_troop(s.t1_3)
        let (pt1_4) = pack_troop(s.t1_4)
        let p1 = pt1_1 + (pt1_2 * (SHIFT ** 7)) + (pt1_3 * (SHIFT ** 14)) + (pt1_4 * (SHIFT ** 21))

        # p2
        let (pt1_5) = pack_troop(s.t1_5)
        let (pt1_6) = pack_troop(s.t1_6)
        let (pt1_7) = pack_troop(s.t1_7)
        let (pt1_8) = pack_troop(s.t1_8)
        let p2 = pt1_5 + (pt1_6 * (SHIFT ** 7)) + (pt1_7 * (SHIFT ** 14)) + (pt1_8 * (SHIFT ** 21))

        # p3
        let (pt1_9) = pack_troop(s.t1_9)
        let (pt1_10) = pack_troop(s.t1_10)
        let (pt1_11) = pack_troop(s.t1_11)
        let (pt1_12) = pack_troop(s.t1_12)
        let p3 = pt1_9 + (pt1_10 * (SHIFT ** 7)) + (pt1_11 * (SHIFT ** 14)) + (pt1_12 * (SHIFT ** 21))

        # p4
        let (pt1_13) = pack_troop(s.t1_13)
        let (pt1_14) = pack_troop(s.t1_14)
        let (pt1_15) = pack_troop(s.t1_15)
        let (pt1_16) = pack_troop(s.t1_16)
        let p4 = pt1_13 + (pt1_14 * (SHIFT ** 7)) + (pt1_15 * (SHIFT ** 14)) + (pt1_16 * (SHIFT ** 21))

        # p5
        let (pt2_1) = pack_troop(s.t2_1)
        let (pt2_2) = pack_troop(s.t2_2)
        let (pt2_3) = pack_troop(s.t2_3)
        let (pt2_4) = pack_troop(s.t2_4)
        let p5 = pt2_1 + (pt2_2 * (SHIFT ** 7)) + (pt2_3 * (SHIFT ** 14)) + (pt2_4 * (SHIFT ** 21))

        # p6
        let (pt2_5) = pack_troop(s.t2_5)
        let (pt2_6) = pack_troop(s.t2_6)
        let (pt2_7) = pack_troop(s.t2_7)
        let (pt2_8) = pack_troop(s.t2_8)
        let p6 = pt2_5 + (pt2_6 * (SHIFT ** 7)) + (pt2_7 * (SHIFT ** 14)) + (pt2_8 * (SHIFT ** 21))

        # p7
        let (p7) = pack_troop(s.t3_1)

        return (PackedSquad(p1=p1, p2=p2, p3=p3, p4=p4, p5=p5, p6=p6, p7=p7))
    end

    func unpack_squad{range_check_ptr}(p : PackedSquad) -> (s : Squad):
        alloc_locals

        # can't use unsigned_div_rem to do unpacking because
        # the values are above 2**128 so a bound check would fail
        # instead using split_int to slice the felt to parts;
        # using 2**56 bound because a Troop is 7 bytes => 2 ** (8 * 7)

        let (p1_out : felt*) = alloc()
        split_int(p.p1, 4, SHIFT ** 7, 2 ** 56, p1_out)
        let (p2_out : felt*) = alloc()
        split_int(p.p2, 4, SHIFT ** 7, 2 ** 56, p2_out)
        let (p3_out : felt*) = alloc()
        split_int(p.p3, 4, SHIFT ** 7, 2 ** 56, p3_out)
        let (p4_out : felt*) = alloc()
        split_int(p.p4, 4, SHIFT ** 7, 2 ** 56, p4_out)
        let (p5_out : felt*) = alloc()
        split_int(p.p5, 4, SHIFT ** 7, 2 ** 56, p5_out)
        let (p6_out : felt*) = alloc()
        split_int(p.p6, 4, SHIFT ** 7, 2 ** 56, p6_out)

        let (t1_1) = unpack_troop([p1_out])
        let (t1_2) = unpack_troop([p1_out + 1])
        let (t1_3) = unpack_troop([p1_out + 2])
        let (t1_4) = unpack_troop([p1_out + 3])
        let (t1_5) = unpack_troop([p2_out])
        let (t1_6) = unpack_troop([p2_out + 1])
        let (t1_7) = unpack_troop([p2_out + 2])
        let (t1_8) = unpack_troop([p2_out + 3])
        let (t1_9) = unpack_troop([p3_out])
        let (t1_10) = unpack_troop([p3_out + 1])
        let (t1_11) = unpack_troop([p3_out + 2])
        let (t1_12) = unpack_troop([p3_out + 3])
        let (t1_13) = unpack_troop([p4_out])
        let (t1_14) = unpack_troop([p4_out + 1])
        let (t1_15) = unpack_troop([p4_out + 2])
        let (t1_16) = unpack_troop([p4_out + 3])

        let (t2_1) = unpack_troop([p5_out])
        let (t2_2) = unpack_troop([p5_out + 1])
        let (t2_3) = unpack_troop([p5_out + 2])
        let (t2_4) = unpack_troop([p5_out + 3])
        let (t2_5) = unpack_troop([p6_out])
        let (t2_6) = unpack_troop([p6_out + 1])
        let (t2_7) = unpack_troop([p6_out + 2])
        let (t2_8) = unpack_troop([p6_out + 3])

        let (t3_1) = unpack_troop(p.p7)

        return (
            Squad(t1_1=t1_1, t1_2=t1_2, t1_3=t1_3, t1_4=t1_4, t1_5=t1_5, t1_6=t1_6,
            t1_7=t1_7, t1_8=t1_8, t1_9=t1_9, t1_10=t1_10, t1_11=t1_11, t1_12=t1_12,
            t1_13=t1_13, t1_14=t1_14, t1_15=t1_15, t1_16=t1_16, t2_1=t2_1, t2_2=t2_2,
            t2_3=t2_3, t2_4=t2_4, t2_5=t2_5, t2_6=t2_6, t2_7=t2_7, t2_8=t2_8, t3_1=t3_1),
        )
    end

    func pack_troop{range_check_ptr}(t : Troop) -> (packed : felt):
        alloc_locals

        assert_le(t.type, 3)
        assert_le(t.tier, 255)
        assert_le(t.agility, 255)
        assert_le(t.attack, 255)
        assert_le(t.defense, 255)
        assert_le(t.vitality, 255)
        assert_le(t.wisdom, 255)

        # TODO: mention limitations of this approach
        #       short comment about how it works

        tempvar r = t.type  # no need to shift type
        tempvar tier_shifted = t.tier * SHIFT
        tempvar r = r + tier_shifted
        tempvar agility_shifted = t.agility * (SHIFT ** 2)
        tempvar r = r + agility_shifted
        tempvar attack_shifted = t.attack * (SHIFT ** 3)
        tempvar r = r + attack_shifted
        tempvar defense_shifted = t.defense * (SHIFT ** 4)
        tempvar r = r + defense_shifted
        tempvar vitality_shifted = t.vitality * (SHIFT ** 5)
        tempvar r = r + vitality_shifted
        tempvar wisdom_shifted = t.wisdom * (SHIFT ** 6)
        tempvar r = r + wisdom_shifted

        return (r)
    end

    func unpack_troop{range_check_ptr}(packed : felt) -> (t : Troop):
        let (r0, type) = unsigned_div_rem(packed, SHIFT)
        let (r1, tier) = unsigned_div_rem(r0, SHIFT)
        let (r2, agility) = unsigned_div_rem(r1, SHIFT)
        let (r3, attack) = unsigned_div_rem(r2, SHIFT)
        let (r4, defense) = unsigned_div_rem(r3, SHIFT)
        let (wisdom, vitality) = unsigned_div_rem(r4, SHIFT)

        return (
            Troop(type=type, tier=tier, agility=agility, attack=attack, defense=defense, vitality=vitality, wisdom=wisdom),
        )
    end

    func get_troop_internal{range_check_ptr}(troop_id : felt) -> (t : Troop):
        with_attr error_message("unknown troop ID"):
            assert_not_zero(troop_id)
            assert_le(troop_id, TroopId.GrandMarshal)
        end

        if troop_id == TroopId.Watchman:
            return (
                Troop(type=TroopType.Melee, tier=1, agility=1, attack=1, defense=3, vitality=4, wisdom=1),
            )
        end

        if troop_id == TroopId.Guard:
            return (
                Troop(type=TroopType.Melee, tier=2, agility=2, attack=2, defense=6, vitality=8, wisdom=2),
            )
        end

        if troop_id == TroopId.GuardCaptain:
            return (
                Troop(type=TroopType.Melee, tier=3, agility=4, attack=4, defense=12, vitality=16, wisdom=4),
            )
        end

        if troop_id == TroopId.Squire:
            return (
                Troop(type=TroopType.Melee, tier=1, agility=1, attack=4, defense=1, vitality=1, wisdom=3),
            )
        end

        if troop_id == TroopId.Knight:
            return (
                Troop(type=TroopType.Melee, tier=2, agility=2, attack=8, defense=2, vitality=2, wisdom=6),
            )
        end

        if troop_id == TroopId.KnightCommander:
            return (
                Troop(type=TroopType.Melee, tier=3, agility=4, attack=16, defense=4, vitality=4, wisdom=12),
            )
        end

        if troop_id == TroopId.Scout:
            return (
                Troop(type=TroopType.Ranged, tier=1, agility=4, attack=3, defense=1, vitality=1, wisdom=1),
            )
        end

        if troop_id == TroopId.Archer:
            return (
                Troop(type=TroopType.Ranged, tier=2, agility=8, attack=6, defense=2, vitality=2, wisdom=2),
            )
        end

        if troop_id == TroopId.Sniper:
            return (
                Troop(type=TroopType.Ranged, tier=3, agility=16, attack=12, defense=4, vitality=4, wisdom=4),
            )
        end

        if troop_id == TroopId.Scorpio:
            return (
                Troop(type=TroopType.Siege, tier=1, agility=1, attack=4, defense=1, vitality=3, wisdom=1),
            )
        end

        if troop_id == TroopId.Ballista:
            return (
                Troop(type=TroopType.Siege, tier=2, agility=2, attack=8, defense=2, vitality=6, wisdom=2),
            )
        end

        if troop_id == TroopId.Catapult:
            return (
                Troop(type=TroopType.Siege, tier=3, agility=4, attack=16, defense=4, vitality=12, wisdom=4),
            )
        end

        if troop_id == TroopId.Apprentice:
            return (
                Troop(type=TroopType.Ranged, tier=1, agility=2, attack=2, defense=1, vitality=1, wisdom=4),
            )
        end

        if troop_id == TroopId.Mage:
            return (
                Troop(type=TroopType.Ranged, tier=2, agility=4, attack=4, defense=2, vitality=2, wisdom=8),
            )
        end

        if troop_id == TroopId.Arcanist:
            return (
                Troop(type=TroopType.Ranged, tier=3, agility=8, attack=8, defense=4, vitality=4, wisdom=16),
            )
        end

        if troop_id == TroopId.GrandMarshal:
            return (
                Troop(type=TroopType.Melee, tier=3, agility=16, attack=16, defense=16, vitality=16, wisdom=16),
            )
        end

        # shouldn't ever happen thanks to the asserts at the beginning
        return (Troop(type=0, tier=0, agility=0, attack=0, defense=0, vitality=0, wisdom=0))
    end

    func add_troop_to_squad(t : Troop, s : Squad) -> (updated : Squad):
        alloc_locals

        let (free_slot) = find_first_free_troop_slot_in_squad(s, t.tier)
        let (sarr_len, sarr) = squad_to_array(s)
        let (_, tarr) = troop_to_array(t)

        let (a) = alloc()
        memcpy(a, sarr, free_slot)
        memcpy(a + free_slot, tarr, Troop.SIZE)
        memcpy(
            a + free_slot + Troop.SIZE,
            sarr + free_slot + Troop.SIZE,
            Squad.SIZE - free_slot - Troop.SIZE,
        )
        let (updated) = array_to_squad(sarr_len, a)

        return (updated)
    end

    func remove_troop_from_squad(troop_idx : felt, s : Squad) -> (updated : Squad):
        alloc_locals

        let (sarr_len, sarr) = squad_to_array(s)
        let (a) = alloc()
        memcpy(a, sarr, troop_idx * Troop.SIZE)
        memset(a + troop_idx * Troop.SIZE, 0, Troop.SIZE)
        memcpy(a + (troop_idx + 1) * Troop.SIZE, sarr, Squad.SIZE - (troop_idx + 1) * Troop.SIZE)
        let (updated) = array_to_squad(sarr_len, a)

        return (updated)
    end

    func find_first_free_troop_slot_in_squad(s : Squad, tier : felt) -> (free_slot_index : felt):
        # type == 0 just means the slot is free (0 is the default, if no Troop was assigned there, it's going to be 0)
        if tier == 1:
            if s.t1_1.type == 0:
                return (0)
            end
            if s.t1_2.type == 0:
                return (Troop.SIZE)
            end
            if s.t1_3.type == 0:
                return (Troop.SIZE * 2)
            end
            if s.t1_4.type == 0:
                return (Troop.SIZE * 3)
            end
            if s.t1_5.type == 0:
                return (Troop.SIZE * 4)
            end
            if s.t1_6.type == 0:
                return (Troop.SIZE * 5)
            end
            if s.t1_7.type == 0:
                return (Troop.SIZE * 6)
            end
            if s.t1_8.type == 0:
                return (Troop.SIZE * 7)
            end
            if s.t1_9.type == 0:
                return (Troop.SIZE * 8)
            end
            if s.t1_10.type == 0:
                return (Troop.SIZE * 9)
            end
            if s.t1_11.type == 0:
                return (Troop.SIZE * 10)
            end
            if s.t1_12.type == 0:
                return (Troop.SIZE * 11)
            end
            if s.t1_13.type == 0:
                return (Troop.SIZE * 12)
            end
            if s.t1_14.type == 0:
                return (Troop.SIZE * 13)
            end
            if s.t1_15.type == 0:
                return (Troop.SIZE * 14)
            end
            if s.t1_16.type == 0:
                return (Troop.SIZE * 15)
            end
        end

        if tier == 2:
            if s.t2_1.type == 0:
                return (Troop.SIZE * 16)
            end
            if s.t2_2.type == 0:
                return (Troop.SIZE * 17)
            end
            if s.t2_3.type == 0:
                return (Troop.SIZE * 18)
            end
            if s.t2_4.type == 0:
                return (Troop.SIZE * 19)
            end
            if s.t2_5.type == 0:
                return (Troop.SIZE * 20)
            end
            if s.t2_6.type == 0:
                return (Troop.SIZE * 21)
            end
            if s.t2_7.type == 0:
                return (Troop.SIZE * 22)
            end
            if s.t2_8.type == 0:
                return (Troop.SIZE * 23)
            end
        end

        if tier == 3:
            if s.t3_1.type == 0:
                return (Troop.SIZE * 24)
            end
        end

        with_attr error_message("no free troop slot in squad"):
            assert 1 = 0
        end

        return (0)
    end

    func squad_to_array(s : Squad) -> (a_len : felt, a : felt*):
        alloc_locals
        let (a) = alloc()

        # tier 1
        let (len, t1_1) = troop_to_array(s.t1_1)
        memcpy(a, t1_1, len)
        let (len, t1_2) = troop_to_array(s.t1_2)
        memcpy(a + Troop.SIZE, t1_2, len)
        let (len, t1_3) = troop_to_array(s.t1_3)
        memcpy(a + Troop.SIZE * 2, t1_3, len)
        let (len, t1_4) = troop_to_array(s.t1_4)
        memcpy(a + Troop.SIZE * 3, t1_4, len)
        let (len, t1_5) = troop_to_array(s.t1_5)
        memcpy(a + Troop.SIZE * 4, t1_5, len)
        let (len, t1_6) = troop_to_array(s.t1_6)
        memcpy(a + Troop.SIZE * 5, t1_6, len)
        let (len, t1_7) = troop_to_array(s.t1_7)
        memcpy(a + Troop.SIZE * 6, t1_7, len)
        let (len, t1_8) = troop_to_array(s.t1_8)
        memcpy(a + Troop.SIZE * 7, t1_8, len)
        let (len, t1_9) = troop_to_array(s.t1_9)
        memcpy(a + Troop.SIZE * 8, t1_9, len)
        let (len, t1_10) = troop_to_array(s.t1_10)
        memcpy(a + Troop.SIZE * 9, t1_10, len)
        let (len, t1_11) = troop_to_array(s.t1_11)
        memcpy(a + Troop.SIZE * 10, t1_11, len)
        let (len, t1_12) = troop_to_array(s.t1_12)
        memcpy(a + Troop.SIZE * 11, t1_12, len)
        let (len, t1_13) = troop_to_array(s.t1_13)
        memcpy(a + Troop.SIZE * 12, t1_13, len)
        let (len, t1_14) = troop_to_array(s.t1_14)
        memcpy(a + Troop.SIZE * 13, t1_14, len)
        let (len, t1_15) = troop_to_array(s.t1_15)
        memcpy(a + Troop.SIZE * 14, t1_15, len)
        let (len, t1_16) = troop_to_array(s.t1_16)
        memcpy(a + Troop.SIZE * 15, t1_16, len)

        # tier 2
        let (len, t2_1) = troop_to_array(s.t2_1)
        memcpy(a + Troop.SIZE * 16, t2_1, len)
        let (len, t2_2) = troop_to_array(s.t2_2)
        memcpy(a + Troop.SIZE * 17, t2_2, len)
        let (len, t2_3) = troop_to_array(s.t2_3)
        memcpy(a + Troop.SIZE * 18, t2_3, len)
        let (len, t2_4) = troop_to_array(s.t2_4)
        memcpy(a + Troop.SIZE * 19, t2_4, len)
        let (len, t2_5) = troop_to_array(s.t2_5)
        memcpy(a + Troop.SIZE * 20, t2_5, len)
        let (len, t2_6) = troop_to_array(s.t2_6)
        memcpy(a + Troop.SIZE * 21, t2_6, len)
        let (len, t2_7) = troop_to_array(s.t2_7)
        memcpy(a + Troop.SIZE * 22, t2_7, len)
        let (len, t2_8) = troop_to_array(s.t2_8)
        memcpy(a + Troop.SIZE * 23, t2_8, len)

        # tier 3
        let (len, t3_1) = troop_to_array(s.t3_1)
        memcpy(a + Troop.SIZE * 24, t3_1, len)

        return (Troop.SIZE * 25, a)
    end

    func troop_to_array(t : Troop) -> (a_len : felt, a : felt*):
        let (a) = alloc()
        assert [a] = t.type
        assert [a + 1] = t.tier
        assert [a + 2] = t.agility
        assert [a + 3] = t.attack
        assert [a + 4] = t.defense
        assert [a + 5] = t.vitality
        assert [a + 6] = t.wisdom
        return (Troop.SIZE, a)
    end

    func array_to_squad(a_len : felt, a : felt*) -> (s : Squad):
        alloc_locals

        let (t1_1) = array_to_troop(Troop.SIZE, a)
        let (t1_2) = array_to_troop(Troop.SIZE, a + Troop.SIZE)
        let (t1_3) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 2)
        let (t1_4) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 3)
        let (t1_5) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 4)
        let (t1_6) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 5)
        let (t1_7) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 6)
        let (t1_8) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 7)
        let (t1_9) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 8)
        let (t1_10) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 9)
        let (t1_11) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 10)
        let (t1_12) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 11)
        let (t1_13) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 12)
        let (t1_14) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 13)
        let (t1_15) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 14)
        let (t1_16) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 15)

        let (t2_1) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 16)
        let (t2_2) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 17)
        let (t2_3) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 18)
        let (t2_4) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 19)
        let (t2_5) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 20)
        let (t2_6) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 21)
        let (t2_7) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 22)
        let (t2_8) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 23)

        let (t3_1) = array_to_troop(Troop.SIZE, a + Troop.SIZE * 24)

        return (
            Squad(t1_1=t1_1, t1_2=t1_2, t1_3=t1_3, t1_4=t1_4, t1_5=t1_5, t1_6=t1_6,
            t1_7=t1_7, t1_8=t1_8, t1_9=t1_9, t1_10=t1_10, t1_11=t1_11, t1_12=t1_12,
            t1_13=t1_13, t1_14=t1_14, t1_15=t1_15, t1_16=t1_16, t2_1=t2_1, t2_2=t2_2,
            t2_3=t2_3, t2_4=t2_4, t2_5=t2_5, t2_6=t2_6, t2_7=t2_7, t2_8=t2_8, t3_1=t3_1),
        )
    end

    func array_to_troop(a_len : felt, a : felt*) -> (t : Troop):
        return (
            Troop(type=[a], tier=[a + 1], agility=[a + 2], attack=[a + 3], defense=[a + 4], vitality=[a + 5], wisdom=[a + 6]),
        )
    end

    func build_squad_from_troops{range_check_ptr}(troop_ids_len : felt, troop_ids : felt*) -> (
        squad : Squad
    ):
        alloc_locals
        let (empty : Squad) = build_empty_squad()
        let (full : Squad) = build_squad_from_troops_loop(empty, troop_ids_len, troop_ids)
        return (full)
    end

    func build_squad_from_troops_loop{range_check_ptr}(
        current : Squad, troop_ids_len : felt, troop_ids : felt*
    ) -> (squad : Squad):
        alloc_locals

        if troop_ids_len == 0:
            return (current)
        end

        let (troop : Troop) = get_troop_internal([troop_ids])
        let (updated : Squad) = add_troop_to_squad(troop, current)

        return build_squad_from_troops_loop(updated, troop_ids_len - 1, troop_ids + 1)
    end

    func build_empty_squad() -> (s : Squad):
        return (
            Squad(
            t1_1=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_2=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_3=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_4=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_5=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_6=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_7=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_8=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_9=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_10=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_11=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_12=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_13=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_14=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_15=Troop(0, 0, 0, 0, 0, 0, 0),
            t1_16=Troop(0, 0, 0, 0, 0, 0, 0),
            t2_1=Troop(0, 0, 0, 0, 0, 0, 0),
            t2_2=Troop(0, 0, 0, 0, 0, 0, 0),
            t2_3=Troop(0, 0, 0, 0, 0, 0, 0),
            t2_4=Troop(0, 0, 0, 0, 0, 0, 0),
            t2_5=Troop(0, 0, 0, 0, 0, 0, 0),
            t2_6=Troop(0, 0, 0, 0, 0, 0, 0),
            t2_7=Troop(0, 0, 0, 0, 0, 0, 0),
            t2_8=Troop(0, 0, 0, 0, 0, 0, 0),
            t3_1=Troop(0, 0, 0, 0, 0, 0, 0)),
        )
    end

    func get_troop_population{range_check_ptr}(squad : PackedSquad) -> (population : felt):
        alloc_locals

        let (s : Squad) = unpack_squad(squad)

        let population = s.t1_1.tier + s.t1_2.tier + s.t1_3.tier + s.t1_4.tier +
            s.t1_5.tier + s.t1_6.tier + s.t1_7.tier + s.t1_8.tier + s.t1_9.tier +
            s.t1_10.tier + s.t1_11.tier + s.t1_12.tier + s.t1_13.tier + s.t1_14.tier +
            s.t1_15.tier + s.t1_16.tier + (s.t2_1.tier / 2) + (s.t2_2.tier / 2) + (s.t2_3.tier / 2) +
            (s.t2_4.tier / 2) + (s.t2_5.tier / 2) + (s.t2_6.tier / 2) + (s.t2_7.tier / 2) + (s.t2_8.tier / 2) +
            (s.t3_1.tier / 3)

        return (population=population)
    end
end