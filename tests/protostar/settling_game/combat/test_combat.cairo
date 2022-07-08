%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc

# from starkware.cairo.common.uint256 import Uint256, uint256_add
# from starkware.cairo.common.math_cmp import is_nn, is_le
# from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
# from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div

# from contracts.settling_game.L06_Combat import (
#     run_combat_loop,
#     attack,
#     compute_min_roll_to_hit,
#     load_troop_costs,
# )
from contracts.settling_game.library.library_combat import Combat
from contracts.settling_game.utils.game_structs import (
    RealmBuildingsIds,
    Troop,
    TroopId,
    TroopType,
    Squad,
    SquadStats,
)
# from contracts.settling_game.interfaces.imodules import IArbiter, IL06_Combat
# from contracts.settling_game.utils.game_structs import RealmBuildings, RealmCombatData, Cost, Squad

from protostar.asserts import assert_eq

@external
func __setup__():
    %{
        import os, sys
        sys.path.append(os.path.abspath(os.path.dirname(".")))
    %}

    return ()
end

# @external
# func test_combat{syscall_ptr : felt*, range_check_ptr}():
#     alloc_locals

# let (local troop_ids : felt*) = alloc()

# let (local troop_ids_2 : felt*) = alloc()

# assert troop_ids[0] = 1

# assert troop_ids_2[0] = 1
#     assert troop_ids_2[1] = 2

# local L06_Combat : felt
#     local L06_Proxy_Combat : felt

# %{ ids.L06_Combat = deploy_contract("./contracts/settling_game/L06_Combat.cairo", []).contract_address %}
#     %{ ids.L06_Proxy_Combat = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.L06_Combat]).contract_address %}

# IL06_Combat.set_troop_cost(L06_Proxy_Combat, 1, Cost(3, 8, 262657, 328450))
#     IL06_Combat.set_troop_cost(L06_Proxy_Combat, 2, Cost(3, 8, 262657, 656900))

# IL06_Combat.build_squad_from_troops_in_realm(L06_Proxy_Combat, 1, troop_ids, Uint256(1, 0), 1)
#     IL06_Combat.build_squad_from_troops_in_realm(L06_Proxy_Combat, 2, troop_ids_2, Uint256(1, 0), 1)

# %{ mock_call(ids.L06_Proxy_Combat, "view_troops", [1, 0]) %}
#     let (attacking_s : Squad, defending_s : Squad) = IL06_Combat.view_troops(
#         L06_Proxy_Combat, Uint256(1, 0)
#     )

# %{ print(ids.attacking_s) %}
#     return ()
# end

