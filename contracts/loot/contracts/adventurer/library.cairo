# BUILDINGS LIBRARY
#   functions for
#
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le, assert_nn
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.registers import get_label_location

from contracts.loot.contracts.stats.item import Statistics
from contracts.loot.item.library_item import LootItems
from contracts.settling_game.utils.general import unpack_data
from contracts.settling_game.utils.constants import SHIFT_41

namespace SHIFT_ADVENTURER:
    const _1 = 2 ** 0
    const _2 = 2 ** 4
    const _3 = 2 ** 14
    const _4 = 2 ** 18
    const _5 = 2 ** 38
end

namespace CalculateAdventurer:
    func _items{syscall_ptr : felt*, range_check_ptr}(
        weapon : Item,
        chest : Item,
        head : Item,
        waist : Item,
        feet : Item,
        hands : Item,
        neck : Item,
        ring : Item,
    ) -> (Agility, Attack, Armour, Wisdom, Vitality):
        alloc_locals

        # computed
        let (
            weapon_agility, weapon_attack, weapon_armour, weapon_wisdom, weapon_vitality
        ) = LootItems.calculate_item_stats(weapon)
        let (
            chest_agility, chest_attack, chest_armour, chest_wisdom, chest_vitality
        ) = LootItems.calculate_item_stats(chest)
        let (
            head_agility, head_attack, head_armour, head_wisdom, head_vitality
        ) = LootItems.calculate_item_stats(head)
        let (
            waist_agility, waist_attack, waist_armour, waist_wisdom, waist_vitality
        ) = LootItems.calculate_item_stats(waist)
        let (
            feet_agility, feet_attack, feet_armour, feet_wisdom, feet_vitality
        ) = LootItems.calculate_item_stats(feet)
        let (
            hands_agility, hands_attack, hands_armour, hands_wisdom, hands_vitality
        ) = LootItems.calculate_item_stats(hands)
        let (
            neck_agility, neck_attack, neck_armour, neck_wisdom, neck_vitality
        ) = LootItems.calculate_item_stats(neck)
        let (
            ring_agility, ring_attack, ring_armour, ring_wisdom, ring_vitality
        ) = LootItems.calculate_item_stats(ring)

        let agility = weapon_agility + chest_agility + head_agility + waist_agility + feet_agility + hands_agility + neck_agility + ring_agility
        let attack = weapon_attack + chest_attack + head_attack + waist_attack + feet_attack + hands_attack + neck_attack + ring_attack
        let armour = weapon_armour + chest_armour + head_armour + waist_armour + feet_armour + hands_armour + neck_armour + ring_armour
        let wisdom = weapon_wisdom + chest_wisdom + head_wisdom + waist_wisdom + feet_wisdom + hands_wisdom + neck_wisdom + ring_wisdom
        let vitality = weapon_vitality + chest_vitality + head_vitality + waist_vitality + feet_vitality + hands_vitality + neck_vitality + ring_vitality

        return (agility, attack, armour, wisdom, vitality)
    end

    func _stats{syscall_ptr : felt*, range_check_ptr}(adventurer : Adventurer) -> (
        agility, attack, armour, wisdom, vitality
    ):
        alloc_locals

        let (agility, attack, armour, wisdom, vitality) = _items(
            adventurer.Weapon,
            adventurer.Chest,
            adventurer.Head,
            adventurer.Waist,
            adventurer.Feet,
            adventurer.Hands,
            adventurer.Neck,
            adventurer.Ring,
        )

        let adventurer = Adventurer(
            adventurer.Class,
            agility,
            attack,
            armour,
            wisdom,
            vitality,
            adventurer.Neck,
            adventurer.Weapon,
            adventurer.Ring,
            adventurer.Chest,
            adventurer.Head,
            adventurer.Waist,
            adventurer.Feet,
            adventurer.Hands,
            adventurer.Age,
            adventurer.Name,
            adventurer.XP,
            adventurer.Order,
        )

        return (adventurer)
    end

    func _unpack_adventurer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(packed_adventurer : PackedAdventurerStats) -> (adventurer : AdventurerState):
        alloc_locals

        let (Class) = unpack_data(packed_adventurer.p1, 0, 15)  # 4
        let (Age) = unpack_data(packed_adventurer.p1, 4, 1023)  # 10
        let (Name) = unpack_data(packed_adventurer.p1, 14, 15)  # 4
        let (Order) = unpack_data(packed_adventurer.p1, 18, 15)  # 4 TODO: fix
        let (XP) = unpack_data(packed_adventurer.p1, 38, 2199023255551)  # 30

        let (Neck) = unpack_data(packed_adventurer.p2, 0, 2199023255551)  # 41
        let (Weapon) = unpack_data(packed_adventurer.p2, 41, 2199023255551)  # 41
        let (Ring) = unpack_data(packed_adventurer.p2, 82, 2199023255551)  # 41
        let (Chest) = unpack_data(packed_adventurer.p2, 123, 2199023255551)  # 41

        let (Head) = unpack_data(packed_adventurer.p3, 0, 2199023255551)  # 41
        let (Waist) = unpack_data(packed_adventurer.p3, 41, 2199023255551)  # 41
        let (Feet) = unpack_data(packed_adventurer.p3, 82, 2199023255551)  # 41
        let (Hands) = unpack_data(packed_adventurer.p3, 123, 2199023255551)  # 41

        let adventurer = AdventurerState(
            Class, Age, Name, XP, Order, Neck, Weapon, Ring, Chest, Head, Waist, Feet, Hands
        )

        return (adventurer)
    end

    func _pack_adventurer{syscall_ptr : felt*, range_check_ptr}(
        unpacked_adventurer : AdventurerState
    ) -> (packed_adventurer : PackedAdventurerStats):
        alloc_locals

        let Class = unpacked_adventurer.Class * SHIFT_ADVENTURER._1  # 4
        let Age = unpacked_adventurer.Age * SHIFT_ADVENTURER._2  # 10
        let Name = unpacked_adventurer.Name * SHIFT_ADVENTURER._3  # 10
        let Order = unpacked_adventurer.Order * SHIFT_ADVENTURER._4  # 4
        let XP = unpacked_adventurer.XP * SHIFT_ADVENTURER._5  # 30

        let Neck = unpacked_adventurer.NeckId * SHIFT_41._1  # 41
        let Weapon = unpacked_adventurer.WeaponId * SHIFT_41._2  # 41
        let Ring = unpacked_adventurer.RingId * SHIFT_41._3  # 41
        let Chest = unpacked_adventurer.ChestId * SHIFT_41._4  # 41

        let Head = unpacked_adventurer.HeadId * SHIFT_41._1  # 41
        let Waist = unpacked_adventurer.WaistId * SHIFT_41._2  # 41
        let Feet = unpacked_adventurer.FeetId * SHIFT_41._3  # 41
        let Hands = unpacked_adventurer.HandsId * SHIFT_41._4  # 41

        let p1 = XP + Order + Name + Age + Class
        let p2 = Chest + Ring + Weapon + Neck
        let p3 = Head + Waist + Feet + Hands

        let packedAdventurer = PackedAdventurerStats(p1, p2, p3)

        return (packedAdventurer)
    end

    func _equip_item{syscall_ptr : felt*, range_check_ptr}(
        item_token_id : felt, item : Item, unpacked_adventurer : AdventurerState
    ) -> (success : felt):
        alloc_locals

        if item.Slot == Slot.Neck:
            let Neck = item_token_id * SHIFT_41._1
        end

        return (0)
    end
end
