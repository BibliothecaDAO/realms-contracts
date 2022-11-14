%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.loot.constants.item import Item
from contracts.loot.constants.adventurer import AdventurerStatic, AdventurerDynamic

@contract_interface
namespace IAdventurer {
    func getAdventurerById(tokenId: Uint256) -> (
        adventurer_static: AdventurerStatic, adventurer_dynamic: AdventurerDynamic
    ) {
    }
    func updateAdventurer(tokenId: Uint256, adventurer: felt) {
    }
}
