# Item Structs
#   A struct that holds the Loot item statistics
#
#
# MIT License

%lang starknet

struct State:
    member Bagged : felt # protected in a loot bag
    member Equipped : felt # equipped on an adventurer
    member Loose : felt # not in loot bag or equipped (i.e on a table at a market)
end

# Loot item shape. This is the on-chain metadata of each item.
struct Item:
    member Id : felt  # item id 1 - 100
    member Type : felt # weapon.blade, armor.foot, jewlery.ring
    member Material : felt # the material of the item
    member Rank : felt # 1 is best (Divine Robe = 1, Silk Robe = 2, Linen Robe = 3, Robe = 4, Shirt = 5)
    member Prefix_1 : felt  # First part of the name prefix (i.e Demon)
    member Prefix_2 : felt  # Second part of the name prefix (i.e Grasp)
    member Suffix : felt  # Stored value if item has a Suffix (i.e of Power)
    member Greatness : felt  # Stored value if item has a Greatness
    member Age : felt  # Timestamp of when item was created
    member XP : felt  # accured XP
    member State : State # the state of the item: {bagged, equipped, cooldown, etc}
end

#TODO: Need to renumber these to be all unique
namespace Material:
    const generic = 0

    namespace Metal:
        const generic = 0
        const ancient = 1
        const holy = 2
        const ornate = 3
        const gold = 4
        const silver = 5
        const bronze = 6
        const platinum = 7
        const titanium = 8
        const steel = 9
    end
    namespace Cloth:
        const generic = 0
        const royal = 1
        const divine = 2
        const brightsilk = 3 
        const silk = 4
        const wool = 5
        const linen = 6
    end
    namespace Biotic:
        namespace Demon:
            const generic = 0
            const blood = 1
            const bones = 2
            const brain = 3
            const eyes = 4
            const hide = 5
            const flesh = 6
            const hair = 7
            const heart = 8
            const entrails = 9
            const hands = 10
            const feet = 11
        end
        namespace Dragon:
            const generic = 0
            const blood = 1
            const bones = 2
            const brain = 3
            const eyes = 4
            const skin = 5
            const flesh = 6
            const hair = 7
            const heart = 8
            const entrails = 9
            const hands = 10
            const feet = 11
        end
        namespace Animal:
            const generic = 0
            const blood = 1
            const bones = 2
            const brain = 3
            const eyes = 4
            const hide = 5
            const flesh = 6
            const hair = 7
            const heart = 8
            const entrails = 9
            const hands = 10
            const feet = 11
        end
        namespace Human:
            const generic = 0
            const blood = 1
            const bones = 2
            const brain = 3
            const eyes = 4
            const hide = 5
            const flesh = 6
            const hair = 7
            const heart = 8
            const entrails = 9
            const hands = 10
            const feet = 11
        end
    end
    namespace Paper:
        const generic = 0
        const magical = 1
    end
    namespace Wood:
        const generic = 0
        namespace Hard:
            const generic = 0
            const walnut = 1
            const mahogany = 2
            const maple = 3
            const oak = 4
            const rosewood = 5
            const cherry = 6
            const balsa = 7
            const birch = 8
            const holly = 9
        end
        namespace Soft:
            const generic = 0
            const cedar = 1
            const pine = 2
            const fir = 3
            const hemlock = 4
            const spruce = 5
            const elder = 6
            const yew = 7
        end
    end
end

namespace Slot:
    const Weapon = 1
    const Chest = 2
    const Head = 3
    const Waist = 4
    const Foot = 5
    const Hand = 6
    const Neck = 7
    const Ring = 8
end

