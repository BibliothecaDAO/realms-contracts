%lang starknet

from settling_game.S06_Combat import (
    compute_squad_stats, unpack_troop, pack_squad, unpack_squad, squad_to_array, troop_to_array,
    array_to_squad, array_to_troop, add_troop_to_squad, find_first_free_troop_slot_in_squad,
    PackedSquad, Squad, SquadStats, Troop)

@view
func test_compute_squad_stats(s : Squad) -> (stats : SquadStats):
    let (stats) = compute_squad_stats(s)
    return (stats)
end

@view
func test_unpack_troop{range_check_ptr}(packed : felt) -> (t : Troop):
    let (t) = unpack_troop(packed)
    return (t)
end

@view
func test_pack_squad{range_check_ptr}(s : Squad) -> (p : PackedSquad):
    let (p) = pack_squad(s)
    return (p)
end

@view
func test_unpack_squad{range_check_ptr}(p : PackedSquad) -> (s : Squad):
    let (s) = unpack_squad(p)
    return (s)
end

@view
func test_squad_to_array(s : Squad) -> (a_len : felt, a : felt*):
    let (a_len, a) = squad_to_array(s)
    return (a_len, a)
end

@view
func test_troop_to_array(t : Troop) -> (a_len : felt, a : felt*):
    let (a_len, a) = troop_to_array(t)
    return (a_len, a)
end

@view
func test_array_to_squad(a_len : felt, a : felt*) -> (s : Squad):
    let (s) = array_to_squad(a_len, a)
    return (s)
end

@view
func test_array_to_troop(a_len : felt, a : felt*) -> (t : Troop):
    let (t) = array_to_troop(a_len, a)
    return (t)
end

@view
func test_find_first_free_troop_slot_in_squad(s : Squad, tier : felt) -> (free_slot_index : felt):
    let (idx) = find_first_free_troop_slot_in_squad(s, tier)
    return (idx)
end
