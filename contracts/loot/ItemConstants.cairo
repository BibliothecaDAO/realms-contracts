# Item Structs
#   A struct that holds the Realm statistics.
#   Each module will need to add a struct with their metadata.
#
# MIT License

%lang starknet

struct Item:
    member Id : felt  # item id 1 - 100
    member Class : felt  # loot item class
    member Slot : felt  # head, chest, waist, feet, hands, neck, ring, weapon
    member Agility : felt  # Computed Agility of the item
    member Attack : felt  # Computed Attack of the item
    member Armour : felt  # Computed Armour of the item
    member Wisdom : felt  # Computed Wisdom of the item
    member Vitality : felt  # Computed Vitality of the item
    member Prefix : felt  # Stored value if item has a Prefix
    member Suffix : felt  # Stored value if item has a Suffix
    member Order : felt  # Stored value if item has a Order
    member Bonus : felt  # Stored value if item has a Bonus
    member Level : felt  # Stored value if item has a Level
    member Age : felt  # Timestamp of when item was created
    member XP : felt  # accured XP
end

struct Adventurer:
    member Class : felt

    # computed of all items stats
    member Agility : felt
    member Attack : felt
    member Armour : felt
    member Wisdom : felt
    member Vitality : felt

    # store item NFT id when equiped
    member Neck : Item
    member Weapon : Item
    member Ring : Item
    member Chest : Item
    member Head : Item
    member Waist : Item
    member Feet : Item
    member Hands : Item

    # other unique state
    member Age : felt
    member Name : felt  # mint time
    member XP : felt
    member Order : felt
end

struct AdventurerState:
    # other unique state p1
    member Class : felt
    member Age : felt
    member Name : felt  # mint time
    member XP : felt
    member Order : felt

    # store item NFT id when equiped
    # Packed Stats p2
    member NeckId : felt
    member WeaponId : felt
    member RingId : felt
    member ChestId : felt

    # Packed Stats p3
    member HeadId : felt
    member WaistId : felt
    member FeetId : felt
    member HandsId : felt
end

struct PackedAdventurerStats:
    member p1 : felt
    member p2 : felt
    member p3 : felt
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

namespace ItemArmour:
    const Pendant = 0
    const Necklace = 0
    const Amulet = 0
    const SilverRing = 0
    const BronzeRing = 0
    const PlatinumRing = 0
    const TitaniumRing = 0
    const GoldRing = 0
    const GhostWand = 0
    const GraveWand = 0
    const BoneWand = 0
    const Wand = 0
    const Grimoire = 0
    const Chronicle = 0
    const Tome = 0
    const Book = 0
    const DivineRobe = 50
    const SilkRobe = 49
    const LinenRobe = 48
    const Robe = 46
    const Shirt = 45
    const Crown = 50
    const DivineHood = 49
    const SilkHood = 48
    const LinenHood = 46
    const Hood = 45
    const BrightsilkSash = 0
    const SilkSash = 0
    const WoolSash = 0
    const LinenSash = 0
    const Sash = 0
    const DivineSlippers = 0
    const SilkSlippers = 0
    const WoolShoes = 0
    const LinenShoes = 0
    const Shoes = 0
    const DivineGloves = 50
    const SilkGloves = 49
    const WoolGloves = 48
    const LinenGloves = 46
    const Gloves = 45
    const Katana = 0
    const Falchion = 0
    const Scimitar = 0
    const LongSword = 0
    const ShortSword = 0
    const DemonHusk = 50
    const DragonskinArmor = 49
    const StuddedLeatherArmor = 48
    const HardLeatherArmor = 46
    const LeatherArmor = 45
    const DemonCrown = 50
    const DragonsCrown = 49
    const WarCap = 48
    const LeatherCap = 46
    const Cap = 45
    const DemonhideBelt = 0
    const DragonskinBelt = 0
    const StuddedLeatherBelt = 0
    const HardLeatherBelt = 0
    const LeatherBelt = 0
    const DemonhideBoots = 0
    const DragonskinBoots = 0
    const StuddedLeatherBoots = 0
    const HardLeatherBoots = 0
    const LeatherBoots = 0
    const DemonsHands = 50
    const DragonskinGloves = 49
    const StuddedLeatherGloves = 48
    const HardLeatherGloves = 46
    const LeatherGloves = 45
    const Warhammer = 0
    const Quarterstaff = 0
    const Maul = 0
    const Mace = 0
    const Club = 0
    const HolyChestplate = 100
    const OrnateChestplate = 98
    const PlateMail = 96
    const ChainMail = 93
    const RingMail = 90
    const AncientHelm = 50
    const OrnateHelm = 49
    const GreatHelm = 48
    const FullHelm = 47
    const Helm = 45
    const OrnateBelt = 0
    const WarBelt = 0
    const PlatedBelt = 0
    const MeshBelt = 0
    const HeavyBelt = 0
    const HolyGreaves = 50
    const OrnateGreaves = 49
    const Greaves = 48
    const ChainBoots = 47
    const HeavyBoots = 45
    const HolyGauntlets = 50
    const OrnateGauntlets = 49
    const Gauntlets = 48
    const ChainGloves = 46
    const HeavyGloves = 45
