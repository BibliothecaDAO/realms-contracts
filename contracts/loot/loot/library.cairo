%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.loot.constants.item import Item, NamePrefixLength, NameSuffixLength, ItemSuffixLength
from contracts.loot.loot.stats.item import ItemStats
from contracts.settling_game.utils.general import unpack_data

namespace ItemLib {
    func update_adventurer{syscall_ptr: felt*, range_check_ptr}(
        item: Item, adventurerId: felt
    ) -> Item {
        let updated_item = Item(
            Id=item.Id,
            Slot=item.Slot,
            Type=item.Type,
            Material=item.Material,
            Rank=item.Rank,
            Prefix_1=item.Prefix_1,
            Prefix_2=item.Prefix_2,
            Suffix=item.Suffix,
            Greatness=item.Greatness,
            CreatedBlock=item.CreatedBlock,
            XP=item.XP,
            Adventurer=adventurerId,
            Bag=item.Bag,
        );

        return updated_item;
    }

    func update_xp{syscall_ptr: felt*, range_check_ptr}(item: Item, xp: felt) -> Item {
        let updated_item = Item(
            Id=item.Id,
            Slot=item.Slot,
            Type=item.Type,
            Material=item.Material,
            Rank=item.Rank,
            Prefix_1=item.Prefix_1,
            Prefix_2=item.Prefix_2,
            Suffix=item.Suffix,
            Greatness=item.Greatness,
            CreatedBlock=item.CreatedBlock,
            XP=xp,
            Adventurer=item.Adventurer,
            Bag=item.Bag,
        );

        return updated_item;
    }

    func generate_random_item{syscall_ptr: felt*, range_check_ptr}(rnd: felt) -> (item: Item) {
        let (_, r) = unsigned_div_rem(rnd, 101);

        // set blank item
        let Id = r;
        let (Slot) = ItemStats.item_slot(Id);  // determined by Id
        let (Type) = ItemStats.item_type(Id);  // determined by Id
        let (Material) = ItemStats.item_material(Id);  // determined by Id
        let (Rank) = ItemStats.item_rank(Id);  // determined by Id
        let Prefix_1 = 0;  // name prefix blank
        let Prefix_2 = 0;  // name suffix blank
        let Suffix = 0;  // suffix blank
        let Greatness = 0;  // greatness blank, random?
        let (CreatedBlock) = get_block_timestamp();  // timestamp
        let XP = 0;  // xp blank
        let Adventurer = 0;  // adventurer blank
        let Bag = 0;  // bag blank

        return (
            Item(
                Id=Id,
                Slot=Slot,
                Type=Type,
                Material=Material,
                Rank=Rank,
                Prefix_1=Prefix_1,
                Prefix_2=Prefix_2,
                Suffix=Suffix,
                Greatness=Greatness,
                CreatedBlock=CreatedBlock,
                XP=XP,
                Adventurer=Adventurer,
                Bag=Bag,
            ),
        );
    }

