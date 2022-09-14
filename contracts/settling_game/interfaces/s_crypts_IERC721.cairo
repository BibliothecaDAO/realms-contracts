%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace s_crypts_IERC721 {
    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
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
