%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.loot.constants.beast import Beast, BeastDynamic

@contract_interface
namespace IBeast {
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