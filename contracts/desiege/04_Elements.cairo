%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.access.ownable.library import Ownable

from contracts.desiege.utils.interfaces import (
    IModuleController,
    I02_TowerStorage,
    IDivineEclipseElements,
)
from contracts.desiege.tokens.ERC1155.IERC1155_Mintable_Ownable import IERC1155

const ModuleIdentifier_DivineEclipse = 'divine-eclipse'

# ############# Storage ################
@storage_var
func controller_address() -> (address : felt):
end

@storage_var
func elements_token_address() -> (address : felt):
end

# ############# Events ################

@event
func element_distilled(by : felt, token_id : felt, amount : felt):
end

# ############ Constructor ##############

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt,
    address_of_elements_token : felt,
    address_of_minting_middleware : felt,
):
    controller_address.write(address_of_controller)
    elements_token_address.write(address_of_elements_token)

    # Minting is controlled by an account
    Ownable.initializer(address_of_minting_middleware)

    return ()
end

# ############# External Functions ################

@external
func mint_elements{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, from_l1_address : felt, to : felt, token_id : felt, amount : felt
):
    alloc_locals

    Ownable.assert_only_owner()

    # Ensure user hasn't minted for the next game
    let (local controller) = controller_address.read()

    let (local tower_defence_storage) = IModuleController.get_module_address(controller, 2)
    let (local divine_eclipse_storage) = IModuleController.get_module_address(
        controller, ModuleIdentifier_DivineEclipse
    )
    let (local latest_index) = I02_TowerStorage.get_latest_game_index(tower_defence_storage)

    tempvar next_game_index = latest_index + 1

    # Only allow minting for the next game
    # Minting assets for current game not allowed
    assert game_idx = next_game_index

    # Check if already minted
    let (minted_already) = IDivineEclipseElements.get_has_minted(
        divine_eclipse_storage, from_l1_address, next_game_index
    )

    # TODO: Wrap in with_attr error for better error message
    assert minted_already = 0
    # Prevent minting again for this game
    IDivineEclipseElements.set_has_minted(
        divine_eclipse_storage, from_l1_address, next_game_index, 1
    )

    # Increment total minted
    let (local prev_total) = IDivineEclipseElements.get_total_minted(
        divine_eclipse_storage, token_id
    )
    IDivineEclipseElements.set_total_minted(divine_eclipse_storage, token_id, prev_total + amount)

    let (local element_token) = elements_token_address.read()

    IERC1155.mint(element_token, to, token_id, amount)

    element_distilled.emit(to, token_id, amount)

    return ()
end

@external
func transfer_ownership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    next_owner : felt
):
    alloc_locals
    # Transfer ownership of this contract
    Ownable.transfer_ownership(next_owner)

    # Transfer ownership of the 1155 token contract
    let (local element_token) = elements_token_address.read()

    IERC1155.transferOwnership(element_token, next_owner)

    return ()
end

@view
func get_total_minted{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : felt
) -> (total : felt):
    alloc_locals
    let (local controller) = controller_address.read()

    let (local divine_eclipse_storage) = IModuleController.get_module_address(
        controller, ModuleIdentifier_DivineEclipse
    )
    let (total) = IDivineEclipseElements.get_total_minted(divine_eclipse_storage, token_id)
    return (total=total)
end
