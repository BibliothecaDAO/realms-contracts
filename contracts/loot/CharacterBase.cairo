# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem
from starkware.cairo.common.uint256 import (Uint256, uint256_le)

from contracts.token.IERC721 import IERC721

## Storage of Items

@storage_var
func weapon(token_id: felt) -> (item_token_id: felt):
end

@external
func equipItem{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token_id: felt, item_token_id: felt):

    ## Check user owns the item
    ## Check item is correct for the slot
    ## TODO: Set Id within slot


    return ()
end

@external
func getPower{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token_id: felt, item_token_id: felt):
    
    # SUM all item powers
    # Fetch item stats

    return ()
end   

