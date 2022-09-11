%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from starkware.cairo.common.pow import pow

from contracts.loot.constants.item import ItemIds, ItemSlot, ItemType, ItemMaterial, Material
from contracts.loot.constants.rankings import ItemRank
from contracts.loot.loot.stats.item import ItemStats
from contracts.loot.constants.physics import MaterialDensity
from contracts.loot.constants.adventurer import Adventurer, AdventurerState, PackedAdventurerState
from contracts.loot.adventurer.library import AdventurerLib

# @external
# func test_birth{syscall_ptr : felt*, range_check_ptr}():
#     alloc_locals

# let (adventurer : AdventurerState) = AdventurerLib.birth(1, 2, 3, 4, 5)

# let order = adventurer.Order

# %{ print('Realm Happiness:', ids.order) %}

# return ()
# end

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

@external
func test_pack{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let (adventurer_state : PackedAdventurerState) = AdventurerLib.pack(
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

    let (adventurer : AdventurerState) = AdventurerLib.unpack(adventurer_state)

    assert TestAdventurerState.Race = adventurer.Race  # 3
    assert TestAdventurerState.HomeRealm = adventurer.HomeRealm  # 13
    assert TestAdventurerState.Birthdate = adventurer.Birthdate
    assert TestAdventurerState.Name = adventurer.Name

    # evolving stats
    assert TestAdventurerState.Health = adventurer.Health  #

    assert TestAdventurerState.Level = adventurer.Level  #
    assert TestAdventurerState.Order = adventurer.Order  #

    # Physical
    assert TestAdventurerState.Strength = adventurer.Strength
    assert TestAdventurerState.Dexterity = adventurer.Dexterity
    assert TestAdventurerState.Vitality = adventurer.Vitality

    # Mental
    assert TestAdventurerState.Intelligence = adventurer.Intelligence
    assert TestAdventurerState.Wisdom = adventurer.Wisdom
    assert TestAdventurerState.Charisma = adventurer.Charisma

    # Meta Physical
    assert TestAdventurerState.Luck = adventurer.Luck

    assert TestAdventurerState.XP = adventurer.XP  #

    # store item NFT id when equiped
    # Packed Stats p2
    assert TestAdventurerState.NeckId = adventurer.NeckId
    assert TestAdventurerState.WeaponId = adventurer.WeaponId
    assert TestAdventurerState.RingId = adventurer.RingId
    assert TestAdventurerState.ChestId = adventurer.ChestId

    # Packed Stats p3
    assert TestAdventurerState.HeadId = adventurer.HeadId
    assert TestAdventurerState.WaistId = adventurer.WaistId
    assert TestAdventurerState.FeetId = adventurer.FeetId
    assert TestAdventurerState.HandsId = adventurer.HandsId

    return ()
end
