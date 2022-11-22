%lang starknet

from starkware.cairo.common.math import unsigned_div_rem
from starkware.starknet.common.syscalls import get_block_timestamp

from contracts.loot.constants.item import Item
from contracts.loot.loot.stats.item import ItemStats
from contracts.settling_game.utils.general import unpack_data


namespace ItemLib {
    func update_adventurer{syscall_ptr: felt*, range_check_ptr}(item: Item, adventurerId: felt) -> Item {

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
        let (Rank) = ItemStats.item_rank(Id);  // stored state
        let (Prefix_1) = ItemStats.item_name_prefix(1);  // stored state
        let (Prefix_2) = ItemStats.item_name_suffix(1);  // stored state
        let (Suffix) = ItemStats.item_suffix(1);  // stored state
        let Greatness = 0;  // stored state
        let (CreatedBlock) = get_block_timestamp();  // timestamp
        let XP = 0;  // stored state
        let Adventurer = 0;
        let Bag = 0;

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
                Bag=Bag
            ),
        );

    }
}