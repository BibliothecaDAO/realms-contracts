# Item Structs
#   A struct that holds the Realm statistics.
#   Each module will need to add a struct with their metadata.
#
# MIT License

%lang starknet

struct Adventurer:
    member Class : felt
    member Agility : felt
    member Attack : felt
    member Armour : felt
    member Wisdom : felt
    member Vitality : felt
    member Neck : felt
    member Weapon : felt
    member Ring : felt
    member Chest : felt
    member Head : felt
    member Waist : felt
    member Feet : felt
    member Hands : felt
    member Age : felt
    member Name : felt
    member XP : felt
end

struct Item:
    member ItemId : felt
    member Class : felt  # location for now
    member Slot : felt
    member Agility : felt
    member Attack : felt
    member Armour : felt
    member Wisdom : felt
    member Vitality : felt
    member Prefix : felt
    member Suffix : felt
    member Order : felt
    member Bonus : felt
    member Level : felt
    member Age : felt
    member XP : felt
end

namespace Class:
    const All = 1
    const Mage = 2
    const Ranger = 3
    const Warrior = 4
end

namespace ItemClass:
    const Pendant = Class.All
    const Necklace = Class.All
    const Amulet = Class.All
    const SilverRing = Class.All
    const BronzeRing = Class.All
    const PlatinumRing = Class.All
    const TitaniumRing = Class.All
    const GoldRing = Class.All
    # TODO: add
end

namespace Slot:
    const Weapon = 1
    const Chest = 2
    const Head = 3
    const Waist = 4
    const Feet = 5
    const Hands = 6
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
    # TODO: add
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

namespace ItemAgility:
    const Pendant = 10
    const Necklace = 10
    const Amulet = 10
    const SilverRing = 10
    const BronzeRing = 10
    const PlatinumRing = 10
    const TitaniumRing = 10
    const GoldRing = 10
    const GhostWand = 10
    const GraveWand = 10
    const BoneWand = 10
    const Wand = 10
    const Grimoire = 10
    const Chronicle = 10
    const Tome = 10
    const Book = 10
    const DivineRobe = 10
    const SilkRobe = 10
    const LinenRobe = 10
    const Robe = 10
    const Shirt = 10
    const Crown = 10
    const DivineHood = 10
    const SilkHood = 10
    const LinenHood = 10
    const Hood = 10
    const BrightsilkSash = 50
    const SilkSash = 49
    const WoolSash = 48
    const LinenSash = 46
    const Sash = 45
    const DivineSlippers = 100
    const SilkSlippers = 98
    const WoolShoes = 96
    const LinenShoes = 93
    const Shoes = 90
    const DivineGloves = 10
    const SilkGloves = 10
    const WoolGloves = 10
    const LinenGloves = 10
    const Gloves = 10
    const Katana = 100
    const Falchion = 98
    const Scimitar = 96
    const LongSword = 93
    const ShortSword = 90
    const DemonHusk = 100
    const DragonskinArmor = 98
    const StuddedLeatherArmor = 96
    const HardLeatherArmor = 93
    const LeatherArmor = 90
    const DemonCrown = 50
    const DragonsCrown = 49
    const WarCap = 48
    const LeatherCap = 47
    const Cap = 45
    const DemonhideBelt = 50
    const DragonskinBelt = 49
    const StuddedLeatherBelt = 48
    const HardLeatherBelt = 47
    const LeatherBelt = 45
    const DemonhideBoots = 50
    const DragonskinBoots = 49
    const StuddedLeatherBoots = 48
    const HardLeatherBoots = 47
    const LeatherBoots = 45
    const DemonsHands = 10
    const DragonskinGloves = 10
    const StuddedLeatherGloves = 10
    const HardLeatherGloves = 10
    const LeatherGloves = 10
    const Warhammer = 10
    const Quarterstaff = 10
    const Maul = 10
    const Mace = 10
    const Club = 10
    const HolyChestplate = 10
    const OrnateChestplate = 10
    const PlateMail = 10
    const ChainMail = 10
    const RingMail = 10
    const AncientHelm = 10
    const OrnateHelm = 10
    const GreatHelm = 10
    const FullHelm = 10
    const Helm = 10
    const OrnateBelt = 10
    const WarBelt = 10
    const PlatedBelt = 10
    const MeshBelt = 10
    const HeavyBelt = 10
    const HolyGreaves = 10
    const OrnateGreaves = 10
    const Greaves = 10
    const ChainBoots = 10
    const HeavyBoots = 10
    const HolyGauntlets = 10
    const OrnateGauntlets = 10
    const Gauntlets = 10
    const ChainGloves = 10
    const HeavyGloves = 10
end
