%lang starknet

from contracts.settling_game.utils.game_structs import Squad, PackedSquad, SquadStats, Troop

from contracts.settling_game.S06_Combat import (
    squad_to_array, troop_to_array, array_to_squad, array_to_troop, add_troop_to_squad,
    find_first_free_troop_slot_in_squad)

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
