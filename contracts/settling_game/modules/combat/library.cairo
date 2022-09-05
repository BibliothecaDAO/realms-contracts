# -----------------------------------
#   COMBAT
#   Logic around calculating distance between two points in Euclidean space.
#
#
#
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_nn_le, is_nn, is_le
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.settling_game.utils.general import unpack_data
from contracts.settling_game.modules.combat.constants import BattalionDefence

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

namespace BattlionIds:
    const LightCavalry = 1
    const HeavyCavalry = 2
    const Archer = 3
    const Longbow = 4
    const Mage = 5
    const Arcanist = 6
    const LightInfantry = 7
    const HeavyInfantry = 8
end

namespace Combat:
    func unpack_army{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(army_packed : felt) -> (army : Army):
        alloc_locals

        let (light_cavalry_quantity) = unpack_data(army_packed, 0, 31)  # 5
        let (heavy_cavalry_quantity) = unpack_data(army_packed, 5, 31)  # 5
        let (archer_quantity) = unpack_data(army_packed, 10, 31)  # 5
        let (longbow_quantity) = unpack_data(army_packed, 15, 31)  # 5
        let (mage_quantity) = unpack_data(army_packed, 20, 31)  # 5
        let (archanist_quantity) = unpack_data(army_packed, 25, 31)  # 5
        let (light_infantry_quantity) = unpack_data(army_packed, 30, 31)  # 5
        let (heavy_infantry_quantity) = unpack_data(army_packed, 35, 31)  # 5

        let (light_cavalry_health) = unpack_data(army_packed, 42, 127)  # 7
        let (heavy_cavalry_health) = unpack_data(army_packed, 49, 127)  # 7
        let (archer_health) = unpack_data(army_packed, 56, 127)  # 7
        let (longbow_health) = unpack_data(army_packed, 63, 127)  # 7
        let (mage_health) = unpack_data(army_packed, 70, 127)  # 7
        let (arcanist_health) = unpack_data(army_packed, 77, 127)  # 7
        let (light_infantry_health) = unpack_data(army_packed, 84, 127)  # 7
        let (heavy_infantry_health) = unpack_data(army_packed, 91, 127)  # 7

        return (
            army=(Army(Battalion(light_cavalry_quantity, light_cavalry_health), Battalion(heavy_cavalry_quantity, heavy_cavalry_health), Battalion(archer_quantity, archer_health), Battalion(longbow_quantity, longbow_health), Battalion(mage_quantity, mage_health), Battalion(archanist_quantity, arcanist_health), Battalion(light_infantry_quantity, light_infantry_health), Battalion(heavy_infantry_quantity, heavy_infantry_health))),
        )
    end

    func pack_army{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(army_unpacked : Army) -> (packed_army : felt):
        alloc_locals

        let light_cavalry_quantity = army_unpacked.LightCavalry.quantity * SHIFT_ARMY._1
        let heavy_cavalry_quantity = army_unpacked.HeavyCavalry.quantity * SHIFT_ARMY._2
        let archer_quantity = army_unpacked.Archer.quantity * SHIFT_ARMY._3
        let longbow_quantity = army_unpacked.Longbow.quantity * SHIFT_ARMY._4
        let mage_quantity = army_unpacked.Mage.quantity * SHIFT_ARMY._5
        let archanist_quantity = army_unpacked.Arcanist.quantity * SHIFT_ARMY._6
        let light_infantry_quantity = army_unpacked.LightInfantry.quantity * SHIFT_ARMY._7
        let heavy_infantry_quantity = army_unpacked.HeavyInfantry.quantity * SHIFT_ARMY._8

        let light_cavalry_health = army_unpacked.LightCavalry.health * SHIFT_ARMY._9
        let heavy_cavalry_health = army_unpacked.HeavyCavalry.health * SHIFT_ARMY._10
        let archer_health = army_unpacked.Archer.health * SHIFT_ARMY._11
        let longbow_health = army_unpacked.Longbow.health * SHIFT_ARMY._12
        let mage_health = army_unpacked.Mage.health * SHIFT_ARMY._13
        let arcanist_health = army_unpacked.Arcanist.health * SHIFT_ARMY._14
        let light_infantry_health = army_unpacked.LightInfantry.health * SHIFT_ARMY._15
        let heavy_infantry_health = army_unpacked.HeavyInfantry.health * SHIFT_ARMY._16

        let packed = heavy_infantry_health + light_infantry_health + arcanist_health + mage_health + longbow_health + archer_health + heavy_cavalry_health + light_cavalry_health + heavy_infantry_quantity + light_infantry_quantity + archanist_quantity + mage_quantity + longbow_quantity + archer_quantity + heavy_cavalry_quantity + light_cavalry_quantity
        return (packed)
    end

    func calculate_army_statistics{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(army_packed : felt) -> (statistics : ArmyStatistics):
        alloc_locals

        let (unpacked_army : Army) = unpack_army(army_packed)

        let (cavalry_attack) = calculate_attack_values(
            BattlionIds.LightCavalry,
            unpacked_army.LightCavalry.quantity,
            BattlionIds.HeavyCavalry,
            unpacked_army.HeavyCavalry.quantity,
        )
        let (archery_attack) = calculate_attack_values(
            BattlionIds.Archer,
            unpacked_army.Archer.quantity,
            BattlionIds.Longbow,
            unpacked_army.Longbow.quantity,
        )
        let (magic_attack) = calculate_attack_values(
            BattlionIds.Mage,
            unpacked_army.Mage.quantity,
            BattlionIds.Arcanist,
            unpacked_army.Arcanist.quantity,
        )
        let (infantry_attack) = calculate_attack_values(
            BattlionIds.LightInfantry,
            unpacked_army.LightInfantry.quantity,
            BattlionIds.HeavyInfantry,
            unpacked_army.HeavyInfantry.quantity,
        )

        let (cavalry_defence, archer_defence, magic_defence, infantry_defence) = all_defence_value(
            unpacked_army
        )

        return (
            ArmyStatistics(cavalry_attack, archery_attack, magic_attack, infantry_attack, cavalry_defence, archer_defence, magic_defence, infantry_defence),
        )
    end

    # calculates attack of all battalions
    func calculate_attack_values{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        unit_1_id : felt, unit_1_number : felt, unit_2_id : felt, unit_2_number : felt
    ) -> (attack : felt):
        alloc_locals

        let (unit_1_attack_value) = attack_value(unit_1_id)
        let (unit_2_attack_value) = attack_value(unit_2_id)

        return (unit_1_attack_value * unit_1_number + unit_2_attack_value * unit_2_number)
    end

    # fetches attack constants
    func attack_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        unit_id : felt
    ) -> (attack : felt):
        alloc_locals

        let (type_label) = get_label_location(unit_attack)

        return ([type_label + unit_id - 1])

        unit_attack:
        dw 20
        dw 30
        dw 20
        dw 30
        dw 20
        dw 30
        dw 20
        dw 30
    end

    # calculates defence values
    func calculate_defence_values{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(defense_sum : felt, total_battalions : felt, unit_battalions : felt) -> (defence : felt):
        alloc_locals

        let (percentage_of_battalions, _) = unsigned_div_rem(
            unit_battalions * 100, total_battalions
        )

        let (values, _) = unsigned_div_rem(defense_sum * percentage_of_battalions, 100)

        return (values)
    end

    # TODO: Add in the 1 for the missing battalions
    func calculate_total_battalions{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(army : Army) -> (total_battalions : felt):
        alloc_locals

        return (
            army.LightCavalry.quantity + army.HeavyCavalry.quantity + army.Archer.quantity + army.Longbow.quantity + army.Mage.quantity + army.Arcanist.quantity + army.LightInfantry.quantity + army.HeavyInfantry.quantity,
        )
    end

    # TODO: Add in real values
    func all_defence_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        army : Army
    ) -> (cavalry_defence, archer_defence, magic_defence, infantry_defence):
        alloc_locals

        let (total_battalions) = calculate_total_battalions(army)

        let c_defence = army.LightCavalry.quantity * BattalionDefence.Cavalry.LightCavalry + army.HeavyCavalry.quantity * BattalionDefence.Cavalry.HeavyCavalry + army.Archer.quantity * BattalionDefence.Cavalry.Archer + army.Longbow.quantity * BattalionDefence.Cavalry.Longbow + army.Mage.quantity * BattalionDefence.Cavalry.Mage + army.Arcanist.quantity * BattalionDefence.Cavalry.Arcanist + army.LightInfantry.quantity * BattalionDefence.Cavalry.LightInfantry + army.HeavyInfantry.quantity * BattalionDefence.Cavalry.HeavyInfantry

        let a_defence = army.LightCavalry.quantity * BattalionDefence.Archery.LightCavalry + army.HeavyCavalry.quantity * BattalionDefence.Archery.HeavyCavalry + army.Archer.quantity * BattalionDefence.Archery.Archer + army.Longbow.quantity * BattalionDefence.Archery.Longbow + army.Mage.quantity * BattalionDefence.Archery.Mage + army.Arcanist.quantity * BattalionDefence.Archery.Arcanist + army.LightInfantry.quantity * BattalionDefence.Archery.LightInfantry + army.HeavyInfantry.quantity * BattalionDefence.Archery.HeavyInfantry

        let m_defence = army.LightCavalry.quantity * BattalionDefence.Magic.LightCavalry + army.HeavyCavalry.quantity * BattalionDefence.Magic.HeavyCavalry + army.Archer.quantity * BattalionDefence.Magic.Archer + army.Longbow.quantity * BattalionDefence.Magic.Longbow + army.Mage.quantity * BattalionDefence.Magic.Mage + army.Arcanist.quantity * BattalionDefence.Magic.Arcanist + army.LightInfantry.quantity * BattalionDefence.Magic.LightInfantry + army.HeavyInfantry.quantity * BattalionDefence.Magic.HeavyInfantry

        let i_defence = army.LightCavalry.quantity * BattalionDefence.Infantry.LightCavalry + army.HeavyCavalry.quantity * BattalionDefence.Infantry.HeavyCavalry + army.Archer.quantity * BattalionDefence.Infantry.Archer + army.Longbow.quantity * BattalionDefence.Infantry.Longbow + army.Mage.quantity * BattalionDefence.Infantry.Mage + army.Arcanist.quantity * BattalionDefence.Infantry.Arcanist + army.LightInfantry.quantity * BattalionDefence.Infantry.LightInfantry + army.HeavyInfantry.quantity * BattalionDefence.Infantry.HeavyInfantry

        let (cavalry_defence) = calculate_defence_values(
            c_defence, total_battalions, army.LightCavalry.quantity + army.HeavyCavalry.quantity
        )
        let (archer_defence) = calculate_defence_values(
            a_defence, total_battalions, army.Archer.quantity + army.Longbow.quantity
        )
        let (magic_defence) = calculate_defence_values(
            m_defence, total_battalions, army.Mage.quantity + army.Arcanist.quantity
        )
        let (infantry_defence) = calculate_defence_values(
            i_defence, total_battalions, army.LightInfantry.quantity + army.HeavyInfantry.quantity
        )
        return (cavalry_defence, archer_defence, magic_defence, infantry_defence)
    end

    # luck -> 75-125 random number
    func calculate_luck_outcome{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        luck : felt, attacking_statistics : felt, defending_statistics : felt
    ) -> (outcome : felt):
        alloc_locals

        let (luck, _) = unsigned_div_rem(attacking_statistics * luck, 100)

        return (luck - defending_statistics)
    end

    func calculate_winner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(luck : felt, attack_army_packed : felt, defending_army_packed : felt) -> (outcome : felt):
        alloc_locals

        let (attack_army_statistics : ArmyStatistics) = calculate_army_statistics(
            attack_army_packed
        )
        let (defending_army_statistics : ArmyStatistics) = calculate_army_statistics(
            defending_army_packed
        )

        let (cavalry_outcome) = calculate_luck_outcome(
            luck, attack_army_statistics.CavalryAttack, defending_army_statistics.CavalryDefence
        )
        let (archery_outcome) = calculate_luck_outcome(
            luck, attack_army_statistics.ArcheryAttack, defending_army_statistics.ArcheryDefence
        )
        let (magic_outcome) = calculate_luck_outcome(
            luck, attack_army_statistics.MagicAttack, defending_army_statistics.MagicDefence
        )
        let (infantry_outcome) = calculate_luck_outcome(
            luck, attack_army_statistics.InfantryAttack, defending_army_statistics.InfantryDefence
        )

        let final_outcome = cavalry_outcome + archery_outcome + magic_outcome + infantry_outcome

        let (successful) = is_nn(final_outcome)

        if successful == TRUE:
            return (final_outcome)
        end

        return (FALSE)
    end
end
