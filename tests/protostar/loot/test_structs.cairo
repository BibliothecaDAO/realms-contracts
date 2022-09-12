%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from contracts.loot.constants.adventurer import Adventurer, AdventurerState, PackedAdventurerState

namespace TestAdventurerState:
    # immutable stats
    const Race = 1  # 3
    const HomeRealm = 2  # 13
    const Birthdate = 1662888731
    const Name = 'loaf'

    # evolving stats
    const Health = 5000  #

    const Level = 500  #
    const Order = 12  #

    # Physical
    const Strength = 1000
    const Dexterity = 1000
    const Vitality = 1000

    # Mental
    const Intelligence = 1000
    const Wisdom = 1000
    const Charisma = 1000

    # Meta Physical
    const Luck = 1000

    const XP = 1000000  #

    # store item NFT id when equiped
    # Packed Stats p2
    const NeckId = 1000
    const WeaponId = 1000
    const RingId = 1000
    const ChestId = 1000

    # Packed Stats p3
    const HeadId = 1000
    const WaistId = 1000
    const FeetId = 1000
    const HandsId = 1000
end

func get_adventurer_state{syscall_ptr : felt*, range_check_ptr}() -> (
    adventurer_state : AdventurerState
):
    alloc_locals

    return (
        AdventurerState(
        TestAdventurerState.Race,
        TestAdventurerState.HomeRealm,
        TestAdventurerState.Birthdate,
        TestAdventurerState.Name,
        TestAdventurerState.Health,
        TestAdventurerState.Level,
        TestAdventurerState.Order,
        TestAdventurerState.Strength,
        TestAdventurerState.Dexterity,
        TestAdventurerState.Vitality,
        TestAdventurerState.Intelligence,
        TestAdventurerState.Wisdom,
        TestAdventurerState.Charisma,
        TestAdventurerState.Luck,
        TestAdventurerState.XP,
        TestAdventurerState.NeckId,
        TestAdventurerState.WeaponId,
        TestAdventurerState.RingId,
        TestAdventurerState.ChestId,
        TestAdventurerState.HeadId,
        TestAdventurerState.WaistId,
        TestAdventurerState.FeetId,
        TestAdventurerState.HandsId,
        ),
    )
end