namespace ItemSlot:
    const Pendant = Slot.Neck
    const Necklace = Slot.Neck
    const Amulet = Slot.Neck
    const SilverRing = Slot.Ring
    const BronzeRing = Slot.Ring
    const PlatinumRing = Slot.Ring
    const TitaniumRing = Slot.Ring
    const GoldRing = Slot.Ring
    const GhostWand = Slot.Weapon
    const GraveWand = Slot.Weapon
    const BoneWand = Slot.Weapon
    const Wand = Slot.Weapon
    const Grimoire = Slot.Weapon
    const Chronicle = Slot.Weapon
    const Tome = Slot.Weapon
    const Book = Slot.Weapon
    const DivineRobe = Slot.Chest
    const SilkRobe = Slot.Chest
    const LinenRobe = Slot.Chest
    const Robe = Slot.Chest
    const Shirt = Slot.Chest
    const Crown = Slot.Head
    const DivineHood = Slot.Head
    const SilkHood = Slot.Head
    const LinenHood = Slot.Head
    const Hood = Slot.Head
    const BrightsilkSash = Slot.Waist
    const SilkSash = Slot.Waist
    const WoolSash = Slot.Waist
    const LinenSash = Slot.Waist
    const Sash = Slot.Waist
    const DivineSlippers = Slot.Foot
    const SilkSlippers = Slot.Foot
    const WoolShoes = Slot.Foot
    const LinenShoes = Slot.Foot
    const Shoes = Slot.Foot
    const DivineGloves = Slot.Hand
    const SilkGloves = Slot.Hand
    const WoolGloves = Slot.Hand
    const LinenGloves = Slot.Hand
    const Gloves = Slot.Hand
    const Katana = Slot.Weapon
    const Falchion = Slot.Weapon
    const Scimitar = Slot.Weapon
    const LongSword = Slot.Weapon
    const ShortSword = Slot.Weapon
    const DemonHusk = Slot.Chest
    const DragonskinArmor = Slot.Chest
    const StuddedLeatherArmor = Slot.Chest
    const HardLeatherArmor = Slot.Chest
    const LeatherArmor = Slot.Chest
    const DemonCrown = Slot.Head
    const DragonsCrown = Slot.Head
    const WarCap = Slot.Head
    const LeatherCap = Slot.Head
    const Cap = Slot.Head
    const DemonhideBelt = Slot.Waist
    const DragonskinBelt = Slot.Waist
    const StuddedLeatherBelt = Slot.Waist
    const HardLeatherBelt = Slot.Waist
    const LeatherBelt = Slot.Waist
    const DemonhideBoots = Slot.Foot
    const DragonskinBoots = Slot.Foot
    const StuddedLeatherBoots = Slot.Foot
    const HardLeatherBoots = Slot.Foot
    const LeatherBoots = Slot.Foot
    const DemonsHands = Slot.Hand
    const DragonskinGloves = Slot.Hand
    const StuddedLeatherGloves = Slot.Hand
    const HardLeatherGloves = Slot.Hand
    const LeatherGloves = Slot.Hand
    const Warhammer = Slot.Weapon
    const Quarterstaff = Slot.Weapon
    const Maul = Slot.Weapon
    const Mace = Slot.Weapon
    const Club = Slot.Weapon
    const HolyChestplate = Slot.Chest
    const OrnateChestplate = Slot.Chest
    const PlateMail = Slot.Chest
    const ChainMail = Slot.Chest
    const RingMail = Slot.Chest
    const AncientHelm = Slot.Head
    const OrnateHelm = Slot.Head
    const GreatHelm = Slot.Head
    const FullHelm = Slot.Head
    const Helm = Slot.Head
    const OrnateBelt = Slot.Waist
    const WarBelt = Slot.Waist
    const PlatedBelt = Slot.Waist
    const MeshBelt = Slot.Waist
    const HeavyBelt = Slot.Waist
    const HolyGreaves = Slot.Hand
    const OrnateGreaves = Slot.Hand
    const Greaves = Slot.Hand
    const ChainBoots = Slot.Foot
    const HeavyBoots = Slot.Foot
    const HolyGauntlets = Slot.Foot
    const OrnateGauntlets = Slot.Foot
    const Gauntlets = Slot.Foot
    const ChainGloves = Slot.Hand
    const HeavyGloves = Slot.Hand
end

