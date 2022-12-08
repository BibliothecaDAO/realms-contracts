%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
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
        let (Rank) = ItemStats.item_rank(Id);  // determined by Id
        let Prefix_1 = 0;  // name prefix blank
        let Prefix_2 = 0;  // name suffix blank
        let Suffix = 0;  // suffix blank
        let Greatness = 0;  // greatness blank, random?
        let (CreatedBlock) = get_block_timestamp();  // timestamp
        let XP = 0;  // xp blank
        let Adventurer = 0; // adventurer blank
        let Bag = 0; // bag blank

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
                Bag=Bag
            ),
        );
    }
}