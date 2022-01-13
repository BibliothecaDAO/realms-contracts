%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC1155:
    func uri() -> (res: felt):
    end

    func balance_of(owner : felt, token_id : felt) -> (res: felt):
    end

    func balance_of_batch(
        owners_len : felt, 
        owners : felt*, 
        tokens_id_len : felt, 
        tokens_id : felt*) -> (res_len: felt, res: felt*):
    end

    func is_approved_for_all(account : felt, operator : felt) -> (res: felt):
    end

    func set_approval_for_all(operator : felt, approved : felt) -> ():
    end

    func safe_transfer_from(
        _from : felt, 
        to : felt, 
        token_id : felt, 
        amount : felt):
    end

    func safe_batch_transfer_from(
        _from : felt, 
        to : felt, 
        tokens_id_len : felt, 
        tokens_id : felt*, 
        amounts_len : felt,        
        amounts : felt*
        ):
    end

    func _burn(
        _from : felt, 
        token_id : felt, 
        amount : felt) -> ():
    end

    func _burn_batch(
        _from : felt, 
        tokens_id_len : felt, 
        tokens_id : felt*, 
        amounts_len : felt, 
        amounts : felt*) -> (success: felt):
    end

end