namespace ItemIds:
    const Pendant = 1
    const Necklace = 2
    const Amulet = 3
    const SilverRing = 4
    const BronzeRing = 5
    const PlatinumRing = 6
    const TitaniumRing = 7
    const GoldRing = 8
    const GhostWand = 9
    const GraveWand = 10
    const BoneWand = 11
    const Wand = 12
    const Grimoire = 13
    const Chronicle = 14
    const Tome = 15
    const Book = 16
    const DivineRobe = 17
    const SilkRobe = 18
    const LinenRobe = 19
    const Robe = 20
    const Shirt = 21
    const Crown = 22
    const DivineHood = 23
    const SilkHood = 24
    const LinenHood = 25
    const Hood = 26
    const BrightsilkSash = 27
    const SilkSash = 28
    const WoolSash = 29
    const LinenSash = 30
    const Sash = 31
    const DivineSlippers = 32
    const SilkSlippers = 33
    const WoolShoes = 34
    const LinenShoes = 35
    const Shoes = 36
    const DivineGloves = 37
    const SilkGloves = 38
    const WoolGloves = 39
    const LinenGloves = 40
    const Gloves = 41
    const Katana = 42
    const Falchion = 43
    const Scimitar = 44
    const LongSword = 45
    const ShortSword = 46
    const DemonHusk = 47
    const DragonskinArmor = 48
    const StuddedLeatherArmor = 49
    const HardLeatherArmor = 50
    const LeatherArmor = 51
    const DemonCrown = 52
    const DragonsCrown = 53
    const WarCap = 54
    const LeatherCap = 55
    const Cap = 56
    const DemonhideBelt = 57
    const DragonskinBelt = 58
    const StuddedLeatherBelt = 59
    const HardLeatherBelt = 60
    const LeatherBelt = 61
    const DemonhideBoots = 62
    const DragonskinBoots = 63
    const StuddedLeatherBoots = 64
    const HardLeatherBoots = 65
    const LeatherBoots = 66
    const DemonsHands = 67
    const DragonskinGloves = 68
    const StuddedLeatherGloves = 69
    const HardLeatherGloves = 70
    const LeatherGloves = 71
    const Warhammer = 72
    const Quarterstaff = 73
    const Maul = 74
    const Mace = 75
    const Club = 76
    const HolyChestplate = 77
    const OrnateChestplate = 78
    const PlateMail = 79
    const ChainMail = 80
    const RingMail = 81
    const AncientHelm = 82
    const OrnateHelm = 83
    const GreatHelm = 84
    const FullHelm = 85
    const Helm = 86
    const OrnateBelt = 87
    const WarBelt = 88
    const PlatedBelt = 89
    const MeshBelt = 90
    const HeavyBelt = 91
    const HolyGreaves = 92
    const OrnateGreaves = 93
    const Greaves = 94
    const ChainBoots = 95
    const HeavyBoots = 96
    const HolyGauntlets = 97
    const OrnateGauntlets = 98
    const Gauntlets = 99
    const ChainGloves = 100
    const HeavyGloves = 101
end

