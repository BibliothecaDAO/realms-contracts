// Module Interfaces
// MIT License

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IRelics {
    func set_relic_holder(winner_token_id: Uint256, loser_token_id: Uint256) {
    }
    func is_relic_at_home(token_id: Uint256) -> (yesno: felt) {
    }
    func return_relics(realm_token_id: Uint256) {
    }
}
