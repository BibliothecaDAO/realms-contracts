%lang starknet

from contracts.loot.constants.item import Item

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
}