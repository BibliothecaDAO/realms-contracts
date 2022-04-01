%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_le, split_int, unsigned_div_rem

from contracts.settling_game.utils.game_structs import Squad, PackedSquad, SquadStats, Troop

# used for packing
const SHIFT = 0x100

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
        SquadStats(agility=agility, attack=attack, defense=defense, vitality=vitality, wisdom=wisdom))
end

func pack_squad{range_check_ptr}(s : Squad) -> (p : PackedSquad):
    alloc_locals

    # p1
    let (pt1_1) = pack_troop(s.t1_1)
    let (pt1_2) = pack_troop(s.t1_2)
    let (pt1_3) = pack_troop(s.t1_3)
    let (pt1_4) = pack_troop(s.t1_4)
    let p1 = pt1_1 + (pt1_2 * (SHIFT ** 7)) + (pt1_3 * (SHIFT ** 14)) + (pt1_4 * (SHIFT ** 21))

    # p2
    let (pt1_5) = pack_troop(s.t1_5)
    let (pt1_6) = pack_troop(s.t1_6)
    let (pt1_7) = pack_troop(s.t1_7)
    let (pt1_8) = pack_troop(s.t1_8)
    let p2 = pt1_5 + (pt1_6 * (SHIFT ** 7)) + (pt1_7 * (SHIFT ** 14)) + (pt1_8 * (SHIFT ** 21))

    # p3
    let (pt1_9) = pack_troop(s.t1_9)
    let (pt1_10) = pack_troop(s.t1_10)
    let (pt1_11) = pack_troop(s.t1_11)
    let (pt1_12) = pack_troop(s.t1_12)
    let p3 = pt1_9 + (pt1_10 * (SHIFT ** 7)) + (pt1_11 * (SHIFT ** 14)) + (pt1_12 * (SHIFT ** 21))

    # p4
    let (pt1_13) = pack_troop(s.t1_13)
    let (pt1_14) = pack_troop(s.t1_14)
    let (pt1_15) = pack_troop(s.t1_15)
    let (pt1_16) = pack_troop(s.t1_16)
    let p4 = pt1_13 + (pt1_14 * (SHIFT ** 7)) + (pt1_15 * (SHIFT ** 14)) + (pt1_16 * (SHIFT ** 21))

    # p5
    let (pt2_1) = pack_troop(s.t2_1)
    let (pt2_2) = pack_troop(s.t2_2)
    let (pt2_3) = pack_troop(s.t2_3)
    let (pt2_4) = pack_troop(s.t2_4)
    let p5 = pt2_1 + (pt2_2 * (SHIFT ** 7)) + (pt2_3 * (SHIFT ** 14)) + (pt2_4 * (SHIFT ** 21))

    # p6
    let (pt2_5) = pack_troop(s.t2_5)
    let (pt2_6) = pack_troop(s.t2_6)
    let (pt2_7) = pack_troop(s.t2_7)
    let (pt2_8) = pack_troop(s.t2_8)
    let p6 = pt2_5 + (pt2_6 * (SHIFT ** 7)) + (pt2_7 * (SHIFT ** 14)) + (pt2_8 * (SHIFT ** 21))

    # p7
    let (p7) = pack_troop(s.t3_1)

    return (PackedSquad(p1=p1, p2=p2, p3=p3, p4=p4, p5=p5, p6=p6, p7=p7))
end

