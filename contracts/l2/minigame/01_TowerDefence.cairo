%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.l2.minigame.utils.interfaces import IModuleController, I02_TowerStorage

############## Storage ################
@storage_var
func controller_address() -> (address : felt):
end

# ############ Structs ################
# see game_utils/game_structs.cairo

# ############ Constants ##############
const ACTION_TYPE_MOVE = 0
const ACTION_TYPE_ATTACK = 1

# ############ Constructor ##############
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
address_of_controller : felt):
    controller_address.write(address_of_controller) 
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

    I02_TowerStorage.set_latest_game_index(tower_defence_storage, latest_index + 1)

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

func check_end_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(game_idx : felt):
    alloc_locals

    let (local controller) = controller_address.read()
    
    # Get tower_count
    let (local tower_defence_storage) = IModuleController.get_module_address(controller, 2)
    let (local tower_count) = I02_TowerStorage.get_tower_count(
        contract_address=tower_defence_storage, game_idx=game_idx)

    # Iterate through towers
    # TODO: Modify to save a variable or return to execute logic
    towers_loop( game_idx=game_idx, tower_index=tower_count )

    # TODO: Logic to determine winner (defender,attacker)

    # TODO: Store the winner
    return ()
end

# Loop through all tower indexes
func towers_loop{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(
        game_idx : felt,
        tower_index : felt
    ):

    if tower_index == 0:
        return()
    end

    alloc_locals
    # Get the tower attributes at current tower index
    let (local controller) = controller_address.read()
    let (local tower_defence_storage) = IModuleController.get_module_address(controller, 2)
    let (local tower_attrs_packed) = I02_TowerStorage.get_tower_attributes(
        contract_address=tower_defence_storage, game_idx=game_idx, tower_idx=tower_index)

    # TODO: Unpack tower attributes

    # Recursively loop through the towers
    towers_loop( game_idx=game_idx, tower_index = tower_index - 1)
    return ()
end