    func set_item{syscall_ptr: felt*, range_check_ptr}(
        id: felt, greatness: felt, xp: felt, adventurer_id: felt, bag_id: felt
    ) -> (item: Item) {
        alloc_locals;

        // set blank item
        let Id = id;
        let (Slot) = ItemStats.item_slot(Id);  // determined by Id
        let (Type) = ItemStats.item_type(Id);  // determined by Id
        let (Material) = ItemStats.item_material(Id);  // determined by Id
        let (Rank) = ItemStats.item_rank(Id);  // determined by Id
        let check_ge_15 = is_le(15, greatness);
        if (check_ge_15 == TRUE) {
            let (Prefix_1) = ItemStats.item_name_prefix(1);  // stored state
            let (Prefix_2) = ItemStats.item_name_suffix(1);  // stored state
            let (Suffix) = ItemStats.item_suffix(1);  // stored state
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar Prefix_1 = Prefix_1;
            tempvar Prefix_2 = Prefix_2;
            tempvar Suffix = Suffix;
        } else {
            let Prefix_1 = 0;  // stored state
            let Prefix_2 = 0;  // stored state
            let Suffix = 0;  // stored state
            tempvar syscall_ptr: felt* = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar Prefix_1 = Prefix_1;
            tempvar Prefix_2 = Prefix_2;
            tempvar Suffix = Suffix;
        }
        let Greatness = greatness;  // stored state
        let (CreatedBlock) = get_block_timestamp();  // timestamp
        let XP = xp;  // stored state
        let Adventurer = adventurer_id;
        let Bag = bag_id;

        return (
            Item(
                Id=Id,
                Slot=Slot,
                Type=Type,
                Material=Material,
                Rank=Rank,
                Prefix_1=Prefix_1,
                Prefix_2=Prefix_2,
                Suffix=Suffix,
                Greatness=Greatness,
                CreatedBlock=CreatedBlock,
                XP=XP,
                Adventurer=Adventurer,
                Bag=Bag,
            ),
        );
    }

    // @notice Assigns a name prefix to a Loot item using the same schema as the OG Loot Contract
    // @param item: The Loot Item you want to assign a name prefix to
    // @param rnd: A random number
    // @return updated_item: The provided item with a canoncially sound name prefix added
    func assign_item_name_prefix{syscall_ptr: felt*, range_check_ptr}(item: Item, rnd: felt) -> (
        updated_item: Item
    ) {
        let (updated_name_prefix) = generate_name_prefix(item.Id, rnd);

        let updated_item = Item(
            Id=item.Id,
            Slot=item.Slot,
            Type=item.Type,
            Material=item.Material,
            Rank=item.Rank,
            Prefix_1=updated_name_prefix,
            Prefix_2=item.Prefix_2,
            Suffix=item.Suffix,
            Greatness=item.Greatness,
            CreatedBlock=item.CreatedBlock,
            XP=item.XP,
            Adventurer=item.Adventurer,
            Bag=item.Bag,
        );

        return updated_item;
    }

    // @notice Returns a name prefix for the provided random number that is consistent with the Loot Contract
    // @param item_id: The id of the item to get a name prefix for
    // @param rnd: A random number
    // @return name_prefix: The name prefix
    func generate_name_prefix{syscall_ptr: felt*, range_check_ptr}(item_id: felt, rnd: felt) -> (
        name_prefix: felt
    ) {
        // The Loot contract assigns the name prefixes here:
        // https://etherscan.io/token/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code#L1514
        //
        // If you look at:
        // https://github.com/Anish-Agnihotri/dhof-loot/blob/master/output/occurences.json
        //
        // You will realize that each item (i.e Katana) can only receive 1/3rd of the namePrefixes defined in the contract:
        // string[] private namePrefixes = [
        // "Agony", "Apocalypse", "Armageddon", "Beast", "Behemoth", "Blight", "Blood", "Bramble",
        // "Brimstone", "Brood", "Carrion", "Cataclysm", "Chimeric", "Corpse", "Corruption", "Damnation",
        // "Death", "Demon", "Dire", "Dragon", "Dread", "Doom", "Dusk", "Eagle", "Empyrean", "Fate", "Foe",
        // "Gale", "Ghoul", "Gloom", "Glyph", "Golem", "Grim", "Hate", "Havoc", "Honour", "Horror", "Hypnotic",
        // "Kraken", "Loath", "Maelstrom", "Mind", "Miracle", "Morbid", "Oblivion", "Onslaught", "Pain",
        // "Pandemonium", "Phoenix", "Plague", "Rage", "Rapture", "Rune", "Skull", "Sol", "Soul", "Sorrow",
        // "Spirit", "Storm", "Tempest", "Torment", "Vengeance", "Victory", "Viper", "Vortex", "Woe", "Wrath",
        // "Light's", "Shimmering"
        // ];

        // As an example, Katanas can receive the following name prefixes:
        // {Armageddon, Blight, Brimstone, Cataclysm, Corruption, Demon, Dread, Eagle, Foe, Gloom, Grim, Honour, Kraken
        //  Mind, Oblivion, Pandemonium, Rage, Skull, Sorrow, Tempest, Victory, Woe}
        //
        // If a katana is passed into this function, it should return one of the above names and only one of those
        let (item_slot) = ItemStats.item_slot(item_id);
        let (loot_slot_length) = ItemStats.loot_slot_length(item_slot);
        let (loot_item_index) = ItemStats.loot_item_index(item_id);
        // find a new random number that respects Loot constraints
        let new_rnd = rnd * loot_slot_length + loot_item_index;

        let (_, index) = unsigned_div_rem(new_rnd, NamePrefixLength);
        let (name_prefix) = ItemStats.item_name_prefix(index + 1);
        // verify if the prefix can be selected
        // banned prefixes are the ones that will never be selected due to
        // the greatness >= 19 condition in the original Loot
        let (is_banned) = ItemStats.loot_banned_name(name_prefix - 1);
        if (is_banned == 1) {
            // if banned select the next prefix
            let new_rnd = new_rnd + 1;
            let (_, index) = unsigned_div_rem(new_rnd, NamePrefixLength);
            let (name_prefix) = ItemStats.item_name_prefix(index + 1);
            return (name_prefix,);
        } else {
            return (name_prefix,);
        }
    }