@external
func test_get_troop_properties{range_check_ptr}():
    alloc_locals

    let (skirmisher : Troop*) = build_troop(TroopId.Skirmisher)
    tempvar expected : felt* = new (TroopId.Skirmisher, TroopType.RangedNormal, 1, RealmBuildingsIds.ArcherTower, 2, 7, 2, 53, 2)
    assert_arrays_eq(skirmisher, expected, Troop.SIZE)

    let (longbow : Troop*) = build_troop(TroopId.Longbow)
    tempvar expected : felt* = new (TroopId.Longbow, TroopType.RangedNormal, 2, RealmBuildingsIds.ArcherTower, 4, 7, 3, 53, 3)
    assert_arrays_eq(longbow, expected, Troop.SIZE)

    let (crossbow : Troop*) = build_troop(TroopId.Crossbow)
    tempvar expected : felt* = new (TroopId.Crossbow, TroopType.RangedNormal, 3, RealmBuildingsIds.ArcherTower, 6, 9, 4, 53, 4)
    assert_arrays_eq(crossbow, expected, Troop.SIZE)

    let (pikeman : Troop*) = build_troop(TroopId.Pikeman)
    tempvar expected : felt* = new (TroopId.Pikeman, TroopType.Melee, 1, RealmBuildingsIds.Barracks, 7, 4, 5, 53, 1)
    assert_arrays_eq(pikeman, expected, Troop.SIZE)

    let (knight : Troop*) = build_troop(TroopId.Knight)
    tempvar expected : felt* = new (TroopId.Knight, TroopType.Melee, 2, RealmBuildingsIds.Barracks, 9, 7, 8, 79, 2)
    assert_arrays_eq(knight, expected, Troop.SIZE)

    let (paladin : Troop*) = build_troop(TroopId.Paladin)
    tempvar expected : felt* = new (TroopId.Paladin, TroopType.Melee, 3, RealmBuildingsIds.Barracks, 9, 9, 9, 106, 3)
    assert_arrays_eq(paladin, expected, Troop.SIZE)

    let (ballista : Troop*) = build_troop(TroopId.Ballista)
    tempvar expected : felt* = new (TroopId.Ballista, TroopType.Siege, 1, RealmBuildingsIds.Castle, 4, 11, 4, 53, 2)
    assert_arrays_eq(ballista, expected, Troop.SIZE)

    let (mangonel : Troop*) = build_troop(TroopId.Mangonel)
    tempvar expected : felt* = new (TroopId.Mangonel, TroopType.Siege, 2, RealmBuildingsIds.Castle, 4, 10, 5, 53, 3)
    assert_arrays_eq(mangonel, expected, Troop.SIZE)

    let (trebuchet : Troop*) = build_troop(TroopId.Trebuchet)
    tempvar expected : felt* = new (TroopId.Trebuchet, TroopType.Siege, 3, RealmBuildingsIds.Castle, 4, 12, 6, 53, 4)
    assert_arrays_eq(trebuchet, expected, Troop.SIZE)

    let (apprentice : Troop*) = build_troop(TroopId.Apprentice)
    tempvar expected : felt* = new (TroopId.Apprentice, TroopType.RangedMagic, 1, RealmBuildingsIds.MageTower, 7, 7, 2, 53, 8)
    assert_arrays_eq(apprentice, expected, Troop.SIZE)

    let (mage : Troop*) = build_troop(TroopId.Mage)
    tempvar expected : felt* = new (TroopId.Mage, TroopType.RangedMagic, 2, RealmBuildingsIds.MageTower, 7, 9, 2, 53, 9)
    assert_arrays_eq(mage, expected, Troop.SIZE)

    let (arcanist : Troop*) = build_troop(TroopId.Arcanist)
    tempvar expected : felt* = new (TroopId.Arcanist, TroopType.RangedMagic, 3, RealmBuildingsIds.MageTower, 7, 11, 2, 53, 10)
    assert_arrays_eq(arcanist, expected, Troop.SIZE)

    return ()
end

@external
func test_get_troop_properties_reverts_id_zero{range_check_ptr}():
    %{ expect_revert() %}
    Combat.get_troop_properties(0)
    return ()
end

@external
func test_get_troop_properties_reverts_id_too_large{range_check_ptr}():
    %{ expect_revert() %}
    Combat.get_troop_properties(TroopId.SIZE)
    return ()
end

@external
func test_pack_troop{range_check_ptr}():
    alloc_locals

    let (pikeman : Troop*) = build_troop(TroopId.Pikeman)
    let (packed) = Combat.pack_troop([pikeman])
    local expected_packed
    %{
        # Pikeman ID is 4, full vitality is 53, those are the values that get packed
        from tests.protostar.settling_game.combat.utils import pack_troop
        # ids.expected_packed = pack_troop(4, 53)
        ids.expected_packed = pack_troop(ids.pikeman)
    %}
    assert_eq(packed, expected_packed)

    tempvar injured_pikeman : Troop* = new Troop(TroopId.Pikeman, 0, 0, 0, 0, 0, 0, 20, 0)
    let (packed_injured) = Combat.pack_troop([injured_pikeman])
    local expected_packed_injured
    %{ ids.expected_packed_injured = pack_troop(ids.injured_pikeman) %}
    assert_eq(packed_injured, expected_packed_injured)

    let (empty : Troop*) = build_empty_troop()
    let (packed_empty) = Combat.pack_troop([empty])
    assert_eq(packed_empty, 0)

    return ()
