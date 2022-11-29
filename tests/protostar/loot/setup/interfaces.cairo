%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.loot.constants.adventurer import AdventurerState, PackedAdventurerState
from contracts.loot.constants.beast import Beast, BeastStatic, BeastDynamic
from contracts.loot.constants.item import Item

@contract_interface
namespace IController {
    func initializer(arbiter: felt, proxy_admin: felt) {
    }
    func set_address_for_module_id(module_id: felt, module_address: felt) {
    }
    func set_write_access(module_id_doing_writing: felt, module_id_being_written_to: felt) {
    }
    func set_address_for_external_contract(external_contract_id: felt, contract: felt) {
    }
    func set_xoroshiro(xoroshiro: felt) {
    }

}

@contract_interface
namespace IRealms {
    func initializer(name: felt, symbol: felt, proxy_admin: felt) {
    }
    func set_realm_data(tokenId: Uint256, _realm_name: felt, _realm_data: felt) {
    }
}

@contract_interface
namespace ILoot {
    func initializer(
        name: felt, 
        symbol: felt, 
        proxy_admin: felt, 
        controller_address: felt
    ) {
    }
    func mint(to: felt) {
    }
    func updateAdventurer(tokenId: Uint256, adventurerId: felt) {
    }
    func setItemById(
        tokenId: Uint256,
        item: Item
    ) {
    }
    func getItemByTokenId(tokenId: Uint256) -> (item: Item) {
    }
    func tokenURI(tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
    }
}

@contract_interface
namespace IAdventurer {
    func initializer(
        name: felt,
        symbol: felt,
        proxy_admin: felt,
        address_of_controller: felt,
    ) {
    }
    func mint(to: felt, race: felt, home_realm: felt, name: felt, order: felt) {
    }
    func equip_item(tokenId: Uint256, itemTokenId: Uint256) -> (success: felt) {
    }
    func unequip_item(tokenId: Uint256, itemTokenId: Uint256) -> (success: felt) {
    }
    func deduct_health(tokenId: Uint256, amount: felt) -> (success: felt) {
    }
    func increase_xp(tokenId: Uint256, amount: felt) -> (success: felt) {
    }
    func explore(token_id: Uint256) -> (success: felt) {
    }
    func tokenURI(tokenId: Uint256) -> (tokenURI_len: felt, tokenURI: felt*) {
    }
    func get_adventurer_by_id(tokenId: Uint256) -> (adventurer: AdventurerState) {
    }
}

@contract_interface
namespace IBeast {
    func initializer(proxy_admin: felt, address_of_controller: felt) {
    }
    func create(adventurer_token_id: Uint256) -> (beast_token_id: Uint256) {
    }
    func attack(beast_token_id: Uint256) {
    }
    func counter_attack(beast_token_id: Uint256) -> (damage: felt) {
    }
    func flee(beast_token_id: Uint256) {
    }
    func set_beast_by_id(beast_token_id: Uint256, beast: Beast) {
    }
    func get_beast_by_id(beast_token_id: Uint256) -> (beast: Beast) {
    }
    func increase_xp(beast_token_id: Uint256, beast_dynamic: BeastDynamic, amount: felt) -> (
        returned_beast_dynamic: BeastDynamic
    ) {
    }
    func get_adventurer_from_beast(beast_token_id: Uint256) -> () {
    }
}

@contract_interface
namespace ILords {
    func initializer(
        name: felt,
        symbol: felt,
        decimals: felt,
        initial_supply: Uint256,
        recipient: felt,
        proxy_admin: felt,
    ) {
    }
    func balanceOf(owner: felt) -> (balance: Uint256) {
    }
    func approve(spender: felt, amount: Uint256) -> (success: felt) {
    }
    func allowance(owner: felt, spender: felt) -> (allowance: Uint256) {
    }
}

@contract_interface
namespace IXoroshiro {
    func next() -> (rand: felt) {
    }
}