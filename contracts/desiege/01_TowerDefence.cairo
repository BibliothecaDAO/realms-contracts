%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_number,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math_cmp import is_le_felt, is_le
from starkware.cairo.common.math import unsigned_div_rem, assert_lt

from openzeppelin.access.ownable import (
    Ownable_initializer,
    Ownable_only_owner,
    Ownable_transfer_ownership,
    Ownable_get_owner,
)

from contracts.desiege.utils.interfaces import IModuleController, I02_TowerStorage
from contracts.desiege.tokens.ERC1155.IERC1155_Mintable_Ownable import IERC1155
from contracts.game_utils.game_structs import ShieldGameRole

# ############# Storage ################
@storage_var
func controller_address() -> (address : felt):
end

@storage_var
func elements_token_address() -> (address : felt):
end

@storage_var
func blocks_per_minute() -> (bpm : felt):
end

@storage_var
func hours_per_game() -> (hpg : felt):
end

# ############ Events ################

@event
func game_started(game_idx : felt, initial_main_health : felt):
end

@event
func game_action(
    game_idx : felt, token_id : felt, token_offset : felt, amount : felt, action_type : felt
):
end

# ############ Structs ################

# Determined at runtime
struct GameStatus:
    member Active : felt
    member Expired : felt
end

# Game tokens cannot be reused across games
# The base factor is used to deterministically enforce this rule
# Ex. Token ID = 12
# Game Index = 12 / BASE_FACTOR = 1
# Token Offset = 12 % BASE_FACTOR = 2
const TOKEN_BASE_FACTOR = 10

namespace ElementTokenOffset:
    const Light = 1
    const Dark = 2
    # ... what other Elements exist in the Lootverse?
end

namespace ActionType:
    const Attack = 1
    const Shield = 2
    # ... how can actions affect the Lootverse?
end

# ############ Constructor ##############
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _address_of_controller : felt,
    _address_of_elements_token : felt,
    _blocks_per_min : felt,
    _hours_per_game : felt,
    _owner : felt,
):
    controller_address.write(_address_of_controller)
    elements_token_address.write(_address_of_elements_token)
    blocks_per_minute.write(_blocks_per_min)
    hours_per_game.write(_hours_per_game)

    Ownable_initializer(_owner)

    return ()
end

# Convenience function that retrieves relevent
# game state variables in a single call for quick front-end loading
@view
func get_game_context_variables{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (game_idx, bpm, hpg, curr_block, game_start, main_health, curr_boost):
    alloc_locals
    let (controller) = controller_address.read()

    let (tower_defence_storage) = IModuleController.get_module_address(controller, 2)
    let (latest_index) = I02_TowerStorage.get_latest_game_index(tower_defence_storage)

    tempvar game_idx = latest_index

    let (local bpm) = blocks_per_minute.read()
    let (hpg) = hours_per_game.read()
    let (curr_block) = get_block_number()
    let (game_start) = I02_TowerStorage.get_game_start(tower_defence_storage, game_idx)
    let (main_health) = I02_TowerStorage.get_main_health(tower_defence_storage, game_idx)

    let (current_boost) = calculate_time_multiplier(game_start, curr_block)

    return (
        game_idx=game_idx,
        bpm=bpm,
        hpg=hpg,
        curr_block=curr_block,
        game_start=game_start,
        main_health=main_health,
        curr_boost=current_boost,
    )
end

# See tasks/create_game.ts
@external
func create_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _init_main_health : felt
):
    alloc_locals
    Ownable_only_owner()

    let (local controller) = controller_address.read()

    let (local tower_defence_storage) = IModuleController.get_module_address(controller, 2)
    let (local latest_index) = I02_TowerStorage.get_latest_game_index(tower_defence_storage)
    tempvar current_index = latest_index + 1

    # Set main health
    I02_TowerStorage.set_main_health(tower_defence_storage, current_index, _init_main_health)

    # Save the game start marker
    let (block_number) = get_block_number()
    I02_TowerStorage.set_game_start(tower_defence_storage, current_index, block_number)

    # Update index
    I02_TowerStorage.set_latest_game_index(tower_defence_storage, current_index)

    game_started.emit(current_index, _init_main_health)

    return ()
end

