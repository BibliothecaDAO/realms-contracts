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
namespace realms_IERC721 {
    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func balanceOf(owner: felt) -> (balance: Uint256) {
    }

    func ownerOf(token_id: Uint256) -> (owner: felt) {
    }

    func safeTransferFrom(_from: felt, to: felt, token_id: Uint256, data_len: felt, data: felt*) {
    }

    func transferFrom(_from: felt, to: felt, token_id: Uint256) {
    }

    func approve(approved: felt, token_id: Uint256) {
    }

    func setApprovalForAll(operator: felt, approved: felt) {
    }

    func getApproved(token_id: Uint256) -> (approved: felt) {
    }

    func isApprovedForAll(owner: felt, operator: felt) -> (is_approved: felt) {
    }

    func get_is_settled(token_id: Uint256) -> (is_settled: felt) {
    }

    func settleState(token_id: Uint256, settle_state: felt) -> (is_settled: felt) {
    }

    func fetch_realm_data(token_id: Uint256) -> (realm_data: RealmData) {
    }
}
