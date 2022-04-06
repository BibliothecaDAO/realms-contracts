%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.settling_game.L06_Combat import (
    run_combat_loop, attack, compute_min_roll_to_hit, hit_troop, hit_squad, to_arr)
from contracts.settling_game.utils.game_structs import Troop, Squad

@view
func test_run_combat_loop{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
        attacker : Squad, defender : Squad, attack_type : felt) -> (
        attacker : Squad, defender : Squad, outcome : felt):
    let (a, d, o) = run_combat_loop(attacker, defender, attack_type)
    return (a, d, o)
end

@view
func test_attack{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
        a : Squad, d : Squad, attack_type : felt) -> (d_after_attack : Squad):
    let (d_after_attack) = attack(a, d, attack_type)
    return (d_after_attack)
end

@view
func test_hit_squad{range_check_ptr}(s : Squad, hits : felt) -> (squad : Squad):
    let (s) = hit_squad(s, hits)
    return (s)
end

@view
func test_hit_troop{range_check_ptr}(t : Troop, hits : felt) -> (
        hit_troop : Troop, remaining_hits : felt):
    let (t, r) = hit_troop(t, hits)
    return (t, r)
end

@view
func test_compute_min_roll_to_hit{range_check_ptr}(a : felt, d : felt) -> (min_roll : felt):
    let (r) = compute_min_roll_to_hit(a, d)
    return (r)
end
