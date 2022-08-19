%lang starknet

from contracts.settling_game.utils.constants import MAX_GOBLIN_TOWN_STRENGTH
from contracts.settling_game.utils.game_structs import RealmData, ResourceIds
from contracts.settling_game.modules.goblintown.library import GoblinTown

@external
func test_pack_unpack{range_check_ptr}():
    alloc_locals

    let strength = 15
    let spawn_ts = 1700000000
    let (packed) = GoblinTown.pack(strength, spawn_ts)
    assert packed = 31359464925306237747200000015

    let (unpacked_strength, unpacked_spawn_ts) = GoblinTown.unpack(packed)
    assert unpacked_strength = strength
    assert unpacked_spawn_ts = spawn_ts

    return ()
end

@external
func test_calculate_strength{range_check_ptr}():
    alloc_locals

    let realm_data = RealmData(
        regions=4,
        cities=12,
        harbours=2,
        rivers=7,
        resource_number=3,
        resource_1=ResourceIds.Stone,
        resource_2=ResourceIds.Ironwood,
        resource_3=ResourceIds.Ruby,
        resource_4=0,
        resource_5=0,
        resource_6=0,
        resource_7=0,
        wonder=0,
        order=1,
    )

    let (strength) = GoblinTown.calculate_strength(realm_data, 0)
    assert strength = 5

    let (strength) = GoblinTown.calculate_strength(realm_data, 3)
    assert strength = 8

    let (strength) = GoblinTown.calculate_strength(realm_data, 20)
    assert strength = MAX_GOBLIN_TOWN_STRENGTH

    return ()
end

@external
func test_get_squad_strength_of_resource{range_check_ptr}():
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Wood)
    assert e = 1
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Stone)
    assert e = 1
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Coal)
    assert e = 1

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Copper)
    assert e = 2
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Obsidian)
    assert e = 2
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Silver)
    assert e = 2

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Ironwood)
    assert e = 3
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.ColdIron)
    assert e = 3
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Gold)
    assert e = 3

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Hartwood)
    assert e = 4
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Diamonds)
    assert e = 4
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Sapphire)
    assert e = 4

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Ruby)
    assert e = 5
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.DeepCrystal)
    assert e = 5
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Ignium)
    assert e = 5

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.EtherealSilica)
    assert e = 6
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.TrueIce)
    assert e = 6

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.TwilightQuartz)
    assert e = 7
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.AlchemicalSilver)
    assert e = 7

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Adamantine)
    assert e = 8
    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Mithral)
    assert e = 8

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.Dragonhide)
    assert e = 9

    let (e) = GoblinTown.get_squad_strength_of_resource(ResourceIds.fish)
    assert e = 1

    return ()
end
