%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from starkware.cairo.common.pow import pow

from contracts.loot.item.constants import ItemIds
from contracts.loot.adventurer.library import CalculateAdventurer
from contracts.loot.item.constants import ItemAgility, Item, Adventurer, AdventurerState
from tests.protostar.loot.consts import TestGear, TestAdventurer

@external
func test_items{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let weapon = Item(
        TestGear.Weapon.Id,
        TestGear.Weapon.Class,
        TestGear.Weapon.Slot,
        TestGear.Weapon.Agility,
        TestGear.Weapon.Attack,
        TestGear.Weapon.Armour,
        TestGear.Weapon.Wisdom,
        TestGear.Weapon.Vitality,
        TestGear.Weapon.Prefix,
        TestGear.Weapon.Suffix,
        TestGear.Weapon.Order,
        TestGear.Weapon.Bonus,
        TestGear.Weapon.Level,
        TestGear.Weapon.Age,
        TestGear.Weapon.XP,
    )

    let chest = Item(
        TestGear.Chest.Id,
        TestGear.Chest.Class,
        TestGear.Chest.Slot,
        TestGear.Chest.Agility,
        TestGear.Chest.Attack,
        TestGear.Chest.Armour,
        TestGear.Chest.Wisdom,
        TestGear.Chest.Vitality,
        TestGear.Chest.Prefix,
        TestGear.Chest.Suffix,
        TestGear.Chest.Order,
        TestGear.Chest.Bonus,
        TestGear.Chest.Level,
        TestGear.Chest.Age,
        TestGear.Chest.XP,
    )
    let head = Item(
        TestGear.Head.Id,
        TestGear.Head.Class,
        TestGear.Head.Slot,
        TestGear.Head.Agility,
        TestGear.Head.Attack,
        TestGear.Head.Armour,
        TestGear.Head.Wisdom,
        TestGear.Head.Vitality,
        TestGear.Head.Prefix,
        TestGear.Head.Suffix,
        TestGear.Head.Order,
        TestGear.Head.Bonus,
        TestGear.Head.Level,
        TestGear.Head.Age,
        TestGear.Head.XP,
    )
    let waist = Item(
        TestGear.Waist.Id,
        TestGear.Waist.Class,
        TestGear.Waist.Slot,
        TestGear.Waist.Agility,
        TestGear.Waist.Attack,
        TestGear.Waist.Armour,
        TestGear.Waist.Wisdom,
        TestGear.Waist.Vitality,
        TestGear.Waist.Prefix,
        TestGear.Waist.Suffix,
        TestGear.Waist.Order,
        TestGear.Waist.Bonus,
        TestGear.Waist.Level,
        TestGear.Waist.Age,
        TestGear.Waist.XP,
    )
    let feet = Item(
        TestGear.Feet.Id,
        TestGear.Feet.Class,
        TestGear.Feet.Slot,
        TestGear.Feet.Agility,
        TestGear.Feet.Attack,
        TestGear.Feet.Armour,
        TestGear.Feet.Wisdom,
        TestGear.Feet.Vitality,
        TestGear.Feet.Prefix,
        TestGear.Feet.Suffix,
        TestGear.Feet.Order,
        TestGear.Feet.Bonus,
        TestGear.Feet.Level,
        TestGear.Feet.Age,
        TestGear.Feet.XP,
    )
    let hands = Item(
        TestGear.Hands.Id,
        TestGear.Hands.Class,
        TestGear.Hands.Slot,
        TestGear.Hands.Agility,
        TestGear.Hands.Attack,
        TestGear.Hands.Armour,
        TestGear.Hands.Wisdom,
        TestGear.Hands.Vitality,
        TestGear.Hands.Prefix,
        TestGear.Hands.Suffix,
        TestGear.Hands.Order,
        TestGear.Hands.Bonus,
        TestGear.Hands.Level,
        TestGear.Hands.Age,
        TestGear.Hands.XP,
    )
    let neck = Item(
        TestGear.Neck.Id,
        TestGear.Neck.Class,
        TestGear.Neck.Slot,
        TestGear.Neck.Agility,
        TestGear.Neck.Attack,
        TestGear.Neck.Armour,
        TestGear.Neck.Wisdom,
        TestGear.Neck.Vitality,
        TestGear.Neck.Prefix,
        TestGear.Neck.Suffix,
        TestGear.Neck.Order,
        TestGear.Neck.Bonus,
        TestGear.Neck.Level,
        TestGear.Neck.Age,
        TestGear.Neck.XP,
    )
    let ring = Item(
        TestGear.Ring.Id,
        TestGear.Ring.Class,
        TestGear.Ring.Slot,
        TestGear.Ring.Agility,
        TestGear.Ring.Attack,
        TestGear.Ring.Armour,
        TestGear.Ring.Wisdom,
        TestGear.Ring.Vitality,
        TestGear.Ring.Prefix,
        TestGear.Ring.Suffix,
        TestGear.Ring.Order,
        TestGear.Ring.Bonus,
        TestGear.Ring.Level,
        TestGear.Ring.Age,
        TestGear.Ring.XP,
    )

    let (agility, attack, armour, wisdom, vitality) = CalculateAdventurer._items(
        weapon, chest, head, waist, feet, hands, neck, ring
    )
    return ()
end

@external
func test_compute_adventurer_stats{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let weapon = Item(
        TestGear.Weapon.Id,
        TestGear.Weapon.Class,
        TestGear.Weapon.Slot,
        TestGear.Weapon.Agility,
        TestGear.Weapon.Attack,
        TestGear.Weapon.Armour,
        TestGear.Weapon.Wisdom,
        TestGear.Weapon.Vitality,
        TestGear.Weapon.Prefix,
        TestGear.Weapon.Suffix,
        TestGear.Weapon.Order,
        TestGear.Weapon.Bonus,
        TestGear.Weapon.Level,
        TestGear.Weapon.Age,
        TestGear.Weapon.XP,
    )

    let chest = Item(
        TestGear.Chest.Id,
        TestGear.Chest.Class,
        TestGear.Chest.Slot,
        TestGear.Chest.Agility,
        TestGear.Chest.Attack,
        TestGear.Chest.Armour,
        TestGear.Chest.Wisdom,
        TestGear.Chest.Vitality,
        TestGear.Chest.Prefix,
        TestGear.Chest.Suffix,
        TestGear.Chest.Order,
        TestGear.Chest.Bonus,
        TestGear.Chest.Level,
        TestGear.Chest.Age,
        TestGear.Chest.XP,
    )
    let head = Item(
        TestGear.Head.Id,
        TestGear.Head.Class,
        TestGear.Head.Slot,
        TestGear.Head.Agility,
        TestGear.Head.Attack,
        TestGear.Head.Armour,
        TestGear.Head.Wisdom,
        TestGear.Head.Vitality,
        TestGear.Head.Prefix,
        TestGear.Head.Suffix,
        TestGear.Head.Order,
        TestGear.Head.Bonus,
        TestGear.Head.Level,
        TestGear.Head.Age,
        TestGear.Head.XP,
    )
    let waist = Item(
        TestGear.Waist.Id,
        TestGear.Waist.Class,
        TestGear.Waist.Slot,
        TestGear.Waist.Agility,
        TestGear.Waist.Attack,
        TestGear.Waist.Armour,
        TestGear.Waist.Wisdom,
        TestGear.Waist.Vitality,
        TestGear.Waist.Prefix,
        TestGear.Waist.Suffix,
        TestGear.Waist.Order,
        TestGear.Waist.Bonus,
        TestGear.Waist.Level,
        TestGear.Waist.Age,
        TestGear.Waist.XP,
    )
    let feet = Item(
        TestGear.Feet.Id,
        TestGear.Feet.Class,
        TestGear.Feet.Slot,
        TestGear.Feet.Agility,
        TestGear.Feet.Attack,
        TestGear.Feet.Armour,
        TestGear.Feet.Wisdom,
        TestGear.Feet.Vitality,
        TestGear.Feet.Prefix,
        TestGear.Feet.Suffix,
        TestGear.Feet.Order,
        TestGear.Feet.Bonus,
        TestGear.Feet.Level,
        TestGear.Feet.Age,
        TestGear.Feet.XP,
    )
    let hands = Item(
        TestGear.Hands.Id,
        TestGear.Hands.Class,
        TestGear.Hands.Slot,
        TestGear.Hands.Agility,
        TestGear.Hands.Attack,
        TestGear.Hands.Armour,
        TestGear.Hands.Wisdom,
        TestGear.Hands.Vitality,
        TestGear.Hands.Prefix,
        TestGear.Hands.Suffix,
        TestGear.Hands.Order,
        TestGear.Hands.Bonus,
        TestGear.Hands.Level,
        TestGear.Hands.Age,
        TestGear.Hands.XP,
    )
    let neck = Item(
        TestGear.Neck.Id,
        TestGear.Neck.Class,
        TestGear.Neck.Slot,
        TestGear.Neck.Agility,
        TestGear.Neck.Attack,
        TestGear.Neck.Armour,
        TestGear.Neck.Wisdom,
        TestGear.Neck.Vitality,
        TestGear.Neck.Prefix,
        TestGear.Neck.Suffix,
        TestGear.Neck.Order,
        TestGear.Neck.Bonus,
        TestGear.Neck.Level,
        TestGear.Neck.Age,
        TestGear.Neck.XP,
    )
    let ring = Item(
        TestGear.Ring.Id,
        TestGear.Ring.Class,
        TestGear.Ring.Slot,
        TestGear.Ring.Agility,
        TestGear.Ring.Attack,
        TestGear.Ring.Armour,
        TestGear.Ring.Wisdom,
        TestGear.Ring.Vitality,
        TestGear.Ring.Prefix,
        TestGear.Ring.Suffix,
        TestGear.Ring.Order,
        TestGear.Ring.Bonus,
        TestGear.Ring.Level,
        TestGear.Ring.Age,
        TestGear.Ring.XP,
    )

    # Test state
    let adventurer_state = AdventurerState(
        TestAdventurer.Class,
        TestAdventurer.Age,
        TestAdventurer.Name,
        TestAdventurer.XP,
        TestAdventurer.Order,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
    )

    # Pack state
    let (packed_adventurer) = CalculateAdventurer._pack_adventurer(adventurer_state)

    # unpack state
    let (unpacked) = CalculateAdventurer._unpack_adventurer(packed_adventurer)

    let unpacked_class : AdventurerState = unpacked

    assert unpacked.Class = 0

    %{ print('Class: ', ids.unpacked.Class) %}
    %{ print('Age: ', ids.unpacked.Age) %}
    %{ print('Name: ', ids.unpacked.Name) %}
    %{ print('XP: ', ids.unpacked.XP) %}
    %{ print('Order: ', ids.unpacked.Order) %}

    %{ print('NeckId: ', ids.unpacked.NeckId) %}
    %{ print('WeaponId: ', ids.unpacked.WeaponId) %}
    %{ print('RingId: ', ids.unpacked.RingId) %}
    %{ print('ChestId: ', ids.unpacked.ChestId) %}
    %{ print('HeadId: ', ids.unpacked.HeadId) %}
    %{ print('WaistId: ', ids.unpacked.WaistId) %}
    %{ print('FeetId: ', ids.unpacked.FeetId) %}
    %{ print('HandsId: ', ids.unpacked.HandsId) %}

    return ()
end
