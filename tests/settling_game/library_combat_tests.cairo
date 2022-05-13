%lang starknet

from contracts.settling_game.utils.game_structs import Squad, PackedSquad, SquadStats, Troop
from contracts.settling_game.library.library_combat import COMBAT

@view
func test_add_troop_to_squad(t : Troop, s : Squad) -> (updated : Squad):
    let (updated) = COMBAT.add_troop_to_squad(t, s)
    return (updated)
end

@view
func test_remove_troop_from_squad(troop_idx : felt, s : Squad) -> (updated : Squad):
    let (updated) = COMBAT.remove_troop_from_squad(troop_idx, s)
    return (updated)
end

@view
func test_compute_squad_stats(s : Squad) -> (stats : SquadStats):
    let (stats) = COMBAT.compute_squad_stats(s)
    return (stats)
end

@view
func test_pack_squad{range_check_ptr}(s : Squad) -> (p : PackedSquad):
    let (p) = COMBAT.pack_squad(s)
    return (p)
end

@view
func test_unpack_squad{range_check_ptr}(p : PackedSquad) -> (s : Squad):
    let (s : Squad) = COMBAT.unpack_squad(p)
    return (s)
end

@view
func test_unpack_troop{range_check_ptr}(packed : felt) -> (t : Troop):
    let (t) = COMBAT.unpack_troop(packed)
    return (t)
end

@view
func test_squad_to_array{range_check_ptr}(s : Squad) -> (a_len : felt, a : felt*):
    let (a_len : felt, a : felt*) = COMBAT.squad_to_array(s)
    return (a_len, a)
end

@view
func test_troop_to_array{range_check_ptr}(t : Troop) -> (a_len : felt, a : felt*):
    let (a_len : felt, a : felt*) = COMBAT.troop_to_array(t)
    return (a_len, a)
end

@view
func test_array_to_squad{range_check_ptr}(a_len : felt, a : felt*) -> (s : Squad):
    let (squad) = COMBAT.array_to_squad(a_len, a)
    return (squad)
end

@view
func test_array_to_troop(a_len : felt, a : felt*) -> (t : Troop):
    let (troop) = COMBAT.array_to_troop(a_len, a)
    return (troop)
end

@view
func test_find_first_free_troop_slot_in_squad(s : Squad, tier : felt) -> (free_slot_index : felt):
    let (idx) = COMBAT.find_first_free_troop_slot_in_squad(s, tier)
    return (idx)
end

@view
func test_build_squad_from_troops{range_check_ptr}(troop_ids_len : felt, troop_ids : felt*) -> (
    squad : Squad
):
    let (s : Squad) = COMBAT.build_squad_from_troops(troop_ids_len, troop_ids)
    return (s)
end

@view
func test_get_troop_population{range_check_ptr}(squad : PackedSquad) -> (population : felt):
    alloc_locals
    let (population) = COMBAT.get_troop_population(squad)

    return (population)
end
