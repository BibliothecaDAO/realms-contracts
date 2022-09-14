%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IResources {
    func claim_resources(token_id: Uint256) {
    }

    func pillage_resources(token_id: Uint256, claimer: felt) {
    }

    func days_accrued(token_id: Uint256) -> (days_accrued: felt, remainder: felt) {
    }

    func vault_days_accrued(token_id: Uint256) -> (days_accrued: felt, remainder: felt) {
    }

    func get_available_vault_days(token_id: Uint256) -> (days_accrued: felt, remainder: felt) {
    }

    func check_if_claimable(token_id: Uint256) -> (can_claim: felt) {
    }

    func get_all_resource_claimable(token_id: Uint256) -> (
        user_mint_len: felt, user_mint: Uint256*
    ) {
    }

    func get_all_vault_raidable(token_id: Uint256) -> (
        vault_mint_len: felt,
        vault_mint: Uint256*,
        total_vault_days: felt,
        total_vault_days_remaining: felt,
    ) {
    }

    func wonder_claim(token_id: Uint256) {
    }
}