@external
func attack_tower{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, tokens_id : felt, _amount : felt
):
    alloc_locals

    # Restrict attack action to dark tokens
    let (local base, local offset) = unsigned_div_rem(tokens_id, TOKEN_BASE_FACTOR)
    assert offset = ElementTokenOffset.Dark
    # Make sure token IDs are allowed for this game
    assert base = game_idx

    let (local caller) = get_caller_address()
    let (local controller) = controller_address.read()
    let (local element_token) = elements_token_address.read()
    let (local tower_defence_storage) = IModuleController.get_module_address(controller, 2)
    let (local health) = I02_TowerStorage.get_main_health(tower_defence_storage, game_idx)
    let (local game_start) = I02_TowerStorage.get_game_start(tower_defence_storage, game_idx)

    let (local game_status) = get_game_state(game_idx)
    assert game_status = GameStatus.Active

    # Finds the associated other token
    let (_, local odd_id) = unsigned_div_rem(tokens_id, 2)
    if odd_id == 1:
        [ap] = tokens_id + 1; ap++
    else:
        [ap] = tokens_id - 1; ap++
    end
    tempvar target_element = [ap - 1]
    let (local value) = I02_TowerStorage.get_shield_value(
        tower_defence_storage, game_idx, target_element
    )

    # Account for boost
    let (local boosted_amount) = calc_amount_plus_boost(game_start, _amount)

    # Damage shield and/or destroy
    let (local shield_remains) = is_le_felt(boosted_amount, value)
    if shield_remains == 1:
        tempvar newValue = value - boosted_amount
        I02_TowerStorage.set_shield_value(tower_defence_storage, game_idx, target_element, newValue)
    else:
        I02_TowerStorage.set_shield_value(tower_defence_storage, game_idx, target_element, 0)
        tempvar damage_remaining = boosted_amount - value
        let (local health_remains) = is_le_felt(damage_remaining, health - 1)
        if health_remains == 1:
            tempvar new_health = health - damage_remaining
            I02_TowerStorage.set_main_health(tower_defence_storage, game_idx, new_health)
        else:
            I02_TowerStorage.set_main_health(tower_defence_storage, game_idx, 0)
        end
    end

    let (local total_alloc) = I02_TowerStorage.get_total_reward_alloc(
        tower_defence_storage, game_idx, ShieldGameRole.Attacker
    )
    let (local user_alloc) = I02_TowerStorage.get_user_reward_alloc(
        tower_defence_storage, game_idx, caller, ShieldGameRole.Attacker
    )
    let (local token_pool) = I02_TowerStorage.get_token_reward_pool(
        tower_defence_storage, game_idx, tokens_id
    )

    # Do not account for boost in alloc calculations
    I02_TowerStorage.set_total_reward_alloc(
        tower_defence_storage, game_idx, ShieldGameRole.Attacker, total_alloc + _amount
    )
    I02_TowerStorage.set_user_reward_alloc(
        tower_defence_storage, game_idx, caller, ShieldGameRole.Attacker, user_alloc + _amount
    )
    I02_TowerStorage.set_token_reward_pool(
        tower_defence_storage, game_idx, tokens_id, token_pool + _amount
    )

    game_action.emit(game_idx, tokens_id, offset, _amount, ActionType.Attack)

    let (local contract_address) = get_contract_address()

    IERC1155.safeTransferFrom(element_token, caller, contract_address, tokens_id, _amount)

    return ()
end

@external
func increase_shield{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt, tokens_id : felt, _amount : felt
):
    alloc_locals

    # Restrict shield action to light tokens
    let (local base, local offset) = unsigned_div_rem(tokens_id, TOKEN_BASE_FACTOR)
    assert offset = ElementTokenOffset.Light
    # Make sure token IDs are allowed for this game
    assert base = game_idx

    let (local caller) = get_caller_address()
    let (local controller) = controller_address.read()
    let (local element_token) = elements_token_address.read()
    let (local tower_defence_storage) = IModuleController.get_module_address(controller, 2)
    let (local value) = I02_TowerStorage.get_shield_value(
        tower_defence_storage, game_idx, tokens_id
    )
    let (local game_start) = I02_TowerStorage.get_game_start(tower_defence_storage, game_idx)

    let (local game_status) = get_game_state(game_idx)
    assert game_status = GameStatus.Active

    # Account for boost
    let (local boosted_amount) = calc_amount_plus_boost(game_start, _amount)

    # Increase shield
    tempvar newValue = value + boosted_amount
    I02_TowerStorage.set_shield_value(tower_defence_storage, game_idx, tokens_id, newValue)

    let (local total_alloc) = I02_TowerStorage.get_total_reward_alloc(
        tower_defence_storage, game_idx, ShieldGameRole.Shielder
    )
    let (local user_alloc) = I02_TowerStorage.get_user_reward_alloc(
        tower_defence_storage, game_idx, caller, ShieldGameRole.Shielder
    )
    let (local token_pool) = I02_TowerStorage.get_token_reward_pool(
        tower_defence_storage, game_idx, tokens_id
    )

    # Do not account for boost in alloc calculations
    I02_TowerStorage.set_total_reward_alloc(
        tower_defence_storage, game_idx, ShieldGameRole.Shielder, total_alloc + _amount
    )
    I02_TowerStorage.set_user_reward_alloc(
        tower_defence_storage, game_idx, caller, ShieldGameRole.Shielder, user_alloc + _amount
    )
    I02_TowerStorage.set_token_reward_pool(
        tower_defence_storage, game_idx, tokens_id, token_pool + _amount
    )

    game_action.emit(game_idx, tokens_id, offset, _amount, ActionType.Shield)

    let (local contract_address) = get_contract_address()

    IERC1155.safeTransferFrom(element_token, caller, contract_address, tokens_id, _amount)

    return ()
end

