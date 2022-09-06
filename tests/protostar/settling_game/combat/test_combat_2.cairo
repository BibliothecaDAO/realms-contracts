%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from contracts.settling_game.modules.combat.library import Combat, Army, Battalion, ArmyStatistics
from contracts.settling_game.modules.combat.constants import BattalionDefence

namespace TestAttackingArmy:
    namespace LightCavalry:
        const quantity = 2
        const health = 100
    end
    namespace HeavyCavalry:
        const quantity = 2
        const health = 100
    end
    namespace Archer:
        const quantity = 2
        const health = 100
    end
    namespace Longbow:
        const quantity = 2
        const health = 100
    end
    namespace Mage:
        const quantity = 2
        const health = 100
    end
    namespace Arcanist:
        const quantity = 2
        const health = 100
    end
    namespace LightInfantry:
        const quantity = 2
        const health = 100
    end
    namespace HeavyInfantry:
        const quantity = 2
        const health = 100
    end
end

namespace TestDefendingArmy:
    namespace LightCavalry:
        const quantity = 1
        const health = 100
    end
    namespace HeavyCavalry:
        const quantity = 1
        const health = 100
    end
    namespace Archer:
        const quantity = 10
        const health = 100
    end
    namespace Longbow:
        const quantity = 2
        const health = 100
    end
    namespace Mage:
        const quantity = 2
        const health = 100
    end
    namespace Arcanist:
        const quantity = 2
        const health = 100
    end
    namespace LightInfantry:
        const quantity = 2
        const health = 100
    end
    namespace HeavyInfantry:
        const quantity = 1
        const health = 100
    end
