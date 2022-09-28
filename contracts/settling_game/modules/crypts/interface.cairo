// Module Interfaces
// MIT License

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IL07_Crypts {
    func set_time_staked(token_id: Uint256, time_left: felt) {
    }
    func get_time_staked(token_id: Uint256) -> (time: felt) {
    }
    func return_approved() {
    }
}

@contract_interface
namespace IL08_Crypts_Resources {
    func check_if_claimable(token_id: Uint256) -> (can_claim: felt) {
    }
    func claim_resources(token_id: Uint256) {
    }
}
