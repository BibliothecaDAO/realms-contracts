%lang starknet

from B5_Combat import (
    compute_squad_stats, unpack_troop, pack_squad, unpack_squad, PackedSquad, Squad, SquadStats,
    Troop)

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
