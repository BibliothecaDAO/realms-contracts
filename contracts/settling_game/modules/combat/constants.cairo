%lang starknet

from contracts.settling_game.utils.game_structs import RealmBuildingsIds

namespace BattalionStatistics:
    namespace Attack:
        const LightCavalry = 20
        const HeavyCavalry = 30
        const Archer = 20
        const Longbow = 30
        const Mage = 20
        const Arcanist = 30
        const LightInfantry = 20
        const HeavyInfantry = 30
    end
    namespace Defence:
        namespace Cavalry:
            const LightCavalry = 20
            const HeavyCavalry = 30
            const Archer = 15
            const Longbow = 25
            const Mage = 25
            const Arcanist = 35
            const LightInfantry = 25
            const HeavyInfantry = 35
        end
        namespace Archery:
            const LightCavalry = 25
            const HeavyCavalry = 35
            const Archer = 20
            const Longbow = 30
            const Mage = 15
            const Arcanist = 25
            const LightInfantry = 25
            const HeavyInfantry = 35
        end
        namespace Magic:
            const LightCavalry = 25
            const HeavyCavalry = 35
            const Archer = 25
            const Longbow = 35
            const Mage = 20
            const Arcanist = 30
            const LightInfantry = 15
            const HeavyInfantry = 25
        end
        namespace Infantry:
            const LightCavalry = 15
            const HeavyCavalry = 25
            const Archer = 25
            const Longbow = 35
            const Mage = 25
            const Arcanist = 35
            const LightInfantry = 20
            const HeavyInfantry = 30
        end
    end
    namespace RequiredBuilding:
        const LightCavalry = RealmBuildingsIds.Castle
        const HeavyCavalry = RealmBuildingsIds.Castle
        const Archer = RealmBuildingsIds.ArcherTower
        const Longbow = RealmBuildingsIds.ArcherTower
        const Mage = RealmBuildingsIds.MageTower
        const Arcanist = RealmBuildingsIds.MageTower
        const LightInfantry = RealmBuildingsIds.Barracks
        const HeavyInfantry = RealmBuildingsIds.Barracks
    end
end

namespace BattalionIds:
    const LightCavalry = 1
    const HeavyCavalry = 2
    const Archer = 3
    const Longbow = 4
    const Mage = 5
    const Arcanist = 6
    const LightInfantry = 7
    const HeavyInfantry = 8
    const SIZE = 9
end

namespace SHIFT_ARMY:
    const _1 = 2 ** 0
    const _2 = 2 ** 5
    const _3 = 2 ** 10
    const _4 = 2 ** 15
    const _5 = 2 ** 20
    const _6 = 2 ** 25
    const _7 = 2 ** 30
    const _8 = 2 ** 35

    const _9 = 2 ** 42
    const _10 = 2 ** 49
    const _11 = 2 ** 56
    const _12 = 2 ** 63
    const _13 = 2 ** 70
    const _14 = 2 ** 77
    const _15 = 2 ** 84
    const _16 = 2 ** 91
end

struct Battalion:
    member quantity : felt  # 1-23
    member health : felt  # 1-100
end

struct Army:
    member LightCavalry : Battalion
    member HeavyCavalry : Battalion
    member Archer : Battalion
    member Longbow : Battalion
    member Mage : Battalion
    member Arcanist : Battalion
    member LightInfantry : Battalion
    member HeavyInfantry : Battalion
end

struct ArmyStatistics:
    member CavalryAttack : felt  # (Light Cav Base Attack*Number of Attacking Light Cav Battalions)+(Heavy Cav Base Attack*Number of Attacking Heavy Cav Battalions)
    member ArcheryAttack : felt  # (Archer Base Attack*Number of Attacking Archer Battalions)+(Longbow Base Attack*Number of Attacking Longbow Battalions)
    member MagicAttack : felt  # (Mage Base Attack*Number of Attacking Mage Battalions)+(Arcanist Base Attack*Number of Attacking Arcanist Battalions)
    member InfantryAttack : felt  # (Light Inf Base Attack*Number of Attacking Light Inf Battalions)+(Heavy Inf Base Attack*Number of Attacking Heavy Inf Battalions)

    member CavalryDefence : felt  # (Sum of all units Cavalry Defence*Percentage of Attacking Cav Battalions)
    member ArcheryDefence : felt  # (Sum of all units Archery Defence*Percentage of Attacking Archery Battalions)
    member MagicDefence : felt  # (Sum of all units Magic Cav Defence*Percentage of Attacking Magic Battalions)
    member InfantryDefence : felt  # (Sum of all units Infantry Defence*Percentage of Attacking Infantry Battalions)
end

struct ArmyData:
    member ArmyPacked : felt
    member LastAttacked : felt
    member XP : felt
    member Level : felt
    member CallSign : felt
end
