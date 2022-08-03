%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.L06_Combat import (
    run_combat_loop,
    attack,
    load_troop_costs,
    set_troop_cost,
)
from contracts.settling_game.utils.game_structs import Troop, Squad, Cost

@view
func test_run_combat_loop{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    attacker : Squad, defender : Squad
) -> (attacker : Squad, defender : Squad, outcome : felt):
    let (a, d, o) = run_combat_loop(Uint256(1, 0), Uint256(2, 0), attacker, defender)
    return (a, d, o)
end

@view
func test_attack{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    a : Squad, d : Squad
) -> (d_after_attack : Squad):
    let (d_after_attack) = attack(Uint256(1, 0), Uint256(2, 0), a, d)
    return (d_after_attack)
end

@view
func test_load_troop_costs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    troop_ids_len : felt, troop_ids : felt*
) -> (costs_len : felt, costs : Cost*):
    alloc_locals

    let (costs : Cost*) = alloc()
    load_troop_costs(troop_ids_len, troop_ids, costs)

    return (troop_ids_len, costs)
end
