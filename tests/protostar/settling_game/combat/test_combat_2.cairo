%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address

from contracts.settling_game.modules.combat.library import Combat, Army, Battalion, ArmyStatistics

namespace TestAttackingArmy:
    namespace LightCavalry:
        const quantity = 3
        const health = 100
    end
    namespace HeavyCavalry:
        const quantity = 3
        const health = 100
    end
    namespace Archer:
        const quantity = 3
        const health = 100
    end
    namespace Longbow:
        const quantity = 3
        const health = 100
    end
    namespace Mage:
        const quantity = 3
        const health = 100
    end
    namespace Arcanist:
        const quantity = 3
        const health = 100
    end
    namespace LightInfantry:
        const quantity = 3
        const health = 100
    end
    namespace HeavyInfantry:
        const quantity = 3
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
