import asyncio
from collections import namedtuple
import functools
import math
import operator
import os
import struct

import pytest
from starkware.starknet.testing.starknet import Starknet, StarknetContract
from starkware.starkware_utils.error_handling import StarkException


Troop = namedtuple('Troop', 'type tier agility attack defense vitality wisdom')
Squad = namedtuple(
    'Squad',
    't1_1 t1_2 t1_3 t1_4 t1_5 t1_6 t1_7 t1_8 t1_9 t1_10 t1_11 t1_12 t1_13 t1_14 t1_15 t1_16 '
    + 't2_1 t2_2 t2_3 t2_4 t2_5 t2_6 t2_7 t2_8 t3_1',
)
PackedSquad = namedtuple('PackedSquad', 'p1 p2 p3 p4 p5 p6 p7')

EMPTY_TROOP = Troop(0, 0, 0, 0, 0, 0, 0)
WATCHMAN = Troop(1, 1, 1, 1, 3, 4, 1)
GUARD = Troop(1, 2, 2, 2, 6, 8, 2)
GUARD_CAPTAIN = Troop(1, 3, 4, 4, 12, 16, 4)
SQUIRE = Troop(1, 1, 1, 4, 1, 1, 3)
KNIGHT = Troop(1, 2, 2, 8, 2, 2, 6)
KNIGHT_COMMANDER = Troop(1, 3, 4, 16, 4, 4, 12)
SCOUT = Troop(2, 1, 4, 3, 1, 1, 1)
ARCHER = Troop(2, 2, 8, 6, 2, 2, 2)
SNIPER = Troop(2, 3, 16, 12, 4, 4, 4)
SCORPIO = Troop(3, 1, 1, 4, 1, 3, 1)
BAILLISTA = Troop(3, 2, 2, 8, 2, 6, 2)
CATAPULT = Troop(3, 3, 4, 16, 4, 12, 4)
APPRENTICE = Troop(2, 1, 2, 2, 1, 1, 4)
MAGE = Troop(2, 2, 4, 4, 2, 2, 8)
ARCANIST = Troop(2, 3, 8, 8, 4, 4, 16)
GRAND_MARSHAL = Troop(1, 3, 16, 16, 16, 16, 16)
TROOPS = [
    WATCHMAN,
    GUARD,
    GUARD_CAPTAIN,
    SQUIRE,
    KNIGHT,
    KNIGHT_COMMANDER,
    SCOUT,
    ARCHER,
    SNIPER,
    SCORPIO,
    BAILLISTA,
    CATAPULT,
    APPRENTICE,
    MAGE,
    ARCANIST,
    GRAND_MARSHAL,
]


def build_default_squad() -> Squad:
    troops = [WATCHMAN] * 16 + [GUARD] * 8 + [GUARD_CAPTAIN]
    return Squad(*troops)


def build_partial_squad(first_empty_slot: int) -> Squad:
    troops = [WATCHMAN] * 16 + [GUARD] * 8 + [GUARD_CAPTAIN]
    empties = [EMPTY_TROOP] * (25 - first_empty_slot)
    squad = Squad(*(troops[:first_empty_slot] + empties))
    return squad


def pack_squad(squad: Squad) -> PackedSquad:
    shift = 0x100
    p1 = (
        pack_troop(squad.t1_1)
        + pack_troop(squad.t1_2) * shift ** 7
        + pack_troop(squad.t1_3) * shift ** 14
        + pack_troop(squad.t1_4) * shift ** 21
    )
    p2 = (
        pack_troop(squad.t1_5)
        + pack_troop(squad.t1_6) * shift ** 7
        + pack_troop(squad.t1_7) * shift ** 14
        + pack_troop(squad.t1_8) * shift ** 21
    )
    p3 = (
        pack_troop(squad.t1_9)
        + pack_troop(squad.t1_10) * shift ** 7
        + pack_troop(squad.t1_11) * shift ** 14
        + pack_troop(squad.t1_12) * shift ** 21
    )
    p4 = (
        pack_troop(squad.t1_13)
        + pack_troop(squad.t1_14) * shift ** 7
        + pack_troop(squad.t1_15) * shift ** 14
        + pack_troop(squad.t1_16) * shift ** 21
    )

    p5 = (
        pack_troop(squad.t2_1)
        + pack_troop(squad.t2_2) * shift ** 7
        + pack_troop(squad.t2_3) * shift ** 14
        + pack_troop(squad.t2_4) * shift ** 21
    )

    p6 = (
        pack_troop(squad.t2_5)
        + pack_troop(squad.t2_6) * shift ** 7
        + pack_troop(squad.t2_7) * shift ** 14
        + pack_troop(squad.t2_8) * shift ** 21
    )

    p7 = pack_troop(squad.t3_1)

    return PackedSquad(p1, p2, p3, p4, p5, p6, p7)


