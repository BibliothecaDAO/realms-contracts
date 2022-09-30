%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.utils.game_structs import CryptData

@contract_interface
namespace ICrypts {
    func get_is_unlocked(token_id: Uint256) -> (is_unlocked: felt) {
    }

    func lockState(token_id: Uint256, lock_state: felt) -> (is_unlocked: felt) {
    }

    func fetch_crypt_data(token_id: Uint256) -> (crypt_data: CryptData) {
    }
}