func unpack_squad{range_check_ptr}(p : PackedSquad) -> (s : Squad):
    alloc_locals

    # can't use unsigned_div_rem to do unpacking because
    # the values are above 2**128 so a bound check would fail
    # instead using split_int to slice the felt to parts;
    # using 2**56 bound because a Troop is 7 bytes => 2 ** (8 * 7)

    let (p1_out : felt*) = alloc()
    split_int(p.p1, 4, SHIFT ** 7, 2 ** 56, p1_out)
    let (p2_out : felt*) = alloc()
    split_int(p.p2, 4, SHIFT ** 7, 2 ** 56, p2_out)
    let (p3_out : felt*) = alloc()
    split_int(p.p3, 4, SHIFT ** 7, 2 ** 56, p3_out)
    let (p4_out : felt*) = alloc()
    split_int(p.p4, 4, SHIFT ** 7, 2 ** 56, p4_out)
    let (p5_out : felt*) = alloc()
    split_int(p.p5, 4, SHIFT ** 7, 2 ** 56, p5_out)
    let (p6_out : felt*) = alloc()
    split_int(p.p6, 4, SHIFT ** 7, 2 ** 56, p6_out)

    let (t1_1) = unpack_troop([p1_out])
    let (t1_2) = unpack_troop([p1_out + 1])
    let (t1_3) = unpack_troop([p1_out + 2])
    let (t1_4) = unpack_troop([p1_out + 3])
    let (t1_5) = unpack_troop([p2_out])
    let (t1_6) = unpack_troop([p2_out + 1])
    let (t1_7) = unpack_troop([p2_out + 2])
    let (t1_8) = unpack_troop([p2_out + 3])
    let (t1_9) = unpack_troop([p3_out])
    let (t1_10) = unpack_troop([p3_out + 1])
    let (t1_11) = unpack_troop([p3_out + 2])
    let (t1_12) = unpack_troop([p3_out + 3])
    let (t1_13) = unpack_troop([p4_out])
    let (t1_14) = unpack_troop([p4_out + 1])
    let (t1_15) = unpack_troop([p4_out + 2])
    let (t1_16) = unpack_troop([p4_out + 3])

    let (t2_1) = unpack_troop([p5_out])
    let (t2_2) = unpack_troop([p5_out + 1])
    let (t2_3) = unpack_troop([p5_out + 2])
    let (t2_4) = unpack_troop([p5_out + 3])
    let (t2_5) = unpack_troop([p6_out])
    let (t2_6) = unpack_troop([p6_out + 1])
    let (t2_7) = unpack_troop([p6_out + 2])
    let (t2_8) = unpack_troop([p6_out + 3])

    let (t3_1) = unpack_troop(p.p7)

    return (
        Squad(t1_1=t1_1, t1_2=t1_2, t1_3=t1_3, t1_4=t1_4, t1_5=t1_5, t1_6=t1_6,
        t1_7=t1_7, t1_8=t1_8, t1_9=t1_9, t1_10=t1_10, t1_11=t1_11, t1_12=t1_12,
        t1_13=t1_13, t1_14=t1_14, t1_15=t1_15, t1_16=t1_16, t2_1=t2_1, t2_2=t2_2,
        t2_3=t2_3, t2_4=t2_4, t2_5=t2_5, t2_6=t2_6, t2_7=t2_7, t2_8=t2_8, t3_1=t3_1))
end

func pack_troop{range_check_ptr}(t : Troop) -> (packed : felt):
    alloc_locals

    assert_le(t.type, 3)
    assert_le(t.tier, 255)
    assert_le(t.agility, 255)
    assert_le(t.attack, 255)
    assert_le(t.defense, 255)
    assert_le(t.vitality, 255)
    assert_le(t.wisdom, 255)

    # TODO: mention limitations of this approach
    #       short comment about how it works

    tempvar r = t.type  # no need to shift type
    tempvar tier_shifted = t.tier * SHIFT
    tempvar r = r + tier_shifted
    tempvar agility_shifted = t.agility * (SHIFT ** 2)
    tempvar r = r + agility_shifted
    tempvar attack_shifted = t.attack * (SHIFT ** 3)
    tempvar r = r + attack_shifted
    tempvar defense_shifted = t.defense * (SHIFT ** 4)
    tempvar r = r + defense_shifted
    tempvar vitality_shifted = t.vitality * (SHIFT ** 5)
    tempvar r = r + vitality_shifted
    tempvar wisdom_shifted = t.wisdom * (SHIFT ** 6)
    tempvar r = r + wisdom_shifted

    return (r)
end

func unpack_troop{range_check_ptr}(packed : felt) -> (t : Troop):
    let (r0, type) = unsigned_div_rem(packed, SHIFT)
    let (r1, tier) = unsigned_div_rem(r0, SHIFT)
    let (r2, agility) = unsigned_div_rem(r1, SHIFT)
    let (r3, attack) = unsigned_div_rem(r2, SHIFT)
    let (r4, defense) = unsigned_div_rem(r3, SHIFT)
    let (wisdom, vitality) = unsigned_div_rem(r4, SHIFT)

    return (
        Troop(type=type, tier=tier, agility=agility, attack=attack, defense=defense, vitality=vitality, wisdom=wisdom))
end
