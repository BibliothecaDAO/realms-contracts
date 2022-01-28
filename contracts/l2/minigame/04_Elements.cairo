%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from contracts.l2.tokens.IERC1155 import IERC1155

############## Storage ################
@storage_var
func controller_address() -> (address : felt):
end

@storage_var
func elements_token_address() -> (address : felt):
end

# Stores the maximum amount of elements that should be minted
@storage_var
func elements_max() -> (max : felt):
end

# Stores the amount of elements minted for an L1,L2 address pair
@storage_var
func has_minted( l1_address : felt, l2_address : felt ) -> ( has_minted : felt ):
end

# Stores the contract address of the only account able to mint
@storage_var
func authorized_minter() -> ( minter_middleware : felt):
end

# ############ Constructor ##############

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }(
        address_of_controller : felt,
        address_of_elements_token : felt,
        address_of_minting_middleware : felt
    ):
    controller_address.write(address_of_controller) 
    elements_token_address.write(address_of_elements_token)

    # Minting middleware
    authorized_minter.write(address_of_minting_middleware)
    
    return ()
end

@external
func _set_authorized_minter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}( minter_middleware : felt):
    only_authorized_minter()
    authorized_minter.write(minter_middleware)
    return ()
end

############## External Functions ################

@external
func mint_elements{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        to : felt,
        tokens_id_len : felt,
        tokens_id : felt*,
        amounts_len : felt,
        amounts : felt*
    ):
    alloc_locals

    only_authorized_minter()

    let (local element_token) = elements_token_address.read()
    
    IERC1155.mint_batch(
        element_token,
        to,
        tokens_id_len,
        tokens_id, 
        amounts_len,
        amounts)

    return ()

end

############## Internal Functions ################

# Will revert if caller is not the authorized minter
func only_authorized_minter{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():

    alloc_locals
    let (local caller) = get_caller_address()
    let (allowed_minter) = authorized_minter.read()
    assert caller = allowed_minter

    return ()
end