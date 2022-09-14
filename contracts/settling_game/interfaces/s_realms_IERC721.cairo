// Interface for Staked Realms ERC721 token
//   Token that is sent to wallet when a user stakes a Realm
//   and burned when the user unstakes a Realm
//
// MIT License

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace s_realms_IERC721 {
    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func tokenByIndex(index: Uint256) -> (tokenId: Uint256) {
    }

    func tokenOfOwnerByIndex(owner: felt, index: Uint256) -> (tokenId: Uint256) {
    }

    func balanceOf(owner: felt) -> (balance: Uint256) {
    }

    func ownerOf(token_id: Uint256) -> (owner: felt) {
    }

    func safeTransferFrom(_from: felt, to: felt, token_id: Uint256, data: felt) {
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

    func mint(to: felt, token_id: Uint256) {
    }

    func burn(token_id: Uint256) {
    }
}
