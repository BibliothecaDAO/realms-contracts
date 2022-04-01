%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le, split_int, unsigned_div_rem
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset
from starkware.cairo.common.pow import pow
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.utils.game_structs import (
    TroopId, TroopType, Troop, Squad, PackedSquad, RealmCombatData)
from contracts.settling_game.library_combat import pack_squad

# used when adding or removing squads to Realms
const ATTACKING_SQUAD_SLOT = 1
const DEFENDING_SQUAD_SLOT = 2

@storage_var
func realm_combat_data(realm_id : Uint256) -> (combat_data : RealmCombatData):
end

@view
func get_realm_combat_data{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        realm_id : Uint256) -> (combat_data : RealmCombatData):
    let (combat_data) = realm_combat_data.read(realm_id)
    return (combat_data)
end

@external
func set_realm_combat_data{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        realm_id : Uint256, combat_data : RealmCombatData):
    # TODO: auth checks! but how? this gets called from L06 after a combat
    realm_combat_data.write(realm_id, combat_data)
    return ()
end

# can be used to add, overwrite or remove a Squad from a Realm
@external
func update_squad_in_realm{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
        s : Squad, realm_id : Uint256, slot : felt):
    alloc_locals
    # TODO: owner checks
    let (realm_combat_data : RealmCombatData) = get_realm_combat_data(realm_id)
    let (packed_squad : PackedSquad) = pack_squad(s)

    if slot == ATTACKING_SQUAD_SLOT:
        let new_realm_combat_data = RealmCombatData(
            attacking_squad=packed_squad,
            defending_squad=realm_combat_data.defending_squad,
            last_attacked_at=realm_combat_data.last_attacked_at)
        set_realm_combat_data(realm_id, new_realm_combat_data)
        return ()
    else:
        let new_realm_combat_data = RealmCombatData(
            attacking_squad=realm_combat_data.attacking_squad,
            defending_squad=packed_squad,
            last_attacked_at=realm_combat_data.last_attacked_at)
        set_realm_combat_data(realm_id, new_realm_combat_data)
        return ()
    end
end

# TODO: stats shouldn't be hardcoded here, take them from a felt that's easy to update
#       TBD on how that's going to be done, some kind of shared stats module

@view
func get_troop{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(troop_id : felt) -> (t : Troop):
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

@view
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
        Squad.SIZE - free_slot - Troop.SIZE)
    let (updated) = array_to_squad(sarr_len, a)

    return (updated)
end

@view
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

@view
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

@view
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
