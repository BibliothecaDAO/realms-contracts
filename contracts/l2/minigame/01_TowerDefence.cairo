%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math_cmp import (is_le_felt)

from contracts.l2.minigame.utils.interfaces import IModuleController, I02_TowerStorage
from contracts.l2.tokens.IERC20 import IERC20

############## Storage ################
@storage_var
func controller_address() -> (address : felt):
end

@storage_var
func attack_token_address() -> (address : felt):
end

# ############ Structs ################
# see game_utils/game_structs.cairo

# ############ Constants ##############
const ACTION_TYPE_MOVE = 0
const ACTION_TYPE_ATTACK = 1

# ############ Constructor ##############
@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }(
        address_of_controller : felt,
        address_of_attack_token : felt
    ):
    controller_address.write(address_of_controller) 
    attack_token_address.write(address_of_attack_token)
    
    return ()
end

@external
func create_game{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        expiry_timestamp : felt
    ):
    alloc_locals

    let (local controller) = controller_address.read()

    # TODO: Restrict to only_owner

    let (local tower_defence_storage) = IModuleController.get_module_address(
        controller, 2)
    let (local latest_index) = I02_TowerStorage.get_latest_game_index(tower_defence_storage)
    tempvar current_index = latest_index + 1

    # Set initial wall health to 100
    I02_TowerStorage.set_wall_health(tower_defence_storage, current_index, 100)

    # Update index
    I02_TowerStorage.set_latest_game_index(tower_defence_storage, current_index)

    return ()
end


@external
func execute_game_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_idx : felt,
        account_id : felt,
        target_position : felt,
        action_type : felt
    ):

    # TODO
    

    return ()
end

@external
func attack_wall{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_idx : felt,
        amount : felt # Uint256
    ) -> ( success : felt ):
    alloc_locals
    let (local controller) = controller_address.read()
    let (local tower_defence_storage) = IModuleController.get_module_address(
        controller, 2)
    let (local health) = I02_TowerStorage.get_wall_health(tower_defence_storage, game_idx)

    local damage = amount # getDamageFromToken(game_idx, amount) (should be exponential)

    # assert max allowed amount

    let burn_amount = amount # can burn all like spell consumption in most games

    let ( local is_wall_alive ) = is_le_felt(damage, health - 1) 
    if is_wall_alive == 1: 
        tempvar newHealth = health - damage
        I02_TowerStorage.set_wall_health(tower_defence_storage, game_idx, newHealth)
    else:
        # burn_amount -= extra # 
        I02_TowerStorage.set_wall_health(tower_defence_storage, game_idx, 0)

        # reward
    end

    let (local caller) = get_caller_address()
    let (local attack_token) = attack_token_address.read()
    # ERC20 alternative to transferFrom to 0
    # If ERC1155, batchBurn.
    let token_amount = Uint256(burn_amount, 0)
    IERC20.burnFrom(attack_token, caller,  token_amount)
    return (1)
end

