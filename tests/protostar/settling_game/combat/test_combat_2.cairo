%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from contracts.settling_game.modules.combat.library import Combat, Army, Battalion, ArmyStatistics
from contracts.settling_game.modules.combat.constants import BattalionDefence, BattalionIds

func build_attacking_army() -> (a : Army):
    tempvar values = new (2, 100, 2, 100, 2, 100, 2, 100, 2, 100, 2, 100, 2, 100, 2, 100,)
    let a = cast(values, Army*)
    return ([a])
end

func build_defending_army() -> (a : Army):
    tempvar values = new (1, 100, 1, 100, 10, 100, 2, 100, 2, 100, 2, 100, 2, 100, 1, 100,)
    let a = cast(values, Army*)
    return ([a])
end

@external
func test_squad{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let (attacking_army) = build_attacking_army()
    let (packed_army) = Combat.pack_army(attacking_army)
    let (unpacked_army : Army) = Combat.unpack_army(packed_army)

    assert unpacked_army.LightCavalry.quantity = 2
    assert unpacked_army.LightCavalry.health = 100
    assert unpacked_army.HeavyInfantry.quantity = 2
    assert unpacked_army.HeavyInfantry.health = 100

    return ()
end

@external
func test_statistics{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let (attacking_army) = build_attacking_army()
    let (packed_army) = Combat.pack_army(attacking_army)
    let (unpacked_army : ArmyStatistics) = Combat.calculate_army_statistics(packed_army)

    return ()
end

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

    %{ print('outcome:', ids.outcome) %}
    %{ print('attacker:', ids.updated_attack_army_packed) %}
    %{ print('defender:', ids.updated_defence_army_packed) %}

    return ()
end

@external
func test_calculate_total_battalions{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let (attacking_army) = build_attacking_army()
    let (packed_army) = Combat.pack_army(attacking_army)
    let (unpacked_army) = Combat.unpack_army(packed_army)
    let (total_battalions) = Combat.calculate_total_battalions(attacking_army)

    %{ print('battalions:', ids.total_battalions) %}

    let c_defence = unpacked_army.LightCavalry.quantity * BattalionDefence.Cavalry.LightCavalry + unpacked_army.HeavyCavalry.quantity * BattalionDefence.Cavalry.HeavyCavalry + unpacked_army.Archer.quantity * BattalionDefence.Cavalry.Archer + unpacked_army.Longbow.quantity * BattalionDefence.Cavalry.Longbow + unpacked_army.Mage.quantity * BattalionDefence.Cavalry.Mage + unpacked_army.Arcanist.quantity * BattalionDefence.Cavalry.Arcanist + unpacked_army.LightInfantry.quantity * BattalionDefence.Cavalry.LightInfantry + unpacked_army.HeavyInfantry.quantity * BattalionDefence.Cavalry.HeavyInfantry

    let (cavalry_defence) = Combat.calculate_defence_values(
        c_defence,
        total_battalions,
        unpacked_army.LightCavalry.quantity + unpacked_army.HeavyCavalry.quantity,
    )

    %{ print('wins:', ids.cavalry_defence) %}

    return ()
end

@external
func test_health_remaining{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let (attacking_army) = build_attacking_army()
    let (packed_army) = Combat.pack_army(attacking_army)
    let (unpacked_army) = Combat.unpack_army(packed_army)

    let (total_battalions) = Combat.calculate_health_remaining(100 * 10, 2, 8, 100, 200)

    %{ print('health:', ids.total_battalions) %}

    return ()
end

@external
func test_add_battalions_to_army{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let (attacking_army) = build_attacking_army()
    let (packed_army) = Combat.pack_army(attacking_army)
    let (unpacked_army) = Combat.unpack_army(packed_army)

    let (battalion_ids : felt*) = alloc()
    assert battalion_ids[0] = BattalionIds.LightCavalry
    assert battalion_ids[1] = BattalionIds.HeavyCavalry

    let (battalions : Battalion*) = alloc()
    assert battalions[0] = Battalion(3, 20)
    assert battalions[1] = Battalion(1, 100)

    let (total_battalions : Army) = Combat.add_battalions_to_army(
        unpacked_army, 2, battalion_ids, 2, battalions
    )

    assert total_battalions.LightCavalry.quantity = 3

    # %{ print('battalions:', ids.b) %}

    return ()
end