end
@external
func test_squad{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let attacking_army = Army(
        Battalion(TestAttackingArmy.LightCavalry.quantity,
        TestAttackingArmy.LightCavalry.health),
        Battalion(TestAttackingArmy.HeavyCavalry.quantity,
        TestAttackingArmy.HeavyCavalry.health),
        Battalion(TestAttackingArmy.Archer.quantity,
        TestAttackingArmy.Archer.health),
        Battalion(TestAttackingArmy.Longbow.quantity,
        TestAttackingArmy.Longbow.health),
        Battalion(TestAttackingArmy.Mage.quantity,
        TestAttackingArmy.Mage.health),
        Battalion(TestAttackingArmy.Arcanist.quantity,
        TestAttackingArmy.Arcanist.health),
        Battalion(TestAttackingArmy.LightInfantry.quantity,
        TestAttackingArmy.LightInfantry.health),
        Battalion(TestAttackingArmy.HeavyInfantry.quantity,
        TestAttackingArmy.HeavyInfantry.health),
    )

    let (packed_army) = Combat.pack_army(attacking_army)

    let (unpacked_army : Army) = Combat.unpack_army(packed_army)

    assert TestAttackingArmy.LightCavalry.quantity = unpacked_army.LightCavalry.quantity
    assert TestAttackingArmy.HeavyInfantry.quantity = unpacked_army.HeavyInfantry.quantity

    return ()
end

@external
func test_statistics{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let attacking_army = Army(
        Battalion(TestAttackingArmy.LightCavalry.quantity,
        TestAttackingArmy.LightCavalry.health),
        Battalion(TestAttackingArmy.HeavyCavalry.quantity,
        TestAttackingArmy.HeavyCavalry.health),
        Battalion(TestAttackingArmy.Archer.quantity,
        TestAttackingArmy.Archer.health),
        Battalion(TestAttackingArmy.Longbow.quantity,
        TestAttackingArmy.Longbow.health),
        Battalion(TestAttackingArmy.Mage.quantity,
        TestAttackingArmy.Mage.health),
        Battalion(TestAttackingArmy.Arcanist.quantity,
        TestAttackingArmy.Arcanist.health),
        Battalion(TestAttackingArmy.LightInfantry.quantity,
        TestAttackingArmy.LightInfantry.health),
        Battalion(TestAttackingArmy.HeavyInfantry.quantity,
        TestAttackingArmy.HeavyInfantry.health),
    )

    let (packed_army) = Combat.pack_army(attacking_army)

    let (unpacked_army : ArmyStatistics) = Combat.calculate_army_statistics(packed_army)

    return ()
end

@external
func test_winner{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let attacking_army = Army(
        Battalion(TestAttackingArmy.LightCavalry.quantity,
        TestAttackingArmy.LightCavalry.health),
        Battalion(TestAttackingArmy.HeavyCavalry.quantity,
        TestAttackingArmy.HeavyCavalry.health),
        Battalion(TestAttackingArmy.Archer.quantity,
        TestAttackingArmy.Archer.health),
        Battalion(TestAttackingArmy.Longbow.quantity,
        TestAttackingArmy.Longbow.health),
        Battalion(TestAttackingArmy.Mage.quantity,
        TestAttackingArmy.Mage.health),
        Battalion(TestAttackingArmy.Arcanist.quantity,
        TestAttackingArmy.Arcanist.health),
        Battalion(TestAttackingArmy.LightInfantry.quantity,
        TestAttackingArmy.LightInfantry.health),
        Battalion(TestAttackingArmy.HeavyInfantry.quantity,
        TestAttackingArmy.HeavyInfantry.health),
    )

    let (attacking_army_packed) = Combat.pack_army(attacking_army)

    let defending_army = Army(
        Battalion(TestDefendingArmy.LightCavalry.quantity,
        TestDefendingArmy.LightCavalry.health),
        Battalion(TestDefendingArmy.HeavyCavalry.quantity,
        TestDefendingArmy.HeavyCavalry.health),
        Battalion(TestDefendingArmy.Archer.quantity,
        TestDefendingArmy.Archer.health),
        Battalion(TestDefendingArmy.Longbow.quantity,
        TestDefendingArmy.Longbow.health),
        Battalion(TestDefendingArmy.Mage.quantity,
        TestDefendingArmy.Mage.health),
        Battalion(TestDefendingArmy.Arcanist.quantity,
        TestDefendingArmy.Arcanist.health),
        Battalion(TestDefendingArmy.LightInfantry.quantity,
        TestDefendingArmy.LightInfantry.health),
        Battalion(TestDefendingArmy.HeavyInfantry.quantity,
        TestDefendingArmy.HeavyInfantry.health),
    )

    let (defending_army_packed) = Combat.pack_army(defending_army)

    let luck = 125

    let (outcome) = Combat.calculate_winner(luck, attacking_army_packed, defending_army_packed)

    %{ print('wins:', ids.outcome) %}

    return ()
end

@external
func test_calculate_total_battalions{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let attacking_army : Army = Army(
        Battalion(TestAttackingArmy.LightCavalry.quantity,
        TestAttackingArmy.LightCavalry.health),
        Battalion(TestAttackingArmy.HeavyCavalry.quantity,
        TestAttackingArmy.HeavyCavalry.health),
        Battalion(TestAttackingArmy.Archer.quantity,
        TestAttackingArmy.Archer.health),
        Battalion(TestAttackingArmy.Longbow.quantity,
        TestAttackingArmy.Longbow.health),
        Battalion(TestAttackingArmy.Mage.quantity,
        TestAttackingArmy.Mage.health),
        Battalion(TestAttackingArmy.Arcanist.quantity,
        TestAttackingArmy.Arcanist.health),
        Battalion(TestAttackingArmy.LightInfantry.quantity,
        TestAttackingArmy.LightInfantry.health),
        Battalion(TestAttackingArmy.HeavyInfantry.quantity,
        TestAttackingArmy.HeavyInfantry.health),
    )

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

    let attacking_army : Army = Army(
        Battalion(TestAttackingArmy.LightCavalry.quantity,
        TestAttackingArmy.LightCavalry.health),
        Battalion(TestAttackingArmy.HeavyCavalry.quantity,
        TestAttackingArmy.HeavyCavalry.health),
        Battalion(TestAttackingArmy.Archer.quantity,
        TestAttackingArmy.Archer.health),
        Battalion(TestAttackingArmy.Longbow.quantity,
        TestAttackingArmy.Longbow.health),
        Battalion(TestAttackingArmy.Mage.quantity,
        TestAttackingArmy.Mage.health),
        Battalion(TestAttackingArmy.Arcanist.quantity,
        TestAttackingArmy.Arcanist.health),
        Battalion(TestAttackingArmy.LightInfantry.quantity,
        TestAttackingArmy.LightInfantry.health),
        Battalion(TestAttackingArmy.HeavyInfantry.quantity,
        TestAttackingArmy.HeavyInfantry.health),
    )

    let (packed_army) = Combat.pack_army(attacking_army)

    let (unpacked_army) = Combat.unpack_army(packed_army)

    let (total_battalions) = Combat.calculate_attacker_health_remaining(100, 4, 12, 100, 70)

    %{ print('health:', ids.total_battalions) %}

    return ()
end
