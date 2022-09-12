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

from tests.protostar.loot.test_structs import TestAdventurerState, get_adventurer_state

@external
func test_birth{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (adventurer : AdventurerState) = AdventurerLib.birth(
        TestAdventurerState.Race,
        TestAdventurerState.HomeRealm,
        TestAdventurerState.Name,
        TestAdventurerState.Birthdate,
        TestAdventurerState.Order,
    )
    assert TestAdventurerState.Race = adventurer.Race
    assert TestAdventurerState.HomeRealm = adventurer.HomeRealm
    assert TestAdventurerState.Name = adventurer.Name
    assert TestAdventurerState.Birthdate = adventurer.Birthdate
    assert TestAdventurerState.Order = adventurer.Order

    return ()
end

@external
func test_pack{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals

    let (state) = get_adventurer_state()

    let (adventurer_state : PackedAdventurerState) = AdventurerLib.pack(state)

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

# @external
# func test_cast{
#     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
# }():
#     alloc_locals

# let (adventurer_state : PackedAdventurerState) = AdventurerLib.pack(state)

# let (adventurer : AdventurerState) = AdventurerLib.unpack(adventurer_state)

# let (c) = AdventurerLib.cast_state(0, 2, adventurer)

# %{ print('Race', ids.c.Race) %}

# return ()
# end