end

@external
func test_pack_troop_reverts_id_too_large{range_check_ptr}():
    %{ expect_revert() %}
    tempvar invalid = new Troop(TroopId.SIZE, 0, 0, 0, 0, 0, 0, 200, 0)
    Combat.pack_troop([invalid])
    return ()
end

@external
func test_pack_troop_reverts_vitality_too_large{range_check_ptr}():
    %{ expect_revert() %}
    tempvar invalid = new Troop(TroopId.Mage, 0, 0, 0, 0, 0, 0, 300, 0)
    Combat.pack_troop([invalid])
    return ()
end

@external
func test_unpack_troop{range_check_ptr}():
    alloc_locals

    unpack_packed_all_loop(TroopId.SIZE - 1)

    let packed_skirmisher_20 = 5121  # TroopId.Skirmisher w/ vitality 20
    let (unpacked : Troop) = Combat.unpack_troop(packed_skirmisher_20)
    tempvar expected = Troop(TroopId.Skirmisher, TroopType.RangedNormal, 1, RealmBuildingsIds.ArcherTower, 2, 7, 2, 20, 2)
    # TODO: is there a clean way how to use assert_array_eq here as well?
    assert_troop_eq(unpacked, expected)

    let packed_empty = 0
    let (unpacked : Troop) = Combat.unpack_troop(packed_empty)
    let (expected_empty) = build_empty_troop()
    tempvar expected = [expected_empty]  # cast from Troop* to Troop
    assert_troop_eq(unpacked, expected)

    return ()
end

func unpack_packed_all_loop{range_check_ptr}(troop_id : felt):
    alloc_locals

    if troop_id == 0:
        return ()
    end

    let (t : Troop*) = build_troop(troop_id)
    let (packed) = Combat.pack_troop([t])
    let (unpacked) = Combat.unpack_troop(packed)
    assert_troop_eq(unpacked, [t])

    return unpack_packed_all_loop(troop_id - 1)
end

@external
func test_pack_squad{range_check_ptr}():
    alloc_locals
    local expected_packed_full
    local expected_packed_partial

    %{
        from tests.protostar.settling_game.combat import utils
        ids.expected_packed_full = utils.pack_squad(utils.build_default_squad())
        ids.expected_packed_partial = utils.pack_squad(utils.build_partial_squad())
    %}

    let (full : Squad) = build_default_squad()
    let (partial : Squad) = build_partial_squad()
    let (packed_full) = Combat.pack_squad(full)
    let (packed_partial) = Combat.pack_squad(partial)

    assert_eq(packed_full, expected_packed_full)
    assert_eq(packed_partial, expected_packed_partial)

    return ()
end

@external
func test_unpack_squad{range_check_ptr}():
    alloc_locals
    let (__fp__, _) = get_fp_and_pc()

    let full : Squad = build_default_squad()
    let partial : Squad = build_partial_squad()
    let (packed_full) = Combat.pack_squad(full)
    let (packed_partial) = Combat.pack_squad(partial)
    let (unpacked_full : Squad) = Combat.unpack_squad(packed_full)
    let (unpacked_partial : Squad) = Combat.unpack_squad(packed_partial)

    assert_arrays_eq(&full, &unpacked_full, Squad.SIZE)
    assert_arrays_eq(&partial, &unpacked_partial, Squad.SIZE)

    return ()
end

@external
func test_compute_squad_stats{range_check_ptr}():
    alloc_locals

    let squad : Squad = build_default_squad()
    let stats : SquadStats = Combat.compute_squad_stats(squad)

    assert_eq(stats.agility, 44)
    assert_eq(stats.attack, 107)
    assert_eq(stats.armor, 37)
    assert_eq(stats.vitality, 795)
    assert_eq(stats.wisdom, 37)

    let squad : Squad = build_partial_squad()
    let stats : SquadStats = Combat.compute_squad_stats(squad)

    assert_eq(stats.agility, 28)
    assert_eq(stats.attack, 65)
    assert_eq(stats.armor, 23)
    assert_eq(stats.vitality, 477)
    assert_eq(stats.wisdom, 23)

    return ()
