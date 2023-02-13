// Module Interfaces
// MIT License

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IGoblinTown {
    func spawn_goblin_welcomparty(realm_id: Uint256) {
    }

    func get_strength_and_timestamp(realm_id: Uint256) -> (strength: felt, spawn_ts: felt) {
    }

    func spawn_next(realm_id: Uint256) {
    }
}