@external
func claim_rewards{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt
):
    alloc_locals
    let (local caller) = get_caller_address()
    let (local controller) = controller_address.read()
    let (local tower_defence_storage) = IModuleController.get_module_address(controller, 2)
    let (local health) = I02_TowerStorage.get_main_health(tower_defence_storage, game_idx)

    # Ensure claiming can occur only when the game clock has expired
    let (local game_state) = get_game_state(game_idx)
    assert game_state = GameStatus.Expired

    # This is the game winning condition.
    # Light wins if health remains above 0.
    # Dark wins if health equals to 0.
    let (local side_won) = is_le_felt(health, 0)  # 0 = Shielders, 1 = Attackers

    let (local total_alloc) = I02_TowerStorage.get_total_reward_alloc(
        tower_defence_storage, game_idx, side_won
    )
    let (local user_alloc) = I02_TowerStorage.get_user_reward_alloc(
        tower_defence_storage, game_idx, caller, side_won
    )

    # Rewards TBD
    # Calling this function does nothing.
    # This contract can be upgraded.

    return ()
end

# Returns the game state for a game index
# Games are active if the block number falls within
# the game start and hours_per_game boundary
# else the game is considered expired
@view
func get_game_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_idx : felt
) -> (game_state_enum : felt):
    alloc_locals
    let (local controller) = controller_address.read()
    let (local element_token) = elements_token_address.read()
    let (local tower_defence_storage) = IModuleController.get_module_address(controller, 2)
    let (local health) = I02_TowerStorage.get_main_health(tower_defence_storage, game_idx)

    let (health_depleted) = is_le_felt(health, 0)

    if health_depleted == 1:
        return (GameStatus.Expired)
    end

    let (block_num) = get_block_number()

    let (bpm) = blocks_per_minute.read()
    let (hpg) = hours_per_game.read()

    let (local game_started_at) = I02_TowerStorage.get_game_start(tower_defence_storage, game_idx)

    tempvar diff = block_num - game_started_at

    let (local minutes, _) = unsigned_div_rem(diff, bpm)
    let (local hours_passed, _) = unsigned_div_rem(minutes, 60)

    # Subtract 1 from hours per game because we don't want
    # games equal or greater (hours_per_game) to be active
    let (is_within_game_range) = is_le(hours_passed, hpg - 1)

    if is_within_game_range == 1:
        return (GameStatus.Active)
    else:
        return (GameStatus.Expired)
    end
end

# Calculate the multiplier based on block number
# to 2 decimals of precision
@view
func calculate_time_multiplier{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_started_at : felt, _current_block_num : felt
) -> (basis_points):
    alloc_locals

    # Calculate hours passed.
    let diff = _current_block_num - game_started_at
    # Ex. 15 sec blocktimes = 4 bpm
    let (local l2BlocksPerMinute) = blocks_per_minute.read()
    let (local minutes, _) = unsigned_div_rem(diff, l2BlocksPerMinute)
    let (local hours, _) = unsigned_div_rem(minutes, 60)

    # Offset hours by -1 so that the effect starts at the first hour = 0
    tempvar offset_hours = hours + 1

    let (local safe_mul) = pow(base=10, exp=4)

    # TODO: Check this for overflow
    # restricting denominator (hours_per_game) should work also
    let _numerator = offset_hours * safe_mul

    let (local hpg) = hours_per_game.read()
    let (added_effect, _) = unsigned_div_rem(_numerator, hpg)

    # Halve the effect to cap max effect at 50%
    let (effect_halved, _) = unsigned_div_rem(added_effect, 2)

    # TODO: Enforce maximum cap
    return (basis_points=effect_halved)
end

# Calculate action amount plus
# time boost.
@view
func calc_amount_plus_boost{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    game_started_at : felt, amount : felt
) -> (boosted_amount : felt):
    alloc_locals
    let (block_num) = get_block_number()

    let (local basis_points) = calculate_time_multiplier(game_started_at, block_num)
    let (amount_base, _) = unsigned_div_rem(amount, 100)
    let amount_x_boost = amount_base * basis_points
    # Precision is only 2 decimals, so divide by 100
    let (boost, _) = unsigned_div_rem(amount_x_boost, 100)

    return (boosted_amount=amount + boost)
end

@view
func get_current_boost{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    boost : felt
):
    alloc_locals
    let (local controller) = controller_address.read()
    let (local tower_defence_storage) = IModuleController.get_module_address(controller, 2)
    let (local game_idx) = I02_TowerStorage.get_latest_game_index(tower_defence_storage)
    let (local game_start) = I02_TowerStorage.get_game_start(tower_defence_storage, game_idx)

    let (block_num) = get_block_number()
    let (local basis_points) = calculate_time_multiplier(game_start, block_num)
    return (boost=basis_points)
end

# Exponential math
func pow(base : felt, exp : felt) -> (res):
    if exp == 0:
        return (res=1)
    end
    let (res) = pow(base=base, exp=exp - 1)
    return (res=res * base)
end

#
# Ownable Externals
#
@view
func get_owner{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}() -> (
    owner : felt
):
    let (o) = Ownable_get_owner()
    return (owner=o)
end

@external
func transfer_ownership{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
    next_owner : felt
):
    Ownable_transfer_ownership(next_owner)
    return ()
end
