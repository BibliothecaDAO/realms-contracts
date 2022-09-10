%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from contracts.settling_game.modules.combat.library import Combat, Army, Battalion, ArmyStatistics
from contracts.settling_game.modules.combat.constants import BattalionStatistics, BattalionIds

func build_attacking_army() -> (a : Army):
    tempvar values = new (2, 100, 2, 100, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,)
    let a = cast(values, Army*)
    return ([a])
end

func build_defending_army() -> (a : Army):
    tempvar values = new (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,)
    # tempvar values = new (1, 100, 1, 100, 10, 100, 2, 100, 2, 100, 2, 100, 2, 100, 1, 100,)
    let a = cast(values, Army*)
    return ([a])
end

# @external
# func test_squad{
#     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
# }():
#     alloc_locals

# let (attacking_army) = build_attacking_army()
#     let (packed_army) = Combat.pack_army(attacking_army)
#     let (unpacked_army : Army) = Combat.unpack_army(packed_army)

# assert unpacked_army.LightCavalry.Quantity = 2
#     assert unpacked_army.LightCavalry.Health = 100
#     assert unpacked_army.HeavyInfantry.Quantity = 0
#     assert unpacked_army.HeavyInfantry.Health = 0

# return ()
# end

# @external
# func test_statistics{
#     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
# }():
#     alloc_locals

# let (attacking_army) = build_attacking_army()
#     let (packed_army) = Combat.pack_army(attacking_army)
#     let (unpacked_army : ArmyStatistics) = Combat.calculate_army_statistics(packed_army)

# return ()
# end

@external
func test_winner{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let (attacking_army) = build_attacking_army()
    let (attacking_army_packed) = Combat.pack_army(attacking_army)

    let (defending_army) = build_defending_army()
    let (defending_army_packed) = Combat.pack_army(defending_army)

    let luck = 100

    let (
        outcome, updated_attack_army_packed, updated_defence_army_packed
    ) = Combat.calculate_winner(luck, attacking_army_packed, defending_army_packed)

    assert outcome = 1

    return ()
end

# @external
# func test_calculate_total_battalions{
#     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
# }():
#     alloc_locals

# let (attacking_army) = build_attacking_army()
#     let (packed_army) = Combat.pack_army(attacking_army)
#     let (unpacked_army) = Combat.unpack_army(packed_army)
#     let (total_battalions) = Combat.calculate_total_battalions(attacking_army)

# assert total_battalions = 12

# let c_defence = unpacked_army.LightCavalry.Quantity * BattalionStatistics.Defence.Cavalry.LightCavalry + unpacked_army.HeavyCavalry.Quantity * BattalionStatistics.Defence.Cavalry.HeavyCavalry + unpacked_army.Archer.Quantity * BattalionStatistics.Defence.Cavalry.Archer + unpacked_army.Longbow.Quantity * BattalionStatistics.Defence.Cavalry.Longbow + unpacked_army.Mage.Quantity * BattalionStatistics.Defence.Cavalry.Mage + unpacked_army.Arcanist.Quantity * BattalionStatistics.Defence.Cavalry.Arcanist + unpacked_army.LightInfantry.Quantity * BattalionStatistics.Defence.Cavalry.LightInfantry + unpacked_army.HeavyInfantry.Quantity * BattalionStatistics.Defence.Cavalry.HeavyInfantry

# let (cavalry_defence) = Combat.calculate_defence_values(
#         c_defence,
#         total_battalions,
#         unpacked_army.LightCavalry.Quantity + unpacked_army.HeavyCavalry.Quantity,
#     )

# assert cavalry_defence = c_defence

# return ()
# end

# @external
# func test_health_remaining{
#     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
# }():
#     alloc_locals

# let (attacking_army) = build_attacking_army()
#     let (packed_army) = Combat.pack_army(attacking_army)
#     let (unpacked_army) = Combat.unpack_army(packed_army)

# let (total_health, total_battalions) = Combat.calculate_health_remaining(100, 2, 3, 100, 100)

# %{ print('total_health:', ids.total_health) %}
#     %{ print('total_battalions:', ids.total_battalions) %}
#     return ()
# end

# @external
# func test_add_battalions_to_army{
#     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
# }():
#     alloc_locals

# let (attacking_army) = build_attacking_army()
#     let (packed_army) = Combat.pack_army(attacking_army)
#     let (unpacked_army) = Combat.unpack_army(packed_army)

# let (battalion_ids : felt*) = alloc()
#     assert battalion_ids[0] = BattalionIds.LightCavalry
#     assert battalion_ids[1] = BattalionIds.HeavyCavalry

# let (battalions : felt*) = alloc()
#     assert battalions[0] = 3
#     assert battalions[1] = 3

# let (total_battalions : Army) = Combat.add_battalions_to_army(
#         unpacked_army, 2, battalion_ids, 2, battalions
#     )

# assert total_battalions.LightCavalry.Quantity = battalions[0]

# return ()
# end
