# Item Structs
#   A struct that holds the Loot item statistics
#
#
# MIT License

%lang starknet

from contracts.loot.constants.item import (
    ItemMaterial,
    Material,
    ItemType,
)

func item_vs_damage{syscall_ptr : felt*, range_check_ptr}(
        item_attacking_id : felt, item_defending_id : felt
    ) -> (class : felt):
        alloc_locals

        let (a_slot) = get_label_location(item_a_slot)

        let (d_slot) = get_label_location(item_d_slot)

        return ([a_slot + item_attacking_id - 1] + [a_slot + item_defending_id - 1])

        item_a_slot:
        dw ItemType.GhostWand
        dw ItemType.GraveWand
        dw ItemType.BoneWand
        dw ItemType.Wand

        dw ItemType.Grimoire
        dw ItemType.Chronicle
        dw ItemType.Tome
        dw ItemType.Book

        dw ItemType.Warhammer
        dw ItemType.Quarterstaff
        dw ItemType.Maul
        dw ItemType.Mace
        dw ItemType.Club

        dw ItemType.Katana
        dw ItemType.Falchion
        dw ItemType.Scimitar
        dw ItemType.LongSword
        dw ItemType.ShortSword
        # TODO: add
        
        item_d_slot:
        dw ItemType.HolyChestplate
        dw ItemType.OrnateChestplate
        dw ItemType.PlateMail
        dw ItemType.ChainMail
        dw ItemType.RingMail
        # TODO: add
    end
## Todo: Figure out ideal data structure for communicate the following basic combat rules:
    ## Blade vs Cloth = Critical Damage
    ## Blade vs Hide == Normal Damage
    ## Blade vs Metal == Minimal Damage

    ## Bludgeon vs Metal == Critical Damage
    ## Bludgeon vs Hide == Normal Damage
    ## Bludgeon vs Cloth == Minimal Damage

    ## Magic vs Metal == Critical Damage
    ## Magic vs Hide == Normal Damage
    ## Magic vs Cloth == Minimal Damage