def pack_troop(troop: Troop) -> int:
    return int.from_bytes(struct.pack('<7b', *troop), 'little')


@pytest.mark.asyncio
async def test_get_troop(s06_combat):
    for idx, troop in enumerate(TROOPS):
        tx = await s06_combat.get_troop(idx + 1).invoke()
        assert troop == tx.result.t

    with pytest.raises(StarkException):
        await s06_combat.get_troop(0).invoke()

    with pytest.raises(StarkException):
        await s06_combat.get_troop(len(TROOPS) + 1).invoke()


@pytest.mark.asyncio
async def test_unpack_troop(s06_combat_tests):
    for troop in TROOPS:
        packed = pack_troop(troop)
        tx = await s06_combat_tests.test_unpack_troop(packed).invoke()
        assert troop == tx.result.t


@pytest.mark.asyncio
async def test_compute_squad_stats(s06_combat_tests):
    squad = build_default_squad()
    tx = await s06_combat_tests.test_compute_squad_stats(squad).invoke()
    stats = tx.result.stats

    assert stats.agility == sum([t.agility for t in squad])
    assert stats.attack == sum([t.attack for t in squad])
    assert stats.defense == sum([t.defense for t in squad])
    assert stats.vitality == sum([t.vitality for t in squad])
    assert stats.wisdom == sum([t.wisdom for t in squad])


@pytest.mark.asyncio
async def test_pack_squad(s06_combat_tests):
    squad = build_default_squad()
    packed_squad = pack_squad(squad)
    tx = await s06_combat_tests.test_pack_squad(squad).invoke()
    assert tx.result.p == packed_squad


@pytest.mark.asyncio
async def test_unpack_squad(s06_combat_tests):
    squad = build_default_squad()
    packed_squad = pack_squad(squad)
    tx = await s06_combat_tests.test_unpack_squad(packed_squad).invoke()
    assert tx.result.s == squad


@pytest.mark.asyncio
async def test_attack(l06_combat_tests):
    attack_vs_defense = 1
    wisdom_vs_agility = 2
    for attack_type in [attack_vs_defense, wisdom_vs_agility]:
        a = build_default_squad()
        d = build_default_squad()
        tx = await l06_combat_tests.test_attack(a, d, attack_type).invoke()

        # assuming at least one hit
        assert tx.result.d_after_attack.t1_1.vitality < d.t1_1.vitality


@pytest.mark.asyncio
async def test_compute_min_roll_to_hit(l06_combat_tests):
    # NOTE: takes about 3 mins to go through the whole combo
    for a in range(20, 120):
        for d in range(20, 120):
            exp = min(math.ceil((a / d) * 7), 12)
            tx = await l06_combat_tests.test_compute_min_roll_to_hit(a, d).invoke()
            res = tx.result.min_roll
            assert exp == res


@pytest.mark.asyncio
async def test_hit_squad(l06_combat_tests):
    # default squad has a vitality of 144

    # partial kill
    squad = build_default_squad()
    tx = await l06_combat_tests.test_hit_squad(squad, 100).invoke()
    attacked = tx.result.squad
    assert attacked.t1_1.vitality == 0
    assert attacked.t1_16.vitality == 0
    assert attacked.t2_1.vitality == 0
    assert attacked.t2_4.vitality == 0
    assert attacked.t2_5.vitality == 4
    assert attacked.t3_1.vitality == 16

    # full kill
    squad = build_default_squad()
    tx = await l06_combat_tests.test_hit_squad(squad, 144).invoke()
    attacked = tx.result.squad
    assert attacked.t1_1.vitality == 0
    assert attacked.t1_16.vitality == 0
    assert attacked.t2_1.vitality == 0
    assert attacked.t2_8.vitality == 0
    assert attacked.t3_1.vitality == 0


