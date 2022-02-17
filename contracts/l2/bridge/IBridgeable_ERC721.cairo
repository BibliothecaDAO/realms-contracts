%lang starknet

from starkware.cairo.common.uint256 import (
    Uint256
)

@contract_interface
namespace IBridgeable_ERC721:
    func bridge_mint(to: felt, token_id: Uint256):
    end
end