namespace ItemMaterial:
    const Pendant = Material.generic
    const Necklace = Material.generic
    const Amulet = Material.generic
    const SilverRing = Material.Metal.silver
    const BronzeRing = Material.Metal.bronze
    const PlatinumRing = Material.Metal.platinum
    const TitaniumRing = Material.Metal.titanium
    const GoldRing = Material.Metal.gold
    const GhostWand = Material.Wood.Soft.elder # dumbledoor's wand was made of elder
    const GraveWand = Material.Wood.Soft.yew # voldemort's wand was made of yew
    const BoneWand = Material.Wood.Hard.holly # HP's wand was made of holly
    const Wand = Material.Wood.Hard.oak
    const Grimoire = Material.Paper.magical
    const Chronicle = Material.Paper.generic
    const Tome = Material.Paper.generic
    const Book = Material.Paper.generic
    const DivineRobe = Material.Cloth.divine
    const SilkRobe = Material.Cloth.silk
    const LinenRobe = Material.Cloth.linen
    const Robe = Material.Cloth.generic
    const Shirt = Material.Cloth.generic
    const Crown = Material.Cloth.royal
    const DivineHood = Material.Cloth.divine
    const SilkHood = Material.Cloth.silk
    const LinenHood = Material.Cloth.linen
    const Hood = Material.Cloth.generic
    const BrightsilkSash = Material.Cloth.brightsilk
    const SilkSash = Material.Cloth.silk
    const WoolSash = Material.Cloth.wool
    const LinenSash = Material.Cloth.linen
    const Sash = Material.Cloth.generic
    const DivineSlippers = Material.Cloth.divine
    const SilkSlippers = Material.Cloth.silk
    const WoolShoes = Material.Cloth.wool
    const LinenShoes = Material.Cloth.linen
    const Shoes = Material.Cloth.generic
    const DivineGloves = Material.Cloth.divine
    const SilkGloves = Material.Cloth.silk
    const WoolGloves = Material.Cloth.wool
    const LinenGloves = Material.Cloth.linen
    const Gloves = Material.Cloth.generic
    const Katana = Material.Metal.steel
    const Falchion = Material.Metal.steel
    const Scimitar = Material.Metal.steel
    const LongSword = Material.Metal.steel
    const ShortSword = Material.Metal.steel
    const DemonHusk = Material.Biotic.Demon.hide
    const DragonskinArmor = Material.Biotic.Dragon.skin
    const StuddedLeatherArmor =  Material.Biotic.Animal.hide
    const HardLeatherArmor = Material.Biotic.Animal.hide
    const LeatherArmor = Material.Biotic.Animal.hide
    const DemonCrown = Material.Biotic.Demon.bones
    const DragonsCrown = Material.Biotic.Dragon.bones
    const WarCap = Material.Biotic.Animal.hide
    const LeatherCap = Material.Biotic.Animal.hide
    const Cap = Material.Biotic.Animal.hide
    const DemonhideBelt = Material.Biotic.Demon.hide
    const DragonskinBelt = Material.Biotic.Dragon.skin
    const StuddedLeatherBelt = Material.Biotic.Animal.hide
    const HardLeatherBelt = Material.Biotic.Animal.hide
    const LeatherBelt = Material.Biotic.Animal.hide
    const DemonhideBoots = Material.Biotic.Demon.hide
    const DragonskinBoots = Material.Biotic.Dragon.skin
    const StuddedLeatherBoots = Material.Biotic.Animal.hide
    const HardLeatherBoots = Material.Biotic.Animal.hide
    const LeatherBoots = Material.Biotic.Animal.hide
    const DemonsHands =Material.Biotic.Demon.hands
    const DragonskinGloves = Material.Biotic.Dragon.skin
    const StuddedLeatherGloves = Material.Biotic.Animal.hide
    const HardLeatherGloves = Material.Biotic.Animal.hide
    const LeatherGloves = Material.Biotic.Animal.hide
    const Warhammer = Material.Metal.steel
    const Quarterstaff = Material.Wood.generic
    const Maul = Material.Metal.steel
    const Mace = Material.Metal.steel
    const Club = Material.Wood.Hard.oak
    const HolyChestplate = Material.Metal.holy
    const OrnateChestplate = Material.Metal.ornate
    const PlateMail = Material.Metal.steel
    const ChainMail = Material.Metal.steel
    const RingMail = Material.Metal.steel
    const AncientHelm = Material.Metal.ancient
    const OrnateHelm = Material.Metal.ornate
    const GreatHelm = Material.Metal.steel
    const FullHelm = Material.Metal.steel
    const Helm = Material.Metal.generic
    const OrnateBelt = Material.Metal.ornate
    const WarBelt = Material.Metal.generic
    const PlatedBelt = Material.Metal.steel
    const MeshBelt = Material.Metal.generic
    const HeavyBelt = Material.Metal.generic
    const HolyGreaves = Material.Metal.holy
    const OrnateGreaves = Material.Metal.ornate
    const Greaves = Material.Metal.steel
    const ChainBoots = Material.Metal.steel
    const HeavyBoots = Material.Metal.generic
    const HolyGauntlets = Material.Metal.holy
    const OrnateGauntlets = Material.Metal.ornate
    const Gauntlets = Material.Metal.steel
    const ChainGloves = Material.Metal.steel
    const HeavyGloves = Material.Metal.generic
end