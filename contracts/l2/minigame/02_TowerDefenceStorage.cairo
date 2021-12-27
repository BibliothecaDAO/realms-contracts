%lang starknet
%builtins pedersen range_check
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from contracts.l2.minigame.utils.interfaces import IModuleController

# ############ TowerDefence Storage ################
# Contract maintains the storage variables

@storage_var
func controller_address() -> (address : felt):
end

# The game index increases each game
# Widely used to scope other variables by game index
@storage_var
func latest_game_index( ) -> ( game_idx : felt ):
end

# Stores the wall health for a given game index
# Increases through replenishment, dicreases through attacks. 
@storage_var
func wall_health( game_idx : felt ) -> ( health : felt ):
end

# Attributes of a tower for a given tower index
# Multiple attributes are packed into a single felt
@storage_var
func tower_attributes( game_idx : felt, tower_idx : felt ) -> ( attrs : felt ):
end

# Stores the number of towers for a given game index
# You can loop recursively through all of the towers using the count
@storage_var
func tower_count( game_idx : felt ) -> ( count : felt ):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
address_of_controller : felt):
    controller_address.write(address_of_controller) 
    return ()
end

@external
func get_latest_game_index{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (  game_idx : felt ):
    let (game_idx) = latest_game_index.read()
    return (game_idx)
end

@external
func set_latest_game_index{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(  game_idx : felt ):

    only_approved()

    latest_game_index.write(  game_idx )
    return ()
end

@external
func get_wall_health{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*,range_check_ptr}( game_idx : felt) -> ( health : felt ):
    let (health) = wall_health.read( game_idx )
    return (health) 
end

@external
func set_wall_health{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*,range_check_ptr}( game_idx : felt, health : felt ):
    
    only_approved()

    wall_health.write( game_idx, health)
    return ()
end

@external
func get_tower_attributes{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*,range_check_ptr}( game_idx : felt, tower_idx : felt) -> ( attrs_packed : felt ):
    let (attrs_packed) = tower_attributes.read( game_idx, tower_idx )
    return (attrs_packed) 
end

@external
func set_tower_attributes{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*,range_check_ptr}( game_idx : felt, tower_idx : felt, attrs_packed : felt ):
    
    only_approved()

    tower_attributes.write( game_idx, tower_idx, attrs_packed)
    return ()
end

@external
func get_tower_count{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*,range_check_ptr}( game_idx : felt ) -> ( count : felt ):
    let (count) = tower_count.read( game_idx )
    return (count)
end

@external
func set_tower_count{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*,range_check_ptr}( game_idx : felt, count : felt ):

    only_approved()

    tower_count.write( game_idx, count)
    return ()
end

# Checks write-permission of the calling contract.
func only_approved{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    # Get the address of the module trying to write to this contract.
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()
    # Pass this address on to the ModuleController.
    # "Does this address have write-authority here?"
    # Will revert the transaction if not.
    IModuleController.has_write_access(
        contract_address=controller,
        address_attempting_to_write=caller)
    return ()
end
