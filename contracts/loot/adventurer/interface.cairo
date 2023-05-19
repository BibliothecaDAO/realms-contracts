%lang starknet

from starkware.cairo.common.uint256 import Uint256

from contracts.loot.constants.adventurer import AdventurerState, AdventurerDynamic

@contract_interface
namespace IAdventurer {
    func owner_of(tokenId: Uint256) -> (owner: felt) {
    }
    func get_adventurer_by_id(tokenId: Uint256) -> (adventurer: AdventurerState) {
    }
    func deduct_health(tokenId: Uint256, amount: felt) -> (adventurer_dynamic: AdventurerDynamic) {
    }
    func increase_xp(tokenId: Uint256, amount: felt) -> (success: felt) {
    }
    func update_status(tokenId: Uint256, status: felt) -> (success: felt) {
    }
    func assign_beast(tokenId: Uint256, value: felt) -> (success: felt) {
    }
    func explore(tokenId: Uint256) -> (success: felt) {
    }
    func update_adventurer(adventurer_token_id: Uint256, adventurer_dynamic: AdventurerDynamic) {
    }
}
