%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from contracts.desiege.utils.interfaces import IModuleController

# ############ TowerDefence Storage ################
# Contract maintains the storage variables

@storage_var
func controller_address() -> (address : felt):
end

# The game index increases each game
# Widely used to scope other variables by game index
@storage_var
func latest_game_index() -> (game_idx : felt):
end

# The marker to indicate when a game started
@storage_var
func game_start(game_idx : felt) -> (started_at : felt):
end

# Stores the wall health for a given game index
# Dicreases when attacks get through the shield.
@storage_var
func main_health(game_idx : felt) -> (health : felt):
end

# Stores the shield value for a given game index
# Increases through replenishment, dicreases through attacks.
@storage_var
func shield_value(game_idx : felt, token_id : felt) -> (value : felt):
end

# Tracks total tokens accumulated for a game idx
# Increases everytime any user contributes elements
@storage_var
func token_reward_pool(game_idx : felt, token_id : felt) -> (value : felt):
end

# Tracks total reward allocations
# Increases everytime any user contributes to a side (0:shielders,1:attackers)
@storage_var
func total_reward_alloc(game_idx : felt, side : felt) -> (value : felt):
end

# Tracks user reward allocations
# Increases based on the elements contributed to a battle from a single user
@storage_var
func user_reward_alloc(game_idx : felt, user : felt, side : felt) -> (value : felt):
end

# Attributes of a tower for a given tower index
# Multiple attributes are packed into a single felt
@storage_var
func tower_attributes(game_idx : felt, tower_idx : felt) -> (attrs : felt):
end

# Stores the number of towers for a given game index
# You can loop recursively through all of the towers using the count
@storage_var
func tower_count(game_idx : felt) -> (count : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt
):
    controller_address.write(address_of_controller)
    return ()
end

@view
func get_latest_game_index{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    game_idx : felt
):
    let (game_idx) = latest_game_index.read()
    return (game_idx)
end

@external
func set_latest_game_index{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt
):
    only_approved()

    latest_game_index.write(game_idx)
    return ()
end

@view
func get_game_start{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt
) -> (started_at : felt):
    let (param) = game_start.read(game_idx)
    return (param)
end

@external
func set_game_start{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, started_at : felt
):
    only_approved()

    game_start.write(game_idx, started_at)
    return ()
end

@view
func get_main_health{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt
) -> (health : felt):
    let (health) = main_health.read(game_idx)
    return (health)
end

@external
func set_main_health{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, health : felt
):
    only_approved()

    main_health.write(game_idx, health)
    return ()
end

@view
func get_shield_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, token_id : felt
) -> (value : felt):
    let (value) = shield_value.read(game_idx, token_id)
    return (value)
end

@external
func set_shield_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, token_id : felt, value : felt
):
    only_approved()

    shield_value.write(game_idx, token_id, value)
    return ()
end

@view
func get_token_reward_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, token_id : felt
) -> (value : felt):
    let (value) = token_reward_pool.read(game_idx, token_id)
    return (value)
end

@external
func set_token_reward_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, token_id : felt, value : felt
):
    only_approved()

    token_reward_pool.write(game_idx, token_id, value)
    return ()
end

@view
func get_total_reward_alloc{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, side : felt
) -> (value : felt):
    let (value) = total_reward_alloc.read(game_idx, side)
    return (value)
end

@external
func set_total_reward_alloc{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, side : felt, value : felt
):
    only_approved()

    total_reward_alloc.write(game_idx, side, value)
    return ()
end

@view
func get_user_reward_alloc{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, user : felt, side : felt
) -> (value : felt):
    let (value) = user_reward_alloc.read(game_idx, user, side)
    return (value)
end

@external
func set_user_reward_alloc{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, user : felt, side : felt, value : felt
):
    only_approved()

    user_reward_alloc.write(game_idx, user, side, value)
    return ()
end

@view
func get_tower_attributes{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, tower_idx : felt
) -> (attrs_packed : felt):
    let (attrs_packed) = tower_attributes.read(game_idx, tower_idx)
    return (attrs_packed)
end

@external
func set_tower_attributes{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, tower_idx : felt, attrs_packed : felt
):
    only_approved()

    tower_attributes.write(game_idx, tower_idx, attrs_packed)
    return ()
end

@view
func get_tower_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt
) -> (count : felt):
    let (count) = tower_count.read(game_idx)
    return (count)
end

@external
func set_tower_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, count : felt
):
    only_approved()

    tower_count.write(game_idx, count)
    return ()
end

# Checks write-permission of the calling contract.
func only_approved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    # Get the address of the module trying to write to this contract.
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()
    # Pass this address on to the ModuleController.
    # "Does this address have write-authority here?"
    # Will revert the transaction if not.
    IModuleController.has_write_access(
        contract_address=controller, address_attempting_to_write=caller
    )
    return ()
end
