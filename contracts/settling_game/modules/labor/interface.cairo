// Module Interfaces
// MIT License

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ILabor {
    func pillage(token_id: Uint256, claimer: felt) {
    }
}
