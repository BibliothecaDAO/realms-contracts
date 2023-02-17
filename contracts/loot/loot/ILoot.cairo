%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.loot.constants.item import Item

@contract_interface
namespace ILoot {
    func get_item_by_token_id(tokenId: Uint256) -> (item: Item) {
    }
    func update_adventurer(tokenId: Uint256, adventurer: felt) {
    }
    func mint_starter_weapon(to: felt, weapon_id: felt, adventurer_token_id: Uint256) -> (
        item_token_id: Uint256
    ) {
    }
    func mint_from_mart(to: felt, weapon_id: felt, adventurer_token_id: Uint256){
    }
    func mint(to: felt, adventurer_token_id: Uint256) -> (item_token_id: Uint256) {
    }
    func item_owner(tokenId: Uint256, adventurer_token_id: Uint256) -> (owner: felt) {
    }
    func get_adventurer_owner(tokenId: Uint256) -> (adventuer_token_id: Uint256) {
    }
    func increase_xp(tokenId: Uint256, amount: felt) -> (success: felt) {
    }
}