@pytest.mark.asyncio
async def test_hit_troop(l06_combat_tests):
    # test full kill
    tx = await l06_combat_tests.test_hit_troop(WATCHMAN, 27).invoke()
    troop = Troop(*tx.result.hit_troop)
    hits_left = tx.result.remaining_hits

    assert troop.vitality == 0
    assert hits_left == 27 - WATCHMAN.vitality

    # test injury
    tx = await l06_combat_tests.test_hit_troop(WATCHMAN, 2).invoke()
    troop = Troop(*tx.result.hit_troop)
    hits_left = tx.result.remaining_hits

    assert troop.vitality == WATCHMAN.vitality - 2
    assert hits_left == 0

    # test no hit
    tx = await l06_combat_tests.test_hit_troop(WATCHMAN, 0).invoke()
    troop = Troop(*tx.result.hit_troop)
    hits_left = tx.result.remaining_hits

    assert troop.vitality == WATCHMAN.vitality
    assert hits_left == 0


@pytest.mark.asyncio
async def test_squad_to_array(s06_combat_tests):
    s = build_default_squad()
    tx = await s06_combat_tests.test_squad_to_array(s).invoke()
    flattened = functools.reduce(operator.concat, [list(t) for t in s])
    assert tx.result.a == flattened


@pytest.mark.asyncio
async def test_troop_to_array(s06_combat_tests):
    for t in TROOPS:
        tx = await s06_combat_tests.test_troop_to_array(t).invoke()
        assert tx.result.a == list(t)


@pytest.mark.asyncio
async def test_array_to_squad(s06_combat_tests):
    s = build_default_squad()
    flattened = functools.reduce(operator.concat, [list(t) for t in s])
    tx = await s06_combat_tests.test_array_to_squad(flattened).invoke()
    assert tx.result.s == s


@pytest.mark.asyncio
async def test_array_to_troop(s06_combat_tests):
    a = list(SNIPER)
    tx = await s06_combat_tests.test_array_to_troop(a).invoke()
    assert tx.result.t == SNIPER


@pytest.mark.asyncio
async def test_add_troop_to_squad(s06_combat):
    partial_squad = build_partial_squad(3)

    # add a tier 1
    tx = await s06_combat.add_troop_to_squad(SCORPIO, partial_squad).invoke()
    assert tx.result.updated.t1_4 == SCORPIO

    # add a tier 2
    tx = await s06_combat.add_troop_to_squad(KNIGHT, partial_squad).invoke()
    assert tx.result.updated.t2_1 == KNIGHT

    # add a tier 3
    tx = await s06_combat.add_troop_to_squad(ARCANIST, partial_squad).invoke()
    assert tx.result.updated.t3_1 == ARCANIST

    # adding to a full squad should fail
    with pytest.raises(StarkException):
        squad = build_default_squad()
        await s06_combat.add_troop_to_squad(GUARD, squad).invoke()


@pytest.mark.asyncio
async def test_remove_troop_from_squad(s06_combat):
    squad = build_default_squad()

    modified_squad = squad
    for troop_idx in range(len(squad)):
        tx = await s06_combat.remove_troop_from_squad(troop_idx, modified_squad).invoke()
        modified_squad = tx.result.updated
        assert modified_squad[troop_idx] == EMPTY_TROOP


@pytest.mark.asyncio
async def test_find_first_free_troop_slot_in_squad(s06_combat_tests):
    troop_size = 7  # Cairo's Troop.SIZE, also the number of element in Troop
    for i in range(25):
        partial_squad = build_partial_squad(i)
        tier = 1
        if i >= 16:
            tier = 2
        if i == 24:
            tier = 3

        tx = await s06_combat_tests.test_find_first_free_troop_slot_in_squad(
            partial_squad, tier
        ).invoke()
        assert tx.result.free_slot_index == i * troop_size

    full_squad = build_default_squad()
    for tier in [1, 2, 3]:
        with pytest.raises(StarkException):
            await s06_combat_tests.test_find_first_free_troop_slot_in_squad(
                full_squad, tier
            ).invoke()
