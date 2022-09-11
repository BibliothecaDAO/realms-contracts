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

from contracts.loot.loot.stats.item import ItemStats

from contracts.loot.constants.adventurer import Adventurer, AdventurerState, PackedAdventurerState
from contracts.settling_game.utils.general import unpack_data
from contracts.settling_game.utils.constants import SHIFT_41

namespace SHIFT_ADVENTURER:
    const _1 = 2 ** 0
    const _2 = 2 ** 4
    const _3 = 2 ** 14
    const _4 = 2 ** 18
    const _5 = 2 ** 38
end

namespace AdventurerLib:
    func birth{syscall_ptr : felt*, range_check_ptr}(
        race : felt, home_realm : felt, name : felt, birth_date : felt, order : felt
    ) -> (adventurer : AdventurerState):
        alloc_locals
        # set blank item

        let Race = race  # stored state
        let HomeRealm = home_realm  # stored state
        let Name = name  # stored state
        let Birthdate = birth_date  # stored state
        let Health = 100  # stored state
        let XP = 0  # stored state
        let Level = 0  # stored state
        let Order = order  # stored state

        # Physical
        let Strength = 0
        let Dexterity = 0
        let Vitality = 0

        # Mental
        let Intelligence = 0
        let Wisdom = 0
        let Charisma = 0

        let Luck = 0

        let NeckId = 0
        let WeaponId = 0
        let RingId = 0
        let ChestId = 0
        let HeadId = 0
        let WaistId = 0
        let FeetId = 0
        let HandsId = 0

        return (
            AdventurerState(
            Race=Race,
            HomeRealm=HomeRealm,
            Name=Name,
            Birthdate=Birthdate,
            Health=Health,
            Level=Level,
            Order=Order,
            Strength=Strength,
            Dexterity=Dexterity,
            Vitality=Vitality,
            Intelligence=Intelligence,
            Wisdom=Wisdom,
            Charisma=Charisma,
            Luck=Luck,
            XP=XP,
            NeckId=NeckId,
            WeaponId=WeaponId,
            RingId=RingId,
            ChestId=ChestId,
            HeadId=HeadId,
            WaistId=WaistId,
            FeetId=FeetId,
            HandsId=HandsId
            ),
        )
    end

    namespace SHIFT_P_1:
        const _1 = 2 ** 0
        const _2 = 2 ** 3
        const _3 = 2 ** 16
        const _4 = 2 ** 49
    end

    namespace SHIFT_P_2:
        const _1 = 2 ** 0
        const _2 = 2 ** 13
        const _3 = 2 ** 22
        const _4 = 2 ** 27
        const _5 = 2 ** 37
        const _6 = 2 ** 47
        const _7 = 2 ** 57
        const _8 = 2 ** 67
        const _9 = 2 ** 77
        const _10 = 2 ** 87
        const _11 = 2 ** 97
        const _12 = 2 ** 107
        const _13 = 2 ** 117
    end

    func pack{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(unpacked_adventurer_state : AdventurerState) -> (packed_adventurer : PackedAdventurerState):
        alloc_locals

        let Race = unpacked_adventurer_state.Race * SHIFT_P_1._1
        let HomeRealm = unpacked_adventurer_state.HomeRealm * SHIFT_P_1._2
        let Birthdate = unpacked_adventurer_state.Birthdate * SHIFT_P_1._3
        let Name = unpacked_adventurer_state.Name * SHIFT_P_1._4

        let Health = unpacked_adventurer_state.Health * SHIFT_P_2._1
        let Level = unpacked_adventurer_state.Level * SHIFT_P_2._2
        let Order = unpacked_adventurer_state.Order * SHIFT_P_2._3

        # Physical
        let Strength = unpacked_adventurer_state.Strength * SHIFT_P_2._4
        let Dexterity = unpacked_adventurer_state.Dexterity * SHIFT_P_2._5
        let Vitality = unpacked_adventurer_state.Vitality * SHIFT_P_2._6

        # Mental
        let Intelligence = unpacked_adventurer_state.Intelligence * SHIFT_P_2._7
        let Wisdom = unpacked_adventurer_state.Wisdom * SHIFT_P_2._8
        let Charisma = unpacked_adventurer_state.Charisma * SHIFT_P_2._9

        let Luck = unpacked_adventurer_state.Luck * SHIFT_P_2._10

        let XP = unpacked_adventurer_state.XP * SHIFT_P_2._11

        # Items
        let Neck = unpacked_adventurer_state.NeckId * SHIFT_41._1  # 30
        let Weapon = unpacked_adventurer_state.WeaponId * SHIFT_41._2  # 30
        let Ring = unpacked_adventurer_state.RingId * SHIFT_41._3  # 30
        let Chest = unpacked_adventurer_state.ChestId * SHIFT_41._4  # 30

        let Head = unpacked_adventurer_state.HeadId * SHIFT_41._1  # 30
        let Waist = unpacked_adventurer_state.WaistId * SHIFT_41._2  # 30
        let Feet = unpacked_adventurer_state.FeetId * SHIFT_41._3  # 30
        let Hands = unpacked_adventurer_state.HandsId * SHIFT_41._4  # 30

        # packing
        let p1 = Name + Birthdate + HomeRealm + Race
        let p2 = XP + Luck + Charisma + Wisdom + Intelligence + Vitality + Dexterity + Strength + Order + Level + Health
        let p3 = Chest + Ring + Weapon + Neck
        let p4 = Hands + Feet + Waist + Head

        let packedAdventurer = PackedAdventurerState(p1, p2, p3, p4)

        return (packedAdventurer)
    end

    func unpack{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*,
    }(packed_adventurer : PackedAdventurerState) -> (adventurer : AdventurerState):
        alloc_locals

        let (Race) = unpack_data(packed_adventurer.p1, 0, 15)  # 4
        let (HomeRealm) = unpack_data(packed_adventurer.p1, 4, 1023)  # 10
        let (Name) = unpack_data(packed_adventurer.p1, 14, 15)  # 4
        let (Birthdate) = unpack_data(packed_adventurer.p1, 18, 15)  # 4

        let (Health) = unpack_data(packed_adventurer.p2, 0, 8191)
        let (Level) = unpack_data(packed_adventurer.p2, 13, 511)
        let (Order) = unpack_data(packed_adventurer.p2, 22, 31)

        # Physical
        let (Strength) = unpack_data(packed_adventurer.p2, 27, 1023)
        let (Dexterity) = unpack_data(packed_adventurer.p2, 37, 1023)
        let (Vitality) = unpack_data(packed_adventurer.p2, 47, 1023)

        # Mental
        let (Intelligence) = unpack_data(packed_adventurer.p2, 57, 1023)
        let (Wisdom) = unpack_data(packed_adventurer.p2, 67, 1023)
        let (Charisma) = unpack_data(packed_adventurer.p2, 77, 1023)

        let (Luck) = unpack_data(packed_adventurer.p2, 87, 1023)

        let (XP) = unpack_data(packed_adventurer.p2, 97, 1023)

        # p3
        let (NeckId) = unpack_data(packed_adventurer.p3, 0, 2199023255551)  # 41
        let (WeaponId) = unpack_data(packed_adventurer.p3, 41, 2199023255551)  # 41
        let (RingId) = unpack_data(packed_adventurer.p3, 82, 2199023255551)  # 41
        let (ChestId) = unpack_data(packed_adventurer.p3, 123, 2199023255551)  # 41

        # p4
        let (HeadId) = unpack_data(packed_adventurer.p3, 0, 2199023255551)  # 41
        let (WaistId) = unpack_data(packed_adventurer.p3, 41, 2199023255551)  # 41
        let (FeetId) = unpack_data(packed_adventurer.p3, 82, 2199023255551)  # 41
        let (HandsId) = unpack_data(packed_adventurer.p3, 123, 2199023255551)  # 41

        return (
            AdventurerState(
            Race=Race,
            HomeRealm=HomeRealm,
            Name=Name,
            Birthdate=Birthdate,
            Health=Health,
            Level=Level,
            Order=Order,
            Strength=Strength,
            Dexterity=Dexterity,
            Vitality=Vitality,
            Intelligence=Intelligence,
            Wisdom=Wisdom,
            Charisma=Charisma,
            Luck=Luck,
            XP=XP,
            NeckId=NeckId,
            WeaponId=WeaponId,
            RingId=RingId,
            ChestId=ChestId,
            HeadId=HeadId,
            WaistId=WaistId,
            FeetId=FeetId,
            HandsId=HandsId
            ),
        )
    end
    # func _stats{syscall_ptr : felt*, range_check_ptr}(adventurer : Adventurer) -> (
    #     agility, attack, armour, wisdom, vitality
    # ):
    #     alloc_locals

    # let (agility, attack, armour, wisdom, vitality) = _items(
    #         adventurer.Weapon,
    #         adventurer.Chest,
    #         adventurer.Head,
    #         adventurer.Waist,
    #         adventurer.Feet,
    #         adventurer.Hands,
    #         adventurer.Neck,
    #         adventurer.Ring,
    #     )

    # let adventurer = Adventurer(
    #         adventurer.Class,
    #         agility,
    #         attack,
    #         armour,
    #         wisdom,
    #         vitality,
    #         adventurer.Neck,
    #         adventurer.Weapon,
    #         adventurer.Ring,
    #         adventurer.Chest,
    #         adventurer.Head,
    #         adventurer.Waist,
    #         adventurer.Feet,
    #         adventurer.Hands,
    #         adventurer.Age,
    #         adventurer.Name,
    #         adventurer.XP,
    #         adventurer.Order,
    #     )

    # return (adventurer)
    # end

    # func _equip_item{syscall_ptr : felt*, range_check_ptr}(
    #     item_token_id : felt, item : Item, unpacked_adventurer : AdventurerState
    # ) -> (success : felt):
    #     alloc_locals

    # if item.Slot == Slot.Neck:
    #         let Neck = item_token_id * SHIFT_41._1
    #     end

    # return (0)
    # end
end
