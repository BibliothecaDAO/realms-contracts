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

# Densities expressed in mg/cm^3
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
        const bone = 1155
        const StuddedLeather = cast((leather * (WeightModifier.Hide.studded / 100)), felt)
        const HardLeather = cast((leather * (WeightModifier.Hide.hard / 100)), felt)
        namespace Demon:
            const hide = cast((leather * (WeightModifier.Hide.demon / 100)), felt)
            const bone = cast((bone * (WeightModifier.Bone.demon / 100)), felt)
        end
        namespace Dragon:
            const skin = cast((leather * (WeightModifier.Hide.dragon / 100)), felt)
            const bone = cast((bone * (WeightModifier.Bone.dragon / 100)), felt)
        end
    end

    const Paper = 1200
    
    namespace Wood:
        namespace Hard:
            const walnut = 6900
            const mahogany = 8500
            const maple = 7500
            const oak = 9000
            const rosewood = 8800
            const cherry = 9000
            const balsa = 1400
            const birch = 6700
            const holly = 6400
        end
        namespace Soft:
            const elder = 4900
            const cedar = 5800
            const pine = 8500
            const fir = 7400
            const hemlock = 8000
            const spruce = 7100
            const yew = 6700
        end
    end
end