# Core Physics
#   Physics for the game
#
#
# MIT License

%lang starknet

# Weight modifiers expressed as percentage of base material
namespace WeightModifier:
    namespace Metal:
        const ancient = 150
        const holy = 135
        const ornate = 120
    end
    namespace Cloth:
        const royal = 150
        const divine = 135
        const brightsilk = 120
    end
    namespace Hide:
        const demon = 150
        const dragon = 135
        const studded = 120
        const hard = 105
    end
    namespace Bone:
        const demon = 150
        const dragon = 135
    end
end

# Densities expressed in kg/m^3
namespace MaterialDensity:
    namespace Metal:
        const gold = 19300
        const silver = 10490
        const bronze = 8730
        const platinum = 21450
        const titanium = 4500
        const steel = 7900

        ### TODO: This isn't valid right now, need another way to handle these
        const ancient = cast((steel * (WeightModifier.Metal.ancient / 100)), felt) # steel * ancient modifier
        const holy = cast((steel * (WeightModifier.Metal.holy / 100)), felt) # steel * holy modifier
        const ornate = cast((steel * (WeightModifier.Metal.ornate / 100)), felt) # steel * ornate modifier
    end
    namespace Cloth:
        const silk = 1370 # single fiber of silk
        const wool = 1307 # single fiber of wool
        const linen = 1280 # single linen (flax) fiber
        const royal = cast((silk * (WeightModifier.Cloth.royal / 100)), felt)
        const divine = cast((silk * (WeightModifier.Cloth.divine / 100)), felt)
        const brightsilk = cast((silk * (WeightModifier.Cloth.brightsilk / 100)), felt)
    end
    namespace Biotic:
        const leather = 8600
        const human_bone = 1155
        const studded_leather = cast((leather * (WeightModifier.Hide.studded / 100)), felt)
        const hard_leather = cast((leather * (WeightModifier.Hide.hard / 100)), felt)
        namespace Demon:
            const hide = cast((leather * (WeightModifier.Hide.demon / 100)), felt)
            const demon_bone = cast((human_bone * (WeightModifier.Bone.demon / 100)), felt)
        end
        namespace Dragon:
            const skin = cast((leather * (WeightModifier.Hide.dragon / 100)), felt)
            const dragon_bone = cast((human_bone * (WeightModifier.Bone.dragon / 100)), felt)
        end
    end

    const Paper = 1200
    
    namespace Wood:
        namespace Hard:
            const walnut = 690
            const mahogany = 850
            const maple = 750
            const oak = 900
            const rosewood = 880
            const cherry = 900
            const balsa = 140
            const birch = 670
            const holly = 640
        end
        namespace Soft:
            const elder = 490
            const cedar = 580
            const pine = 850
            const fir = 740
            const hemlock = 800
            const spruce = 710
            const yew = 670
        end
    end
end