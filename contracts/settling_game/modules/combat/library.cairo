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

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_lt
from starkware.cairo.common.math_cmp import is_nn_le, is_nn, is_le
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset
from contracts.settling_game.utils.general import unpack_data
from contracts.settling_game.modules.combat.constants import (
    BattalionStatistics,
    SHIFT_ARMY,
    Battalion,
    Army,
    ArmyStatistics,
    BattalionIds,
)
from contracts.settling_game.utils.game_structs import RealmBuildings

namespace Combat:
    func add_battalions_to_army{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        current : Army,
        battalion_ids_len : felt,
        battalion_ids : felt*,
        battalions_len : felt,
        battalions : Battalion*,
    ) -> (army : Army):
        alloc_locals

        if battalions_len == 0:
            return (current)
        end

        let (updated) = add_battalion_to_battalion(current, [battalion_ids], [battalions])

        return add_battalions_to_army(
            updated,
            battalion_ids_len - 1,
            battalion_ids + 1,
            battalions_len - 1,
            battalions + Battalion.SIZE,
        )
    end

    func add_battalion_to_battalion{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(current : Army, battalion_id : felt, battalion : Battalion) -> (army : Army):
        alloc_locals

        let (__fp__, _) = get_fp_and_pc()
        # let old = cast(&current, felt*)
        let (updated : felt*) = alloc()

        let battalion_idx = (battalion_id - 1) * Battalion.SIZE
        let old_battalion = [&current + battalion_idx]  # [&old + battalion_idx]

        memcpy(updated, &current, battalion_idx)
        memcpy(updated + battalion_idx, &battalion, Battalion.SIZE)
        memcpy(
            updated + battalion_idx + Battalion.SIZE,
            &current + battalion_idx + Battalion.SIZE,
            Army.SIZE - battalion_idx - Battalion.SIZE,
        )

        let army = cast(updated, Army*)
        return ([army])
    end

    func cast_battalin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        current : Army, battalion_id : felt, quantity : felt
    ) -> (army : Army):
        alloc_locals
        let (__fp__, _) = get_fp_and_pc()

        tempvar st = cast(&current, felt*)

        let (n) = alloc()
        assert n[0] = st[battalion_id] + quantity

        assert st[battalion_id] = n[0]

        let a = cast(st, Army*)

        return ([a])
    end

    # @notice Unpack Army
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

    # @notice Pack Army
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

    # @notice Gets statistics of Army
    # @param army_packed: packed army
    # @ returns ArmyStatistics
    func calculate_army_statistics{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(army_packed : felt) -> (statistics : ArmyStatistics):
        alloc_locals

        let (unpacked_army : Army) = unpack_army(army_packed)

        let (cavalry_attack) = calculate_attack_values(
            BattalionIds.LightCavalry,
            unpacked_army.LightCavalry.quantity,
            BattalionIds.HeavyCavalry,
            unpacked_army.HeavyCavalry.quantity,
        )
        let (archery_attack) = calculate_attack_values(
            BattalionIds.Archer,
            unpacked_army.Archer.quantity,
            BattalionIds.Longbow,
            unpacked_army.Longbow.quantity,
        )
        let (magic_attack) = calculate_attack_values(
            BattalionIds.Mage,
            unpacked_army.Mage.quantity,
            BattalionIds.Arcanist,
            unpacked_army.Arcanist.quantity,
        )
        let (infantry_attack) = calculate_attack_values(
            BattalionIds.LightInfantry,
            unpacked_army.LightInfantry.quantity,
            BattalionIds.HeavyInfantry,
            unpacked_army.HeavyInfantry.quantity,
        )

        let (cavalry_defence, archer_defence, magic_defence, infantry_defence) = all_defence_value(
            unpacked_army
        )

        return (
            ArmyStatistics(cavalry_attack, archery_attack, magic_attack, infantry_attack, cavalry_defence, archer_defence, magic_defence, infantry_defence),
        )
    end

    # @notice Gets attack value on same type battalions (Cav, Archer etc) to be used in combat formula
    # @param unit_1_id: unit id 1
    # @param unit_1_number: unit id 1
    # @param unit_2_id: unit id 2
    # @param unit_2_number: number of units
    # @ returns attack value
    func calculate_attack_values{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        unit_1_id : felt, unit_1_number : felt, unit_2_id : felt, unit_2_number : felt
    ) -> (attack : felt):
        alloc_locals

        let (unit_1_attack_value) = attack_value(unit_1_id)
        let (unit_2_attack_value) = attack_value(unit_2_id)

        return (unit_1_attack_value * unit_1_number + unit_2_attack_value * unit_2_number)
    end

    # @notice Gets attack value
    # @param battalion_id: Battalion ID
    # @ returns attack value
    func attack_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        battalion_id : felt
    ) -> (attack : felt):
        alloc_locals

        let (type_label) = get_label_location(unit_attack)

        return ([type_label + battalion_id - 1])

        unit_attack:
        dw BattalionStatistics.Attack.LightCavalry
        dw BattalionStatistics.Attack.HeavyCavalry
        dw BattalionStatistics.Attack.Archer
        dw BattalionStatistics.Attack.Longbow
        dw BattalionStatistics.Attack.Mage
        dw BattalionStatistics.Attack.Arcanist
        dw BattalionStatistics.Attack.LightInfantry
        dw BattalionStatistics.Attack.HeavyInfantry
    end

    # @notice Calculates real defence value
    # @param defense_sum: Sum of defence values
    # @param total_battalions: Total battalions of Army
    # @param unit_battalions: Qty of battalions
    # @ returns defence value
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

    # @notice Calculates total battalions
    # @param army: Unpacked Army
    # @ returns total battalions
    func calculate_total_battalions{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(army : Army) -> (total_battalions : felt):
        alloc_locals

        return (
            army.LightCavalry.quantity + army.HeavyCavalry.quantity + army.Archer.quantity + army.Longbow.quantity + army.Mage.quantity + army.Arcanist.quantity + army.LightInfantry.quantity + army.HeavyInfantry.quantity,
        )
    end

    # @notice Sums all defence values
    # @param army: Unpacked Army
    # @ returns cavalry_defence, archer_defence, magic_defence, infantry_defence
    func all_defence_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        army : Army
    ) -> (cavalry_defence, archer_defence, magic_defence, infantry_defence):
        alloc_locals

        let (total_battalions) = calculate_total_battalions(army)

        let c_defence = army.LightCavalry.quantity * BattalionStatistics.Defence.Cavalry.LightCavalry + army.HeavyCavalry.quantity * BattalionStatistics.Defence.Cavalry.HeavyCavalry + army.Archer.quantity * BattalionStatistics.Defence.Cavalry.Archer + army.Longbow.quantity * BattalionStatistics.Defence.Cavalry.Longbow + army.Mage.quantity * BattalionStatistics.Defence.Cavalry.Mage + army.Arcanist.quantity * BattalionStatistics.Defence.Cavalry.Arcanist + army.LightInfantry.quantity * BattalionStatistics.Defence.Cavalry.LightInfantry + army.HeavyInfantry.quantity * BattalionStatistics.Defence.Cavalry.HeavyInfantry

        let a_defence = army.LightCavalry.quantity * BattalionStatistics.Defence.Archery.LightCavalry + army.HeavyCavalry.quantity * BattalionStatistics.Defence.Archery.HeavyCavalry + army.Archer.quantity * BattalionStatistics.Defence.Archery.Archer + army.Longbow.quantity * BattalionStatistics.Defence.Archery.Longbow + army.Mage.quantity * BattalionStatistics.Defence.Archery.Mage + army.Arcanist.quantity * BattalionStatistics.Defence.Archery.Arcanist + army.LightInfantry.quantity * BattalionStatistics.Defence.Archery.LightInfantry + army.HeavyInfantry.quantity * BattalionStatistics.Defence.Archery.HeavyInfantry

        let m_defence = army.LightCavalry.quantity * BattalionStatistics.Defence.Magic.LightCavalry + army.HeavyCavalry.quantity * BattalionStatistics.Defence.Magic.HeavyCavalry + army.Archer.quantity * BattalionStatistics.Defence.Magic.Archer + army.Longbow.quantity * BattalionStatistics.Defence.Magic.Longbow + army.Mage.quantity * BattalionStatistics.Defence.Magic.Mage + army.Arcanist.quantity * BattalionStatistics.Defence.Magic.Arcanist + army.LightInfantry.quantity * BattalionStatistics.Defence.Magic.LightInfantry + army.HeavyInfantry.quantity * BattalionStatistics.Defence.Magic.HeavyInfantry

        let i_defence = army.LightCavalry.quantity * BattalionStatistics.Defence.Infantry.LightCavalry + army.HeavyCavalry.quantity * BattalionStatistics.Defence.Infantry.HeavyCavalry + army.Archer.quantity * BattalionStatistics.Defence.Infantry.Archer + army.Longbow.quantity * BattalionStatistics.Defence.Infantry.Longbow + army.Mage.quantity * BattalionStatistics.Defence.Infantry.Mage + army.Arcanist.quantity * BattalionStatistics.Defence.Infantry.Arcanist + army.LightInfantry.quantity * BattalionStatistics.Defence.Infantry.LightInfantry + army.HeavyInfantry.quantity * BattalionStatistics.Defence.Infantry.HeavyInfantry

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

    # @notice Calculates winner of battle
    # @param luck: Luck of Attacker - this is a number between 75-125 which adjusts the battle outcome
    # @param attack_army_packed: Attacking Army packed
    # @param defending_army_packed: Defending Army packed
    func calculate_winner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(luck : felt, attack_army_packed : felt, defending_army_packed : felt) -> (
        outcome : felt, attack_army_packed : felt, defending_army_packed : felt
    ):
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

        let (updated_attack_army_packed, updated_defence_army_packed) = get_updated_packed_armies(
            attack_army_statistics,
            defending_army_statistics,
            attack_army_packed,
            defending_army_packed,
        )

        if successful == TRUE:
            return (TRUE, updated_attack_army_packed, updated_defence_army_packed)
        end

        return (FALSE, updated_attack_army_packed, updated_defence_army_packed)
    end

    # @notice Calculates value after applying luck. All units use this.
    # @param attacking_statistics: Attacker statistics
    # @param defending_statistics: Defender statistics
    func calculate_luck_outcome{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        luck : felt, attacking_statistics : felt, defending_statistics : felt
    ) -> (outcome : felt):
        alloc_locals

        let (luck, _) = unsigned_div_rem(attacking_statistics * luck, 100)

        return (luck - defending_statistics)
    end

    # @notice calculates health of Battalion remaining after a battle
    # @param starting_health: Starting health of Battalion
    # @param battalions: Number of Battalions
    # @param total_battalions: Total Battalions in Army
    # @param counter_attack: Counter attack value
    # @param counter_defence: Counter defence value
    func calculate_health_remaining{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(
        starting_health : felt,
        battalions : felt,
        total_battalions : felt,
        counter_attack : felt,
        counter_defence : felt,
    ) -> (new_health : felt):
        alloc_locals

        let (battalion_div, _) = unsigned_div_rem(battalions * 100, total_battalions)

        let (counter_div, _) = unsigned_div_rem(counter_attack * 100, counter_defence)

        let (h, _) = unsigned_div_rem(((starting_health * counter_div) * 90), 100)

        let (actual, _) = unsigned_div_rem(h, 100)

        let health = battalion_div * actual

        let (final_health, _) = unsigned_div_rem(health, 100)

        return (final_health)
    end

    # @notice gets updated packed armies
    # @param attack_army_statistics: ArmyStatistics of attacking Army
    # @param defending_army_statistics: ArmyStatistics of defending Army
    # @param attack_army_packed: packed attacking Army
    # @param defending_army_packed: packed defending Army
    func get_updated_packed_armies{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(
        attack_army_statistics : ArmyStatistics,
        defending_army_statistics : ArmyStatistics,
        attack_army_packed : felt,
        defending_army_packed : felt,
    ) -> (attack_army_packed : felt, defending_army_packed : felt):
        alloc_locals

        let (attack_army_unpacked : Army) = unpack_army(attack_army_packed)
        let (defending_army_unpacked : Army) = unpack_army(defending_army_packed)

        let (attack_army_packed) = update_and_pack_army(
            attack_army_statistics,
            defending_army_statistics,
            attack_army_unpacked,
            defending_army_unpacked,
        )

        let (defence_army_packed) = update_and_pack_army(
            defending_army_statistics,
            attack_army_statistics,
            defending_army_unpacked,
            attack_army_unpacked,
        )

        return (attack_army_packed, defence_army_packed)
    end

    # @notice updates Army and packs
    # @param attack_army_statistics: ArmyStatistics of attacking Army
    # @param defending_army_statistics: ArmyStatistics of defending Army
    # @param attack_army_unpacked: Attacking Army
    # @param defending_army_unpacked: Defending Army
    func update_and_pack_army{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(
        attack_army_statistics : ArmyStatistics,
        defending_army_statistics : ArmyStatistics,
        attack_army_unpacked : Army,
        defending_army_unpacked : Army,
    ) -> (packed_army : felt):
        alloc_locals

        let (light_cavalry_health) = calculate_health_remaining(
            attack_army_unpacked.LightCavalry.health,
            attack_army_unpacked.LightCavalry.quantity,
            attack_army_unpacked.LightCavalry.quantity + attack_army_unpacked.HeavyCavalry.quantity,
            attack_army_statistics.InfantryAttack,
            defending_army_statistics.InfantryDefence,
        )
        let (heavy_cavalry_health) = calculate_health_remaining(
            attack_army_unpacked.HeavyCavalry.health,
            attack_army_unpacked.HeavyCavalry.quantity,
            attack_army_unpacked.LightCavalry.quantity + attack_army_unpacked.HeavyCavalry.quantity,
            attack_army_statistics.InfantryAttack,
            defending_army_statistics.InfantryDefence,
        )
        let (archer_health) = calculate_health_remaining(
            attack_army_unpacked.Archer.health,
            attack_army_unpacked.Archer.quantity,
            attack_army_unpacked.Archer.quantity + attack_army_unpacked.Longbow.quantity,
            attack_army_statistics.CavalryAttack,
            defending_army_statistics.CavalryDefence,
        )
        let (longbow_health) = calculate_health_remaining(
            attack_army_unpacked.Longbow.health,
            attack_army_unpacked.Longbow.quantity,
            attack_army_unpacked.Archer.quantity + attack_army_unpacked.Longbow.quantity,
            attack_army_statistics.CavalryAttack,
            defending_army_statistics.CavalryDefence,
        )
        let (mage_health) = calculate_health_remaining(
            attack_army_unpacked.Mage.health,
            attack_army_unpacked.Mage.quantity,
            attack_army_unpacked.Mage.quantity + attack_army_unpacked.Arcanist.quantity,
            attack_army_statistics.ArcheryAttack,
            defending_army_statistics.ArcheryDefence,
        )
        let (archanist_health) = calculate_health_remaining(
            attack_army_unpacked.Arcanist.health,
            attack_army_unpacked.Arcanist.quantity,
            attack_army_unpacked.Mage.quantity + attack_army_unpacked.Arcanist.quantity,
            attack_army_statistics.ArcheryAttack,
            defending_army_statistics.ArcheryDefence,
        )
        let (light_infantry_health) = calculate_health_remaining(
            attack_army_unpacked.LightInfantry.health,
            attack_army_unpacked.LightInfantry.quantity,
            attack_army_unpacked.LightInfantry.quantity + attack_army_unpacked.LightInfantry.quantity,
            attack_army_statistics.InfantryAttack,
            defending_army_statistics.InfantryDefence,
        )
        let (heavy_infantry_health) = calculate_health_remaining(
            attack_army_unpacked.HeavyInfantry.health,
            attack_army_unpacked.HeavyInfantry.quantity,
            attack_army_unpacked.HeavyInfantry.quantity + attack_army_unpacked.HeavyInfantry.quantity,
            attack_army_statistics.MagicAttack,
            defending_army_statistics.MagicDefence,
        )

        let updated_attacking_army = Army(
            Battalion(attack_army_unpacked.LightCavalry.quantity,
            light_cavalry_health),
            Battalion(attack_army_unpacked.HeavyCavalry.quantity,
            heavy_cavalry_health),
            Battalion(attack_army_unpacked.Archer.quantity,
            archer_health),
            Battalion(attack_army_unpacked.Longbow.quantity,
            longbow_health),
            Battalion(attack_army_unpacked.Mage.quantity,
            mage_health),
            Battalion(attack_army_unpacked.Arcanist.quantity,
            archanist_health),
            Battalion(attack_army_unpacked.LightInfantry.quantity,
            light_infantry_health),
            Battalion(attack_army_unpacked.HeavyInfantry.quantity,
            heavy_infantry_health),
        )

        let (packed_army) = pack_army(updated_attacking_army)

        return (packed_army)
    end

    # @notice Asserts can build battalions
    # @param battalion_ids: Array of Battalion IDs that you want to build
    # @param realm_buildings: A RealmBuildings struct specifying which buildings does a Realm have
    func assert_can_build_battalions{range_check_ptr}(
        battalion_ids_len : felt, battalion_ids : felt*, realm_buildings : RealmBuildings
    ):
        alloc_locals
        let (__fp__, _) = get_fp_and_pc()

        if troop_ids_len == 0:
            return ()
        end

        let (building) = get_battalion_building([battalion_ids])
        let buildings = cast(&realm_buildings, felt*)
        let buildings_in_realm : felt = [buildings + building - 1]
        with_attr error_message(
                "Combat: missing building {troop.building} to build troop {troop.id}"):
            assert_not_zero(buildings_in_realm)
        end

        return assert_can_build_battalions(
            battalion_ids_len - 1, battalion_ids + 1, realm_buildings
        )
    end

    # @notice Returns battalion building
    # @param battalion_id: Battalion ID
    # @return building id
    func get_battalion_building{range_check_ptr}(battalion_id : felt) -> (building):
        assert_not_zero(battalion_id)
        assert_lt(battalion_id, BattalionIds.SIZE)

        let (building_label) = get_label_location(battalion_building_per_id)

        return ([building_label + battalion_id - 1])

        battalion_building_per_id:
        dw BattalionStatistics.RequiredBuilding.LightCavalry
        dw BattalionStatistics.RequiredBuilding.HeavyCavalry
        dw BattalionStatistics.RequiredBuilding.Archer
        dw BattalionStatistics.RequiredBuilding.Longbow
        dw BattalionStatistics.RequiredBuilding.Mage
        dw BattalionStatistics.RequiredBuilding.Arcanist
        dw BattalionStatistics.RequiredBuilding.LightInfantry
        dw BattalionStatistics.RequiredBuilding.HeavyInfantry
    end
end
