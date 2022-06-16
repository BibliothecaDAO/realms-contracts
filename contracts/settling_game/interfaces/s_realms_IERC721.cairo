# Interface for Staked Realms ERC721 token
#   Token that is sent to wallet when a user stakes a Realm
#   and burned when the user unstakes a Realm
#
# MIT License

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace s_realms_IERC721:
    func name() -> (name : felt):
    end

    func symbol() -> (symbol : felt):
    end

    func tokenByIndex(index : Uint256) -> (tokenId : Uint256):
    end

    func tokenOfOwnerByIndex(owner : felt, index : Uint256) -> (tokenId : Uint256):
    end

    func balanceOf(owner : felt) -> (balance : Uint256):
    end

    func ownerOf(token_id : Uint256) -> (owner : felt):
    end

    func safeTransferFrom(_from : felt, to : felt, token_id : Uint256, data : felt):
    end

    func transferFrom(_from : felt, to : felt, token_id : Uint256):
    end

    func approve(approved : felt, token_id : Uint256):
    end

    func setApprovalForAll(operator : felt, approved : felt):
    end

    func getApproved(token_id : Uint256) -> (approved : felt):
    end

    func isApprovedForAll(owner : felt, operator : felt) -> (is_approved : felt):
    end

    func mint(to : felt, token_id : Uint256):
    end

    func burn(token_id : Uint256):
    end
end
