%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.loot.constants.beast import Beast

@contract_interface
namespace IBeast {
    func birth() -> (beast_id: felt) {
    }
    func get_beast_by_id(tokenId: felt) -> (beast: Beast) {
    }
}