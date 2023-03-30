%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.utils.game_structs import Point

@contract_interface
namespace ITravel {
    func assert_traveller_is_at_location(
        traveller_contract_id: felt,
        traveller_token_id: Uint256,
        traveller_nested_id: felt,
        destination_contract_id: felt,
        destination_token_id: Uint256,
        destination_nested_id: felt,
    ) {
    }

    func get_coordinates(contract_id: felt, token_id: Uint256, nested_id: felt) -> (point: Point) {
    }

    func set_coordinates(contract_id: felt, token_id: Uint256, nested_id: felt, point: Point) {
    }

    func forbid_travel(
        traveller_contract_id: felt, traveller_token_id: Uint256, traveller_nested_id: felt
    ) {
    }

    func allow_travel(
        traveller_contract_id: felt, traveller_token_id: Uint256, traveller_nested_id: felt
    ) -> () {
    }

    func assert_arrived(contract_id: felt, token_id: Uint256, nested_id: felt) {
    }
}
