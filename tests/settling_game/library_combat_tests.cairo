%lang starknet

from contracts.settling_game.utils.game_structs import Squad, PackedSquad, SquadStats, Troop, SquadPopulation
from contracts.settling_game.library_combat import (
    add_troop_to_squad,
    remove_troop_from_squad,
    compute_squad_stats,
    pack_squad,
    unpack_squad,
    unpack_troop,
    squad_to_array,
    troop_to_array,
    array_to_squad,
    array_to_troop,
    find_first_free_troop_slot_in_squad,
    build_squad_from_troops,
    get_troop_population
)

@view
func test_add_troop_to_squad(t : Troop, s : Squad) -> (updated : Squad):
    let (updated) = add_troop_to_squad(t, s)
    return (updated)
end

@view
func test_remove_troop_from_squad(troop_idx : felt, s : Squad) -> (updated : Squad):
    let (updated) = remove_troop_from_squad(troop_idx, s)
    return (updated)
end

@view
func test_compute_squad_stats(s : Squad) -> (stats : SquadStats):
    let (stats) = compute_squad_stats(s)
    return (stats)
end

@view
func test_pack_squad{range_check_ptr}(s : Squad) -> (p : PackedSquad):
    let (p) = pack_squad(s)
    return (p)
end

@view
func test_unpack_squad{range_check_ptr}(p : PackedSquad) -> (s : Squad):
    let (s : Squad) = unpack_squad(p)
    return (s)
end

@view
func test_unpack_troop{range_check_ptr}(packed : felt) -> (t : Troop):
    let (t) = unpack_troop(packed)
    return (t)
end

@view
func test_squad_to_array{range_check_ptr}(s : Squad) -> (a_len : felt, a : felt*):
    let (a_len : felt, a : felt*) = squad_to_array(s)
    return (a_len, a)
end

@view
func test_troop_to_array{range_check_ptr}(t : Troop) -> (a_len : felt, a : felt*):
    let (a_len : felt, a : felt*) = troop_to_array(t)
    return (a_len, a)
end

@view
func test_array_to_squad{range_check_ptr}(a_len : felt, a : felt*) -> (s : Squad):
    let (squad) = array_to_squad(a_len, a)
    return (squad)
end

@view
func test_array_to_troop(a_len : felt, a : felt*) -> (t : Troop):
    let (troop) = array_to_troop(a_len, a)
    return (troop)
end

@view
func test_find_first_free_troop_slot_in_squad(s : Squad, tier : felt) -> (free_slot_index : felt):
    let (idx) = find_first_free_troop_slot_in_squad(s, tier)
    return (idx)
end

@view
func test_build_squad_from_troops{range_check_ptr}(troop_ids_len : felt, troop_ids : felt*) -> (
    squad : Squad
):
    let (s : Squad) = build_squad_from_troops(troop_ids_len, troop_ids)
    return (s)
end

@view
func test_get_troop_population{range_check_ptr}(squad : PackedSquad) -> (population : felt):
    alloc_locals
    let (population) = get_troop_population(squad)

    return (population=population)
end