    // @notice Assigns a name suffix to a Loot item using the same schema as the OG Loot Contract
    // @param item: The Loot Item you want to assign a name suffix to
    // @param rnd: A random number
    // @return updated_item: The provided item with a canoncially sound name suffix added
    func assign_item_name_suffix{syscall_ptr: felt*, range_check_ptr}(item: Item, rnd: felt) -> (
        updated_item: Item
    ) {
        let (updated_name_suffix) = generate_name_suffix(item.id, rnd);

        let updated_item = Item(
            Id=item.Id,
            Slot=item.Slot,
            Type=item.Type,
            Material=item.Material,
            Rank=item.Rank,
            Prefix_1=item.Prefix_1,
            Prefix_2=updated_name_suffix,
            Suffix=item.Suffix,
            Greatness=item.Greatness,
            CreatedBlock=item.CreatedBlock,
            XP=item.XP,
            Adventurer=item.Adventurer,
            Bag=item.Bag,
        );

        return updated_item;
    }

    // @notice Returns a name suffix for the provided item that is consistent with the Loot Contract
    // @param item_id: The id of a Loot
    // @param rnd: A random number
    // @return name_suffix for the item
    func generate_name_suffix{syscall_ptr: felt*, range_check_ptr}(item_id: felt, rnd: felt) -> (
        name_suffix: felt
    ) {
        // The Loot contract assigns the name suffixes here:
        // https://etherscan.io/token/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code#L1510
        //
        // If you look at:
        // https://github.com/Anish-Agnihotri/dhof-loot/blob/master/output/occurences.json
        //
        // You will see that each weapon uses a single name suffix and other items only receive a subset of the total set of suffixed.
        // For example all Katanas have the name suffix "Grasp" such as "Demon Grasp" Katan of Skill +1
        // All Grimoires have the name suffix "Peak" such as "Shimmering Peak" Grimoire of Perfection +1

        // string[] private nameSuffixes = [
        // "Bane",
        // "Root",
        // "Bite",
        // "Song",
        // "Roar",
        // "Grasp",
        // "Instrument",
        // "Glow",
        // "Bender",
        // "Shadow",
        // "Whisper",
        // "Shout",
        // "Growl",
        // "Tear",
        // "Peak",
        // "Form",
        // "Sun",
        // "Moon"
        // ];
        let (item_slot) = ItemStats.item_slot(item_id);
        let (loot_slot_length) = ItemStats.loot_slot_length(item_slot);
        let (loot_item_index) = ItemStats.loot_item_index(item_id);
        // find a new random number that respects Loot constraints
        let new_rnd = rnd * loot_slot_length + loot_item_index;

        let (_, index) = unsigned_div_rem(new_rnd, NameSuffixLength);
        let (name_suffix) = ItemStats.item_name_suffix(index + 1);
        // verify if the suffix can be selected
        // banned suffixes are the ones that will never be selected due to
        // the greatness > 14 condition in the original Loot
        let (is_banned) = ItemStats.loot_banned_name(name_suffix - 1);
        if (is_banned == 1) {
            // if banned select the next suffix
            let new_rnd = new_rnd + 1;
            let (_, index) = unsigned_div_rem(new_rnd, NameSuffixLength);
            let (name_suffix) = ItemStats.item_name_suffix(index + 1);
            return (name_suffix,);
        } else {
            return (name_suffix,);
        }
    }