end

namespace ItemVitality:
    const Pendant = 0
    const Necklace = 0
    const Amulet = 0
    const SilverRing = 0
    const BronzeRing = 0
    const PlatinumRing = 0
    const TitaniumRing = 0
    const GoldRing = 0
    const GhostWand = 100
    const GraveWand = 98
    const BoneWand = 96
    const Wand = 93
    const Grimoire = 100
    const Chronicle = 98
    const Tome = 96
    const Book = 93
    const DivineRobe = 100
    const SilkRobe = 98
    const LinenRobe = 96
    const Robe = 93
    const Shirt = 90
    const Crown = 0
    const DivineHood = 0
    const SilkHood = 0
    const LinenHood = 0
    const Hood = 0
    const BrightsilkSash = 0
    const SilkSash = 0
    const WoolSash = 0
    const LinenSash = 0
    const Sash = 0
    const DivineSlippers = 0
    const SilkSlippers = 0
    const WoolShoes = 0
    const LinenShoes = 0
    const Shoes = 0
    const DivineGloves = 50
    const SilkGloves = 49
    const WoolGloves = 48
    const LinenGloves = 47
    const Gloves = 45
    const Katana = 0
    const Falchion = 0
    const Scimitar = 0
    const LongSword = 0
    const ShortSword = 0
    const DemonHusk = 0
    const DragonskinArmor = 0
    const StuddedLeatherArmor = 0
    const HardLeatherArmor = 0
    const LeatherArmor = 0
    const DemonCrown = 0
    const DragonsCrown = 0
    const WarCap = 0
    const LeatherCap = 0
    const Cap = 0
    const DemonhideBelt = 0
    const DragonskinBelt = 0
    const StuddedLeatherBelt = 0
    const HardLeatherBelt = 0
    const LeatherBelt = 0
    const DemonhideBoots = 0
    const DragonskinBoots = 0
    const StuddedLeatherBoots = 0
    const HardLeatherBoots = 0
    const LeatherBoots = 0
    const DemonsHands = 0
    const DragonskinGloves = 0
    const StuddedLeatherGloves = 0
    const HardLeatherGloves = 0
    const LeatherGloves = 0
    const Warhammer = 0
    const Quarterstaff = 0
    const Maul = 0
    const Mace = 0
    const Club = 0
    const HolyChestplate = 0
    const OrnateChestplate = 0
    const PlateMail = 0
    const ChainMail = 0
    const RingMail = 0
    const AncientHelm = 0
    const OrnateHelm = 0
    const GreatHelm = 0
    const FullHelm = 0
    const Helm = 0
    const OrnateBelt = 0
    const WarBelt = 0
    const PlatedBelt = 0
    const MeshBelt = 0
    const HeavyBelt = 0
    const HolyGreaves = 0
    const OrnateGreaves = 0
    const Greaves = 0
    const ChainBoots = 0
    const HeavyBoots = 0
    const HolyGauntlets = 0
    const OrnateGauntlets = 0
    const Gauntlets = 0
    const ChainGloves = 0
    const HeavyGloves = 0
end