end

@external
func test_compute_squad_vitality{range_check_ptr}():
    alloc_locals

    let full : Squad = build_default_squad()
    let partial : Squad = build_partial_squad()
    let (full_vitality) = Combat.compute_squad_vitality(full)
    let (partial_vitality) = Combat.compute_squad_vitality(partial)

    assert_eq(full_vitality, 795)
    assert_eq(partial_vitality, 477)

    return ()
end

@external
func test_get_troop_population{range_check_ptr}():
    alloc_locals

    let (full : Squad) = build_default_squad()
    let (partial : Squad) = build_partial_squad()
    let (packed_full) = Combat.pack_squad(full)
    let (packed_partial) = Combat.pack_squad(partial)

    let (full_pop) = Combat.get_troop_population(packed_full)
    let (partial_pop) = Combat.get_troop_population(packed_partial)

    assert_eq(full_pop, 15)
    assert_eq(partial_pop, 9)

    return ()
end

# TODO:
# test_run_combat_loop
# test_attack
# test_compute_min_roll_to_hit

@external
func test_hit_squad{range_check_ptr}():
    alloc_locals

    let (full : Squad) = build_default_squad()

    # full kill
    let (hit : Squad) = Combat.hit_squad(full, 15 * 53 + 1)
    let (vitality) = Combat.compute_squad_vitality(hit)
    assert_eq(vitality, 0)

    # partial kill
    let (hit : Squad) = Combat.hit_squad(full, 8 * 53 + 20)
    let (vitality) = Combat.compute_squad_vitality(hit)
    assert_eq(vitality, (15 * 53) - (8 * 53 + 20))
    assert_eq(hit.t1_9.vitality, 53 - 20)
    assert_eq(hit.t2_1.vitality, 53)

    # partial kill of partial squad
    let (partial : Squad) = build_partial_squad()
    let (hit : Squad) = Combat.hit_squad(partial, 6 * 53 + 30)
    let (vitality) = Combat.compute_squad_vitality(hit)
    assert_eq(vitality, (9 * 53) - (6 * 53 + 30))
    assert_eq(hit.t1_5.vitality, 0)
    assert_eq(hit.t2_1.vitality, 0)
    assert_eq(hit.t2_2.vitality, 53 - 30)

    return ()
end

@external
func test_hit_troop{range_check_ptr}():
    alloc_locals

    let (empty : Troop*) = build_empty_troop()

    # full kill
    let (skirmisher : Troop*) = build_troop(TroopId.Skirmisher)
    let (hit : Troop, remaining : felt) = Combat.hit_troop([skirmisher], 80)
    assert_troop_eq(hit, [empty])
    assert_eq(remaining, 80 - skirmisher.vitality)

    # injury
    let (mage : Troop*) = build_troop(TroopId.Mage)
    let (hit : Troop, remaining : felt) = Combat.hit_troop([mage], 20)
    tempvar expected = new Troop(mage.id, mage.type, mage.tier, mage.building, mage.agility,
        mage.attack, mage.armor, mage.vitality - 20, mage.wisdom)
    assert_troop_eq(hit, [expected])
    assert_eq(remaining, 0)

    # no hit
    let (knight : Troop*) = build_troop(TroopId.Knight)
    let (hit : Troop, remaining : felt) = Combat.hit_troop([knight], 0)
    assert_troop_eq(hit, [knight])
    assert_eq(remaining, 0)

    return ()
end

# test_load_troop_costs
# test_transform_costs_to_token_ids_values
# test_add_troops_to_squad
# test_remove_troops_from_squad
# test_find_first_free_troop_slot_in_squad
# test_get_set_troop_costs
# test_update_squad_in_realm

#
# helper functions
#

# TODO: maybe return an instance of Troop, not a Troop* in the build troop fns