    // @notice Assigns a suffix to a Loot item using the same schema as the OG Loot Contract
    // @param item: The Loot Item you want to assign a suffix to
    // @param rnd: A random number
    // @return updated_item: The provided item with a canoncially sound suffix added
    func assign_item_suffix{syscall_ptr: felt*, range_check_ptr}(item: Item, rnd: felt) -> Item {
        let (updated_suffix) = generate_item_suffix(item.Id, rnd);

        let updated_item = Item(
            Id=item.Id,
            Slot=item.Slot,
            Type=item.Type,
            Material=item.Material,
            Rank=item.Rank,
            Prefix_1=item.Prefix_1,
            Prefix_2=item.Prefix_2,
            Suffix=updated_suffix,
            Greatness=item.Greatness,
            CreatedBlock=item.CreatedBlock,
            XP=item.XP,
            Adventurer=item.Adventurer,
            Bag=item.Bag,
        );

        return updated_item;
    }

    // @notice Returns an item suffix for the provided item that is consistent with the Loot Contract
    // @param item_id: The id of the item to get a name prefix for
    // @param rnd: A random number
    // @return item_suffix: An item suffix
    func generate_item_suffix{syscall_ptr: felt*, range_check_ptr}(item_id: felt, rnd: felt) -> (
        item_suffix: felt
    ) {
        // The Loot contract assigns the item suffix here:
        // https://etherscan.io/token/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code#L1510
        //
        // If you look at:
        // https://github.com/Anish-Agnihotri/dhof-loot/blob/master/output/occurences.json
        //
        // You will see that each weapon only receives half of the total set of suffixes/Orders

        // For example Katanas only receive the suffixes/Orders:
        // {of Giants, of Skill, of Brilliance, of Protection, of Rage, of Vitriol, of Detection, of the Twins}

        // Whereas Grimoires only receive the other half:
        // {of Power, of Titans, of Perfection, of Enlightenment, of Anger, of Fury, of the Fox, of Reflection}

        // string[] private suffixes = [
        //     "of Power",
        //     "of Giants",
        //     "of Titans",
        //     "of Skill",
        //     "of Perfection",
        //     "of Brilliance",
        //     "of Enlightenment",
        //     "of Protection",
        //     "of Anger",
        //     "of Rage",
        //     "of Fury",
        //     "of Vitriol",
        //     "of the Fox",
        //     "of Detection",
        //     "of Reflection",
        //     "of the Twins"
        // ];

        let (item_slot) = ItemStats.item_slot(item_id);
        let (loot_slot_length) = ItemStats.loot_slot_length(item_slot);
        let (loot_item_index) = ItemStats.loot_item_index(item_id);
        // find a new random number that respects Loot constraints
        let new_rnd = rnd * loot_slot_length + loot_item_index;

        let (_, index) = unsigned_div_rem(new_rnd, ItemSuffixLength);
        let (item_suffix) = ItemStats.item_suffix(index + 1);
        return (item_suffix,);
    }
}
