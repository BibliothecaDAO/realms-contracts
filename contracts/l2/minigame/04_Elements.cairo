%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from contracts.l2.minigame.utils.interfaces import IModuleController, I02_TowerStorage
from contracts.l2.tokens.IERC1155 import IERC1155

############## Storage ################
@storage_var
func controller_address() -> (address : felt):
end

@storage_var
func elements_token_address() -> (address : felt):
end

# Stores whether a (L1,L2) address pair has minted
# for a given game idx
@storage_var
func has_minted( l1_address : felt, l2_address : felt, game_idx : felt ) -> ( has_minted : felt ):
end

# token IDs vary each game so token_id is only param required
@storage_var
func total_minted( token_id : felt ) -> ( total : felt ):
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


############## External Functions ################

@external
func mint_elements{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_idx : felt,
        from_l1_address : felt,
        to : felt,
        token_id : felt,
        amount : felt
    ):
    alloc_locals

    only_authorized_minter()

    # Ensure user hasn't minted for the next game
    let (local controller) = controller_address.read()

    let (local tower_defence_storage) = IModuleController.get_module_address(
        controller, 2)
    let (local latest_index) = I02_TowerStorage.get_latest_game_index(tower_defence_storage)

    tempvar next_game_index = latest_index + 1

    # Only allow minting for the next game
    # Minting assets for current game not allowed
    assert game_idx = next_game_index

    # Check if already minted
    let (minted_already) = has_minted.read( from_l1_address, to, next_game_index )
    assert minted_already = 0
    # Prevent minting again for this game
    has_minted.write(from_l1_address, to, next_game_index, 1)

    # Increment total minted
    let (local prev_total) = total_minted.read( token_id )

    total_minted.write( token_id, prev_total + amount )

    let (local element_token) = elements_token_address.read()
    
    IERC1155.mint(
        element_token,
        to,
        token_id,
        amount
    )

    return ()

end

# This module is considered the owner of the 1155 token contract.
@external
func appoint_new_token_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}( _new_owner : felt):
    alloc_locals
    only_authorized_minter()

    let (local element_token) = elements_token_address.read()
    IERC1155.set_owner(element_token, _new_owner)

    return ()
end

@external
func set_authorized_minter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}( minter_middleware : felt):
    only_authorized_minter()
    authorized_minter.write(minter_middleware)
    return ()
end


@view
func get_total_minted{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token_id : felt
    ) -> ( total : felt ):
    let (total) = total_minted.read( token_id )
    return (total=total)
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