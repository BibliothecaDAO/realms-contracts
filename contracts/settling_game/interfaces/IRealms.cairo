// Interface for Realms ERC721 Implementation
//   Realms token that can be staked/unstaked
//
// MIT License

%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.utils.game_structs import RealmData

@contract_interface
namespace IERC165 {
    func supportsInterface(interface_id: felt) -> (success: felt) {
    }
}

@contract_interface
namespace IRealms {
    func get_realm_name(token_id: Uint256) -> (realm_name: felt) {
    }
    func fetch_realm_data(token_id: Uint256) -> (realm_data: RealmData) {
    }
}
