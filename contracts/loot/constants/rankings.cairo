# Item Structs
#   A struct that holds the Loot item statistics
#
#
# MIT License

%lang starknet

namespace Ranking:
    namespace Weapons:
        namespace Bludgeon:
            const Warhammer = 1
            const Quarterstaff = 2
            const Maul = 3
            const Mace = 4
            const Club = 5
        end
        namespace Blade:            
            const Katana = 1
            const Falchion = 2
            const Scimitar = 3
            const LongSword = 4
            const ShortSword = 5
        end
        namespace Wand:
            const GhostWand = 1
            const GraveWand = 2
            const BoneWand = 3
            const Wand = 4
        end
        namespace Book:
            const Grimoire = 1
            const Chronicle = 2
            const Tome = 3
            const Book = 4
        end
    end
    namespace Armor:
        namespace Chest:
            namespace Metal:
                const HolyChestplate = 1
                const OrnateChestplate = 2
                const PlateMail = 3
                const ChainMail = 4
                const RingMail = 5
            end
            namespace Biotic:
                const DemonHusk = 1
                const DragonskinArmor = 2
                const StuddedLeatherArmor = 3
                const HardLeatherArmor = 4
                const LeatherArmor = 5
            end
            namespace Cloth:
                const DivineRobe = 1
                const SilkRobe = 2
                const LinenRobe = 3
                const Robe = 4
                const Shirt = 5
            end
        end
        namespace Head:
            namespace Metal:
                const AncientHelm = 1
                const OrnateHelm = 2
                const GreatHelm = 3
                const FullHelm = 4
                const Helm = 5
            end
            namespace Biotic:
                const DemonCrown = 1
                const DragonsCrown = 2
                const WarCap = 3
                const LeatherCap = 4
                const Cap = 5
            end
            namespace Cloth:
                const Crown = 1
                const DivineHood = 2
                const SilkHood = 3
                const LinenHood = 4
                const Hood = 5
            end
        end
        namespace Waist:
            namespace Metal:
                const OrnateBelt = 1
                const WarBelt = 2
                const PlatedBelt = 3
                const MeshBelt = 4
                const HeavyBelt = 5
            end
            namespace Biotic:
                const DemonhideBelt = 1
                const DragonskinBelt = 2
                const StuddedLeatherBelt = 3
                const HardLeatherBelt = 4
                const LeatherBelt = 5
            end
            namespace Cloth:
                const BrightsilkSash = 1
                const SilkSash = 2
                const WoolSash = 3
                const LinenSash = 4
                const Sash = 5
            end
        end
        namespace Foot:
            namespace Metal:
                const HolyGreaves = 1
                const OrnateGreaves = 2
                const Greaves = 3
                const ChainBoots = 4
                const HeavyBoots = 5
            end
            namespace Biotic:
                const DemonhideBoots = 1
                const DragonskinBoots = 2
                const StuddedLeatherBoots = 3
                const HardLeatherBoots = 4
                const LeatherBoots = 5
            end
            namespace Cloth:
                const DivineSlippers = 1
                const SilkSlippers = 2
                const WoolShoes = 3
                const LinenShoes = 4
                const Shoes = 5
            end
        end
        namespace Hand:
            namespace Metal:
                const HolyGauntlets = 1
                const OrnateGauntlets = 2
                const Gauntlets = 3
                const ChainGloves = 4
                const HeavyGloves = 5
            end
            namespace Biotic:
                const DemonsHands = 1
                const DragonskinGloves = 2
                const StuddedLeatherGloves = 3
                const HardLeatherGloves = 4
                const LeatherGloves = 5
            end
            namespace Cloth:
                const DivineGloves = 1
                const SilkGloves = 2
                const WoolGloves = 3
                const LinenGloves = 4
                const Gloves = 5
            end
        end
    end
    namespace Jewlery:
        namespace Necklace:
            const Pendant = 1
            const Necklace = 1
            const Amulet = 1
        end
        namespace Ring:
            const PlatinumRing = 1
            const TitaniumRing = 1
            const GoldRing = 1
            const SilverRing = 2 
            const BronzeRing = 3
        end
    end
end