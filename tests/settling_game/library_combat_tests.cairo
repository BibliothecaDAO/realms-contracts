%lang starknet

from contracts.settling_game.utils.game_structs import Squad, PackedSquad, SquadStats, Troop
from contracts.settling_game.library_combat import (
    compute_squad_stats, pack_squad, unpack_squad, unpack_troop)

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
    let (s) = unpack_squad(p)
    return (s)
end

@view
func test_unpack_troop{range_check_ptr}(packed : felt) -> (t : Troop):
    let (t) = unpack_troop(packed)
    return (t)
end
