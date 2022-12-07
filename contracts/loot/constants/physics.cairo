// Core Physics
//   Physics for the game
//
//
// MIT License

%lang starknet

// Weight modifiers expressed as percentage of base material
namespace WeightModifier {
    namespace Metal {
        const ancient = 150;
        const holy = 135;
        const ornate = 120;
    }
    namespace Cloth {
        const royal = 150;
        const divine = 135;
        const brightsilk = 120;
    }
    namespace Hide {
        const demon = 150;
        const dragon = 135;
        const studded = 120;
        const hard = 105;
    }
    namespace Bone {
        const demon = 150;
        const dragon = 135;
    }
}

// Densities expressed in kg/m^3
namespace MaterialDensity {
    // TODO: this is a placeholder
    const generic = 0;

    namespace Metal {
        // TODO: this is a placeholder
        const generic = 0;
        const gold = 19300;
        const silver = 10490;
        const bronze = 8730;
        const platinum = 21450;
        const titanium = 4500;
        const steel = 7900;

        // ## TODO: This isn't valid right now, need another way to handle these
        const ancient = cast((steel * (WeightModifier.Metal.ancient / 100)), felt);  // steel * ancient modifier
        const holy = cast((steel * (WeightModifier.Metal.holy / 100)), felt);  // steel * holy modifier
        const ornate = cast((steel * (WeightModifier.Metal.ornate / 100)), felt);  // steel * ornate modifier
    }
    namespace Cloth {
        // TODO: this is a placeholder
        const generic = 0;
        const silk = 1370;  // single fiber of silk
        const wool = 1307;  // single fiber of wool
        const linen = 1280;  // single linen (flax) fiber
        const royal = cast((silk * (WeightModifier.Cloth.royal / 100)), felt);
        const divine = cast((silk * (WeightModifier.Cloth.divine / 100)), felt);
        const brightsilk = cast((silk * (WeightModifier.Cloth.brightsilk / 100)), felt);
    }
    namespace Biotic {
        // TODO: this is a placeholder
        const generic = 0;

        namespace Animal {
            // TODO: this is a placeholder
            const generic = 0;
            // TODO: this is a placeholder
            const blood = 0;
            // TODO: this is a placeholder
            const bones = 0;
            // TODO: this is a placeholder
            const brain = 0;
            // TODO: this is a placeholder
            const eyes = 0;

            const hide = 8600;

            // TODO: this is a placeholder
            const flesh = 0;
            // TODO: this is a placeholder
            const hair = 0;
            // TODO: this is a placeholder
            const heart = 0;
            // TODO: this is a placeholder
            const entrails = 0;
            // TODO: this is a placeholder
            const hands = 0;
            // TODO: this is a placeholder
            const feet = 0;

            const studded_leather = cast((hide * (WeightModifier.Hide.studded / 100)), felt);
            const hard_leather = cast((hide * (WeightModifier.Hide.hard / 100)), felt);
        }

        namespace Human {
            // TODO: this is a placeholder
            const generic = 0;
            // TODO: this is a placeholder
            const blood = 0;

            const bones = 1155;

            // TODO: this is a placeholder
            const brain = 0;
            // TODO: this is a placeholder
            const eyes = 0;
            // TODO: this is a placeholder
            const hide = 0;
            // TODO: this is a placeholder
            const flesh = 0;
            // TODO: this is a placeholder
            const hair = 0;
            // TODO: this is a placeholder
            const heart = 0;
            // TODO: this is a placeholder
            const entrails = 0;
            // TODO: this is a placeholder
            const hands = 0;
            // TODO: this is a placeholder
            const feet = 0;
        }

        namespace Demon {
            // TODO: this is a placeholder
            const generic = 0;
            // TODO: this is a placeholder
            const blood = 0;

            const bones = cast((Human.bones * (WeightModifier.Bone.demon / 100)), felt);

            // TODO: this is a placeholder
            const brain = 0;
            // TODO: this is a placeholder
            const eyes = 0;

            const hide = cast((Animal.hide * (WeightModifier.Hide.demon / 100)), felt);

            // TODO: this is a placeholder
            const flesh = 0;
            // TODO: this is a placeholder
            const hair = 0;
            // TODO: this is a placeholder
            const heart = 0;
            // TODO: this is a placeholder
            const entrails = 0;
            // TODO: this is a placeholder
            const hands = 0;
            // TODO: this is a placeholder
            const feet = 0;
        }

        namespace Dragon {
            // TODO: this is a placeholder
            const generic = 0;
            // TODO: this is a placeholder
            const blood = 0;

            const bones = cast((Human.bones * (WeightModifier.Bone.dragon / 100)), felt);

            // TODO: this is a placeholder
            const brain = 0;
            // TODO: this is a placeholder
            const eyes = 0;

            const skin = cast((Animal.hide * (WeightModifier.Hide.dragon / 100)), felt);

            // TODO: this is a placeholder
            const flesh = 0;
            // TODO: this is a placeholder
            const hair = 0;
            // TODO: this is a placeholder
            const heart = 0;
            // TODO: this is a placeholder
            const entrails = 0;
            // TODO: this is a placeholder
            const hands = 0;
            // TODO: this is a placeholder
            const feet = 0;
        }
    }

    namespace Paper {
        const generic = 1200;
        // TODO: this is a placeholder
        const magical = 0;
    }

    namespace Wood {
        // TODO: this is a placeholder
        const generic = 0;

        namespace Hard {
            // TODO: this is a placeholder
            const generic = 0;

            const walnut = 690;
            const mahogany = 850;
            const maple = 750;
            const oak = 900;
            const rosewood = 880;
            const cherry = 900;
            const balsa = 140;
            const birch = 670;
            const holly = 640;
        }
        namespace Soft {
            // TODO: this is a placeholder
            const generic = 0;

            const elder = 490;
            const cedar = 580;
            const pine = 850;
            const fir = 740;
            const hemlock = 800;
            const spruce = 710;
            const yew = 670;
        }
    }
}