// Module Interfaces
// MIT License

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IFood {
    func available_food_in_store(token_id: Uint256) -> (available: felt) {
    }
    func get_full_store_houses(token_id: Uint256) -> (full_store_houses: felt) {
    }
}
