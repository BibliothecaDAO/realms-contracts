%lang starknet

@contract_interface
namespace IERC1155 {
    func balanceOf(owner: felt, token_id: felt) -> (balance: felt) {
    }

    func balanceOfBatch(owners_len: felt, owners: felt*, tokens_id_len: felt, tokens_id: felt*) -> (
        balance_len: felt, balance: felt*
    ) {
    }

    func isApprovedForAll(account: felt, operator: felt) -> (res: felt) {
    }

    func setApprovalForAll(operator: felt, approved: felt) {
    }

    func safeTransferFrom(sender: felt, recipient: felt, token_id: felt, amount: felt) {
    }

    func safeBatchTransferFrom(
        sender: felt,
        recipient: felt,
        tokens_id_len: felt,
        tokens_id: felt*,
        amounts_len: felt,
        amounts: felt*,
    ) {
    }

    func mint(recipient: felt, token_id: felt, amount: felt) -> () {
    }

    func mintBatch(
        recipient: felt, token_ids_len: felt, token_ids: felt*, amounts_len: felt, amounts: felt*
    ) -> () {
    }

    func burn(account: felt, token_id: felt, amount: felt) {
    }

    func burnBatch(
        account: felt, token_ids_len: felt, token_ids: felt*, amounts_len: felt, amounts: felt*
    ) {
    }

    func getOwner() -> (owner: felt) {
    }

    func transferOwnership(next_owner: felt) {
    }
}