namespace ItemWisdom:
    const Pendant = 0
    const Necklace = 0
    const Amulet = 0
    const SilverRing = 0
    const BronzeRing = 0
    const PlatinumRing = 0
    const TitaniumRing = 0
    const GoldRing = 0
    const GhostWand = 0
    const GraveWand = 0
    const BoneWand = 0
    const Wand = 0
    const Grimoire = 0
    const Chronicle = 0
    const Tome = 0
    const Book = 0
    const DivineRobe = 50
    const SilkRobe = 49
    const LinenRobe = 48
    const Robe = 47
    const Shirt = 45
    const Crown = 50
    const DivineHood = 49
    const SilkHood = 48
    const LinenHood = 47
    const Hood = 45
    const BrightsilkSash = 50
    const SilkSash = 49
    const WoolSash = 48
    const LinenSash = 47
    const Sash = 45
    const DivineSlippers = 0
    const SilkSlippers = 0
    const WoolShoes = 0
    const LinenShoes = 0
    const Shoes = 0
    const DivineGloves = 0
    const SilkGloves = 0
    const WoolGloves = 0
    const LinenGloves = 0
    const Gloves = 0
    const Katana = 0
    const Falchion = 0
    const Scimitar = 0
    const LongSword = 0
    const ShortSword = 0
    const DemonHusk = 50
    const DragonskinArmor = 49
    const StuddedLeatherArmor = 48
    const HardLeatherArmor = 47
    const LeatherArmor = 45
    const DemonCrown = 0
    const DragonsCrown = 0
    const WarCap = 0
    const LeatherCap = 0
    const Cap = 0
    const DemonhideBelt = 0
    const DragonskinBelt = 0
    const StuddedLeatherBelt = 0
    const HardLeatherBelt = 0
    const LeatherBelt = 0
    const DemonhideBoots = 50
    const DragonskinBoots = 49
    const StuddedLeatherBoots = 48
    const HardLeatherBoots = 46
    const LeatherBoots = 45
    const DemonsHands = 0
    const DragonskinGloves = 0
    const StuddedLeatherGloves = 0
    const HardLeatherGloves = 0
    const LeatherGloves = 0
    const Warhammer = 50
    const Quarterstaff = 49
    const Maul = 48
    const Mace = 46
    const Club = 45
    const HolyChestplate = 100
    const OrnateChestplate = 98
    const PlateMail = 96
    const ChainMail = 93
    const RingMail = 90
    const AncientHelm = 0
    const OrnateHelm = 0
    const GreatHelm = 0
    const FullHelm = 0
    const Helm = 0
    const OrnateBelt = 50
    const WarBelt = 49
    const PlatedBelt = 48
    const MeshBelt = 46
    const HeavyBelt = 45
    const HolyGreaves = 50
    const OrnateGreaves = 49
    const Greaves = 48
    const ChainBoots = 46
    const HeavyBoots = 45
    const HolyGauntlets = 0
    const OrnateGauntlets = 0
    const Gauntlets = 0
    const ChainGloves = 0
    const HeavyGloves = 0
end

namespace ItemAttack:
    const Pendant = 0
    const Necklace = 0
    const Amulet = 0
    const SilverRing = 0
    const BronzeRing = 0
    const PlatinumRing = 0
    const TitaniumRing = 0
    const GoldRing = 0
    const GhostWand = 100
    const GraveWand = 98
    const BoneWand = 96
    const Wand = 93
    const Grimoire = 90
    const Chronicle = 0
    const Tome = 0
    const Book = 0
    const DivineRobe = 0
    const SilkRobe = 0
    const LinenRobe = 0
    const Robe = 0
    const Shirt = 0
    const Crown = 0
    const DivineHood = 0
    const SilkHood = 0
    const LinenHood = 0
    const Hood = 0
    const BrightsilkSash = 0
    const SilkSash = 0
    const WoolSash = 0
    const LinenSash = 0
    const Sash = 0
    const DivineSlippers = 0
    const SilkSlippers = 0
    const WoolShoes = 0
    const LinenShoes = 0
    const Shoes = 0
    const DivineGloves = 0
    const SilkGloves = 0
    const WoolGloves = 0
    const LinenGloves = 0
    const Gloves = 0
    const Katana = 100
    const Falchion = 98
    const Scimitar = 96
    const LongSword = 93
    const ShortSword = 90
    const DemonHusk = 0
    const DragonskinArmor = 0
    const StuddedLeatherArmor = 0
    const HardLeatherArmor = 0
    const LeatherArmor = 0
    const DemonCrown = 0
    const DragonsCrown = 0
    const WarCap = 0
    const LeatherCap = 0
    const Cap = 0
    const DemonhideBelt = 50
    const DragonskinBelt = 49
    const StuddedLeatherBelt = 48
    const HardLeatherBelt = 46
    const LeatherBelt = 45
    const DemonhideBoots = 0
    const DragonskinBoots = 0
    const StuddedLeatherBoots = 0
    const HardLeatherBoots = 0
    const LeatherBoots = 0
    const DemonsHands = 50
    const DragonskinGloves = 49
    const StuddedLeatherGloves = 48
    const HardLeatherGloves = 47
    const LeatherGloves = 45
    const Warhammer = 150
    const Quarterstaff = 147
    const Maul = 144
    const Mace = 140
    const Club = 135
    const HolyChestplate = 0
    const OrnateChestplate = 0
    const PlateMail = 0
    const ChainMail = 0
    const RingMail = 0
    const AncientHelm = 50
    const OrnateHelm = 49
    const GreatHelm = 48
    const FullHelm = 46
    const Helm = 45
    const OrnateBelt = 50
    const WarBelt = 49
    const PlatedBelt = 48
    const MeshBelt = 47
    const HeavyBelt = 45
    const HolyGreaves = 0
    const OrnateGreaves = 0
    const Greaves = 0
    const ChainBoots = 0
    const HeavyBoots = 0
    const HolyGauntlets = 50
    const OrnateGauntlets = 49
    const Gauntlets = 48
    const ChainGloves = 47
    const HeavyGloves = 45
end
