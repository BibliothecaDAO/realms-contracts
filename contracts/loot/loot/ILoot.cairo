%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.loot.constants.item import Item

@contract_interface
namespace ILoot:
    func getItemByTokenId(tokenId : Uint256) -> (item : Item):
    end
    func updateAdventurer(tokenId : Uint256, adventurer : felt):
    end
end
