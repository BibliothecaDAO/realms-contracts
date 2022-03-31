%lang starknet
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC1155:
    func balanceOf(owner : felt, token_id : felt) -> (balance : felt):
    end

    func balanceOfBatch(
            owners_len : felt, owners : felt*, tokens_id_len : felt, tokens_id : felt*) -> (
            balance_len : felt, balance : felt*):
    end

    func isApprovedForAll(account : felt, operator : felt) -> (res : felt):
    end

    func setApprovalForAll(operator : felt, approved : felt):
    end

    func safeTransferFrom(_from : felt, to : felt, id : Uint256, amount : Uint256):
    end

    func safeBatchTransferFrom(
            _from : felt, to : felt, ids_len : felt, ids : Uint256*, amounts_len : felt,
            amounts : Uint256*):
    end

    func mint(to : felt, id : Uint256, amount : Uint256) -> ():
    end

    func mintBatch(
            to : felt, ids_len : felt, ids : Uint256*, amounts_len : felt, amounts : Uint256*) -> (
            ):
    end

    func burn(_from : felt, id : Uint256, amount : Uint256):
    end

    func burnBatch(
            _from : felt, ids_len : felt, ids : Uint256*, amounts_len : felt, amounts : Uint256*):
    end
end
