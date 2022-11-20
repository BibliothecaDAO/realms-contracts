%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.loot.constants.beast import Beast

@contract_interface
namespace IBeast {
    func create(adventurer_id: Uint256) -> (beast_id: Uint256) {
    }
    func get_beast_by_id(token_id: Uint256) -> (beast: Beast) {
    }
}