%lang starknet
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ISettling {
    func settle(token_id: Uint256) -> (success: felt) {
    }
    func unsettle(token_id: Uint256) -> (success: felt) {
    }
    func set_time_staked(token_id: Uint256, time_left: felt) {
    }
    func set_time_vault_staked(token_id: Uint256, time_left: felt) {
    }
    func get_time_staked(token_id: Uint256) -> (time: felt) {
    }
    func get_time_vault_staked(token_id: Uint256) -> (time: felt) {
    }
    func get_total_realms_settled() -> (amount: felt) {
    }
}
