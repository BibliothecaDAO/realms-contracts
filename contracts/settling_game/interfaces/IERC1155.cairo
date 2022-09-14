// Interface for ERC1155 Token
//   A standard interface for contracts that manage multiple token types.
//
// MIT License

%lang starknet
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC1155 {
    func balanceOf(owner: felt, token_id: Uint256) -> (balance: Uint256) {
    }

    func balanceOfBatch(
        owners_len: felt, owners: felt*, tokens_id_len: felt, tokens_id: Uint256*
    ) -> (balance_len: felt, balance: Uint256*) {
    }

    func isApprovedForAll(account: felt, operator: felt) -> (res: felt) {
    }

    func setApprovalForAll(operator: felt, approved: felt) {
    }

    func safeTransferFrom(
        _from: felt, to: felt, id: Uint256, amount: Uint256, data_len: felt, data: felt*
    ) {
    }

    func safeBatchTransferFrom(
        _from: felt,
        to: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*,
        data_len: felt,
        data: felt*,
    ) {
    }

    func mint(to: felt, id: Uint256, amount: Uint256, data_len: felt, data: felt*) -> () {
    }

    func mintBatch(
        to: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*,
        data_len: felt,
        data: felt*,
    ) -> () {
    }

    func burn(_from: felt, id: Uint256, amount: Uint256) {
    }

    func burnBatch(
        _from: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*
    ) {
    }
}
