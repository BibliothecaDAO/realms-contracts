%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ICalculator {
    func calculate_epoch() -> (epoch: felt) {
    }
    func calculate_happiness(token_id: Uint256) -> (happiness: felt) {
    }
    func calculate_troop_population(token_id: Uint256) -> (troop_population: felt) {
    }
    func calculate_population(token_id: Uint256) -> (population: felt) {
    }
    func calculate_food(token_id: Uint256) -> (food: felt) {
    }
    func calculate_tribute() -> (tribute: felt) {
    }
    func calculate_troop_coefficent(token_id: Uint256) -> (troop_coefficent: felt) {
    }
}
