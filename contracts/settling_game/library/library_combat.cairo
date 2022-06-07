%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_le,
    assert_lt,
    split_int,
    unsigned_div_rem,
)
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc

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

    func compute_squad_vitality(s : Squad) -> (vitality : felt):
        let vitality = s.t1_1.vitality + s.t1_2.vitality + s.t1_3.vitality + s.t1_4.vitality +
            s.t1_5.vitality + s.t1_6.vitality + s.t1_7.vitality + s.t1_8.vitality + s.t1_9.vitality +
            s.t1_10.vitality + s.t1_11.vitality + s.t1_12.vitality + s.t1_13.vitality + s.t1_14.vitality +
            s.t1_15.vitality + s.t1_16.vitality + s.t2_1.vitality + s.t2_2.vitality + s.t2_3.vitality +
            s.t2_4.vitality + s.t2_5.vitality + s.t2_6.vitality + s.t2_7.vitality + s.t2_8.vitality +
            s.t3_1.vitality
        return (vitality)
    end

    func pack_squad{range_check_ptr}(s : Squad) -> (p : PackedSquad):
        alloc_locals

        # p1
        let (pt1_1) = pack_troop(s.t1_1)
        let (pt1_2) = pack_troop(s.t1_2)
        let (pt1_3) = pack_troop(s.t1_3)
        let (pt1_4) = pack_troop(s.t1_4)
        let (pt1_5) = pack_troop(s.t1_5)
        let (pt1_6) = pack_troop(s.t1_6)
        let (pt1_7) = pack_troop(s.t1_7)
        let (pt1_8) = pack_troop(s.t1_8)
        let (pt1_9) = pack_troop(s.t1_9)
        let (pt1_10) = pack_troop(s.t1_10)
        let (pt1_11) = pack_troop(s.t1_11)
        let (pt1_12) = pack_troop(s.t1_12)
        let (pt1_13) = pack_troop(s.t1_13)
        let (pt1_14) = pack_troop(s.t1_14)
        let (pt1_15) = pack_troop(s.t1_15)

        let p1 = (
            pt1_1 +
            (pt1_2 * (SHIFT ** 2)) +
            (pt1_3 * (SHIFT ** 4)) +
            (pt1_4 * (SHIFT ** 6)) +
            (pt1_5 * (SHIFT ** 8)) +
            (pt1_6 * (SHIFT ** 10)) +
            (pt1_7 * (SHIFT ** 12)) +
            (pt1_8 * (SHIFT ** 14)) +
            (pt1_9 * (SHIFT ** 16)) +
            (pt1_10 * (SHIFT ** 18)) +
            (pt1_11 * (SHIFT ** 20)) +
            (pt1_12 * (SHIFT ** 22)) +
            (pt1_13 * (SHIFT ** 24)) +
            (pt1_14 * (SHIFT ** 26)) +
            (pt1_15 * (SHIFT ** 28)))

        # p2
        let (pt1_16) = pack_troop(s.t1_16)
        let (pt2_1) = pack_troop(s.t2_1)
        let (pt2_2) = pack_troop(s.t2_2)
        let (pt2_3) = pack_troop(s.t2_3)
        let (pt2_4) = pack_troop(s.t2_4)
        let (pt2_5) = pack_troop(s.t2_5)
        let (pt2_6) = pack_troop(s.t2_6)
        let (pt2_7) = pack_troop(s.t2_7)
        let (pt2_8) = pack_troop(s.t2_8)
        let (pt3_1) = pack_troop(s.t3_1)

        let p2 = (
            pt1_16 +
            (pt2_1 * (SHIFT ** 2)) +
            (pt2_2 * (SHIFT ** 4)) +
            (pt2_3 * (SHIFT ** 6)) +
            (pt2_4 * (SHIFT ** 8)) +
            (pt2_5 * (SHIFT ** 10)) +
            (pt2_6 * (SHIFT ** 12)) +
            (pt2_7 * (SHIFT ** 14)) +
            (pt2_8 * (SHIFT ** 16)) +
            (pt3_1 * (SHIFT ** 18)))

        return (PackedSquad(p1=p1, p2=p2))
    end

    func unpack_squad{range_check_ptr}(p : PackedSquad) -> (s : Squad):
        alloc_locals

        let (p1_out : felt*) = alloc()
        split_int(p.p1, 15, SHIFT ** 2, 2 ** 16, p1_out)
        let (p2_out : felt*) = alloc()
        split_int(p.p2, 15, SHIFT ** 2, 2 ** 16, p2_out)

        let (t1_1) = unpack_troop([p1_out])
        let (t1_2) = unpack_troop([p1_out + 1])
        let (t1_3) = unpack_troop([p1_out + 2])
        let (t1_4) = unpack_troop([p1_out + 3])
        let (t1_5) = unpack_troop([p1_out + 4])
        let (t1_6) = unpack_troop([p1_out + 5])
        let (t1_7) = unpack_troop([p1_out + 6])
        let (t1_8) = unpack_troop([p1_out + 7])
        let (t1_9) = unpack_troop([p1_out + 8])
        let (t1_10) = unpack_troop([p1_out + 9])
        let (t1_11) = unpack_troop([p1_out + 10])
        let (t1_12) = unpack_troop([p1_out + 11])
        let (t1_13) = unpack_troop([p1_out + 12])
        let (t1_14) = unpack_troop([p1_out + 13])
        let (t1_15) = unpack_troop([p1_out + 14])

        let (t1_16) = unpack_troop([p2_out])
        let (t2_1) = unpack_troop([p2_out + 1])
        let (t2_2) = unpack_troop([p2_out + 2])
        let (t2_3) = unpack_troop([p2_out + 3])
        let (t2_4) = unpack_troop([p2_out + 4])
        let (t2_5) = unpack_troop([p2_out + 5])
        let (t2_6) = unpack_troop([p2_out + 6])
        let (t2_7) = unpack_troop([p2_out + 7])
        let (t2_8) = unpack_troop([p2_out + 8])
        let (t3_1) = unpack_troop([p2_out + 9])

        return (
            Squad(t1_1=t1_1, t1_2=t1_2, t1_3=t1_3, t1_4=t1_4, t1_5=t1_5, t1_6=t1_6,
            t1_7=t1_7, t1_8=t1_8, t1_9=t1_9, t1_10=t1_10, t1_11=t1_11, t1_12=t1_12,
            t1_13=t1_13, t1_14=t1_14, t1_15=t1_15, t1_16=t1_16, t2_1=t2_1, t2_2=t2_2,
            t2_3=t2_3, t2_4=t2_4, t2_5=t2_5, t2_6=t2_6, t2_7=t2_7, t2_8=t2_8, t3_1=t3_1),
        )
    end

    func pack_troop{range_check_ptr}(t : Troop) -> (packed : felt):
        assert_lt(t.id, TroopId.SIZE)
        assert_le(t.vitality, 255)
        let packed = t.id + t.vitality * SHIFT
        return (packed)
    end

    func unpack_troop{range_check_ptr}(packed : felt) -> (t : Troop):
        alloc_locals
        let (vitality, troop_id) = unsigned_div_rem(packed, SHIFT)
        if troop_id == 0:
            return (
                Troop(id=0, type=0, tier=0, agility=0, attack=0, defense=0, vitality=0, wisdom=0)
            )
        end
        let (type, tier, agility, attack, defense, _, wisdom) = get_troop_properties(troop_id)

        return (
            Troop(id=troop_id, type=type, tier=tier, agility=agility, attack=attack, defense=defense, vitality=vitality, wisdom=wisdom),
        )
    end

    # the values in the tuple this function returns don't change for a Troop,
    # so we hardcode them in the code and use this function to retrieve them
    # this way, we don't have to store them on-chain which allows for more efficient
    # packing (only troop ID and vitality have to be stored)
    func get_troop_properties{range_check_ptr}(troop_id : felt) -> (
        type, tier, agility, attack, defense, vitality, wisdom
    ):
        assert_not_zero(troop_id)
        assert_lt(troop_id, TroopId.SIZE)

        let idx = troop_id - 1
        let (type_label) = get_label_location(troop_types_per_id)
        let (tier_label) = get_label_location(troop_tier_per_id)
        let (agility_label) = get_label_location(troop_agility_per_id)
        let (attack_label) = get_label_location(troop_attack_per_id)
        let (defense_label) = get_label_location(troop_defense_per_id)
        let (vitality_label) = get_label_location(troop_vitality_per_id)
        let (wisdom_label) = get_label_location(troop_wisdom_per_id)

        return (
            [type_label + idx],
            [tier_label + idx],
            [agility_label + idx],
            [attack_label + idx],
            [defense_label + idx],
            [vitality_label + idx],
            [wisdom_label + idx],
        )

        troop_types_per_id:
        dw TroopType.Melee  # Watchman
        dw TroopType.Melee  # Guard
        dw TroopType.Melee  # Guard Captain
        dw TroopType.Melee  # Squire
        dw TroopType.Melee  # Knight
        dw TroopType.Melee  # Knight Commander
        dw TroopType.Ranged  # Scout
        dw TroopType.Ranged  # Archer
        dw TroopType.Ranged  # Sniper
        dw TroopType.Siege  # Scorpio
        dw TroopType.Siege  # Ballista
        dw TroopType.Siege  # Catapult
        dw TroopType.Ranged  # Apprentice
        dw TroopType.Ranged  # Mage
        dw TroopType.Ranged  # Arcanist
        dw TroopType.Melee  # Grand Marshal

        troop_tier_per_id:
        dw 1  # Watchman
        dw 2  # Guard
        dw 3  # Guard Captain
        dw 1  # Squire
        dw 2  # Knight
        dw 3  # Knight Commander
        dw 1  # Scout
        dw 2  # Archer
        dw 3  # Sniper
        dw 1  # Scorpio
        dw 2  # Ballista
        dw 3  # Catapult
        dw 1  # Apprentice
        dw 2  # Mage
        dw 3  # Arcanist
        dw 3  # Grand Marshal

        troop_agility_per_id:
        dw 1  # Watchman
        dw 2  # Guard
        dw 4  # Guard Captain
        dw 1  # Squire
        dw 2  # Knight
        dw 4  # Knight Commander
        dw 4  # Scout
        dw 8  # Archer
        dw 16  # Sniper
        dw 1  # Scorpio
        dw 2  # Ballista
        dw 4  # Catapult
        dw 2  # Apprentice
        dw 4  # Mage
        dw 8  # Arcanist
        dw 16  # Grand Marshal

        troop_attack_per_id:
        dw 1  # Watchman
        dw 2  # Guard
        dw 4  # Guard Captain
        dw 4  # Squire
        dw 8  # Knight
        dw 16  # Knight Commander
        dw 3  # Scout
        dw 6  # Archer
        dw 12  # Sniper
        dw 4  # Scorpio
        dw 8  # Ballista
        dw 16  # Catapult
        dw 2  # Apprentice
        dw 4  # Mage
        dw 8  # Arcanist
        dw 16  # Grand Marshal

        troop_defense_per_id:
        dw 3  # Watchman
        dw 6  # Guard
        dw 12  # Guard Captain
        dw 1  # Squire
        dw 2  # Knight
        dw 4  # Knight Commander
        dw 1  # Scout
        dw 2  # Archer
        dw 4  # Sniper
        dw 1  # Scorpio
        dw 2  # Ballista
        dw 4  # Catapult
        dw 1  # Apprentice
        dw 2  # Mage
        dw 4  # Arcanist
        dw 16  # Grand Marshal

        troop_vitality_per_id:
        dw 4  # Watchman
        dw 8  # Guard
        dw 16  # Guard Captain
        dw 1  # Squire
        dw 2  # Knight
        dw 4  # Knight Commander
        dw 1  # Scout
        dw 2  # Archer
        dw 4  # Sniper
        dw 3  # Scorpio
        dw 6  # Ballista
        dw 12  # Catapult
        dw 1  # Apprentice
        dw 2  # Mage
        dw 4  # Arcanist
        dw 16  # Grand Marshal

        troop_wisdom_per_id:
        dw 1  # Watchman
        dw 2  # Guard
        dw 4  # Guard Captain
        dw 3  # Squire
        dw 6  # Knight
        dw 12  # Knight Commander
        dw 1  # Scout
        dw 2  # Archer
        dw 4  # Sniper
        dw 1  # Scorpio
        dw 2  # Ballista
        dw 4  # Catapult
        dw 4  # Apprentice
        dw 8  # Mage
        dw 16  # Arcanist
        dw 16  # Grand Marshal
    end

    func get_troop_internal{range_check_ptr}(troop_id : felt) -> (t : Troop):
        with_attr error_message("unknown troop ID"):
            assert_not_zero(troop_id)
            assert_lt(troop_id, TroopId.SIZE)
        end

        let (type, tier, agility, attack, defense, vitality, wisdom) = get_troop_properties(
            troop_id
        )
        return (
            Troop(id=troop_id, type=type, tier=tier, agility=agility, attack=attack, defense=defense, vitality=vitality, wisdom=wisdom),
        )
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

    func remove_troop_from_squad{range_check_ptr}(troop_idx : felt, s : Squad) -> (updated : Squad):
        alloc_locals

        assert_lt(troop_idx, Squad.SIZE / Troop.SIZE)

        let (sarr_len, sarr) = squad_to_array(s)
        let (a) = alloc()
        memcpy(a, sarr, troop_idx * Troop.SIZE)
        memset(a + troop_idx * Troop.SIZE, 0, Troop.SIZE)
        memcpy(
            a + (troop_idx + 1) * Troop.SIZE,
            sarr + (troop_idx + 1) * Troop.SIZE,
            Squad.SIZE - (troop_idx + 1) * Troop.SIZE,
        )
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
        let (fp_val, _) = get_fp_and_pc()
        return (Squad.SIZE, cast(fp_val - 2 - Squad.SIZE, felt*))
    end

    func troop_to_array(t : Troop) -> (a_len : felt, a : felt*):
        let (fp_val, _) = get_fp_and_pc()
        return (Troop.SIZE, cast(fp_val - 2 - Troop.SIZE, felt*))
    end

    func array_to_squad(a_len : felt, a : felt*) -> (s : Squad):
        let squad : Squad* = cast(a, Squad*)
        return ([squad])
    end

    func add_troops_to_squad{range_check_ptr}(
        current : Squad, troop_ids_len : felt, troop_ids : felt*
    ) -> (squad : Squad):
        alloc_locals

        if troop_ids_len == 0:
            return (current)
        end

        let (troop : Troop) = get_troop_internal([troop_ids])
        let (updated : Squad) = add_troop_to_squad(troop, current)

        return add_troops_to_squad(updated, troop_ids_len - 1, troop_ids + 1)
    end

    func remove_troops_from_squad{range_check_ptr}(
        current : Squad, troop_idxs_len : felt, troop_idxs : felt*
    ) -> (squad : Squad):
        alloc_locals

        if troop_idxs_len == 0:
            return (current)
        end

        let (updated : Squad) = remove_troop_from_squad([troop_idxs], current)
        return remove_troops_from_squad(updated, troop_idxs_len - 1, troop_idxs + 1)
    end

    func get_troop_population{range_check_ptr}(squad : PackedSquad) -> (population : felt):
        alloc_locals

        let (s : Squad) = unpack_squad(squad)
        tempvar p = 0
        if s.t1_1.id != 0:
            tempvar p = p + 1
        end
        if s.t1_2.id != 0:
            tempvar p = p + 1
        end
        if s.t1_3.id != 0:
            tempvar p = p + 1
        end
        if s.t1_4.id != 0:
            tempvar p = p + 1
        end
        if s.t1_5.id != 0:
            tempvar p = p + 1
        end
        if s.t1_6.id != 0:
            tempvar p = p + 1
        end
        if s.t1_7.id != 0:
            tempvar p = p + 1
        end
        if s.t1_8.id != 0:
            tempvar p = p + 1
        end
        if s.t1_9.id != 0:
            tempvar p = p + 1
        end
        if s.t1_10.id != 0:
            tempvar p = p + 1
        end
        if s.t1_11.id != 0:
            tempvar p = p + 1
        end
        if s.t1_12.id != 0:
            tempvar p = p + 1
        end
        if s.t1_13.id != 0:
            tempvar p = p + 1
        end
        if s.t1_14.id != 0:
            tempvar p = p + 1
        end
        if s.t1_15.id != 0:
            tempvar p = p + 1
        end
        if s.t1_16.id != 0:
            tempvar p = p + 1
        end
        if s.t2_1.id != 0:
            tempvar p = p + 1
        end
        if s.t2_2.id != 0:
            tempvar p = p + 1
        end
        if s.t2_3.id != 0:
            tempvar p = p + 1
        end
        if s.t2_4.id != 0:
            tempvar p = p + 1
        end
        if s.t2_5.id != 0:
            tempvar p = p + 1
        end
        if s.t2_6.id != 0:
            tempvar p = p + 1
        end
        if s.t2_7.id != 0:
            tempvar p = p + 1
        end
        if s.t2_8.id != 0:
            tempvar p = p + 1
        end
        if s.t3_1.id != 0:
            tempvar p = p + 1
        end

        return (p)
    end
end