func build_troop{range_check_ptr}(troop_id) -> (troop : Troop*):
    let (
        type, tier, building, agility, attack, armor, vitality, wisdom
    ) = Combat.get_troop_properties(troop_id)
    return (new Troop(troop_id, type, tier, building, agility, attack, armor, vitality, wisdom))
end

func build_empty_troop() -> (troop : Troop*):
    return (new Troop(0, 0, 0, 0, 0, 0, 0, 0, 0))
end

func build_default_squad{range_check_ptr}() -> (s : Squad):
    let t1_1 : Troop* = build_troop(TroopId.Skirmisher)
    let t1_2 : Troop* = build_troop(TroopId.Skirmisher)
    let t1_3 : Troop* = build_troop(TroopId.Skirmisher)
    let t1_4 : Troop* = build_troop(TroopId.Skirmisher)
    let t1_5 : Troop* = build_troop(TroopId.Skirmisher)
    let t1_6 : Troop* = build_troop(TroopId.Skirmisher)
    let t1_7 : Troop* = build_troop(TroopId.Skirmisher)
    let t1_8 : Troop* = build_troop(TroopId.Skirmisher)
    let t1_9 : Troop* = build_troop(TroopId.Skirmisher)

    let t2_1 : Troop* = build_troop(TroopId.Longbow)
    let t2_2 : Troop* = build_troop(TroopId.Longbow)
    let t2_3 : Troop* = build_troop(TroopId.Longbow)
    let t2_4 : Troop* = build_troop(TroopId.Longbow)
    let t2_5 : Troop* = build_troop(TroopId.Longbow)

    let t3_1 : Troop* = build_troop(TroopId.Crossbow)

    return (
        Squad(
        [t1_1], [t1_2], [t1_3], [t1_4], [t1_5], [t1_6], [t1_7],
        [t1_8], [t1_9], [t2_1], [t2_2], [t2_3], [t2_4], [t2_5], [t3_1]),
    )
end

func build_partial_squad{range_check_ptr}() -> (s : Squad):
    let t1_1 : Troop* = build_troop(TroopId.Skirmisher)
    let t1_2 : Troop* = build_troop(TroopId.Skirmisher)
    let t1_3 : Troop* = build_troop(TroopId.Skirmisher)
    let t1_4 : Troop* = build_troop(TroopId.Skirmisher)
    let t1_5 : Troop* = build_troop(TroopId.Skirmisher)
    let t1_6 : Troop* = build_empty_troop()
    let t1_7 : Troop* = build_empty_troop()
    let t1_8 : Troop* = build_empty_troop()
    let t1_9 : Troop* = build_empty_troop()

    let t2_1 : Troop* = build_troop(TroopId.Longbow)
    let t2_2 : Troop* = build_troop(TroopId.Longbow)
    let t2_3 : Troop* = build_troop(TroopId.Longbow)
    let t2_4 : Troop* = build_empty_troop()
    let t2_5 : Troop* = build_empty_troop()

    let t3_1 : Troop* = build_troop(TroopId.Crossbow)

    return (
        Squad(
        [t1_1], [t1_2], [t1_3], [t1_4], [t1_5], [t1_6], [t1_7],
        [t1_8], [t1_9], [t2_1], [t2_2], [t2_3], [t2_4], [t2_5], [t3_1]),
    )
end

#
# helper asserts
#

func assert_arrays_eq(a1 : felt*, a2 : felt*, size : felt):
    if size == 0:
        return ()
    end
    assert a1[0] = a2[0]
    return assert_arrays_eq(a1 + 1, a2 + 1, size - 1)
end

func assert_troop_eq(t1 : Troop, t2 : Troop):
    assert t1.id = t2.id
    assert t1.type = t2.type
    assert t1.tier = t2.tier
    assert t1.building = t2.building
    assert t1.agility = t2.agility
    assert t1.attack = t2.attack
    assert t1.armor = t2.armor
    assert t1.vitality = t2.vitality
    assert t1.wisdom = t2.wisdom
    return ()
end
