%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address, get_block_number
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math_cmp import (is_le_felt)
from starkware.cairo.common.math import (unsigned_div_rem, assert_lt)

from contracts.l2.minigame.utils.interfaces import IModuleController, I02_TowerStorage
from contracts.l2.tokens.IERC1155 import IERC1155
from contracts.l2.game_utils.game_structs import ShieldGameRole

############## Storage ################
@storage_var
func controller_address() -> (address : felt):
end

@storage_var
func elements_token_address() -> (address : felt):
end

@storage_var
func blocks_per_minute() -> ( bpm : felt):
end

@storage_var
func hours_per_game() -> ( hpg : felt):
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
        address_of_elements_token : felt,
        _blocks_per_min : felt,
        _hours_per_game : felt
    ):
    controller_address.write(address_of_controller) 
    elements_token_address.write(address_of_elements_token)
    blocks_per_minute.write(_blocks_per_min)
    hours_per_game.write(_hours_per_game)
    
    return ()
end

@external
func create_game{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
    ):
    alloc_locals

    let (local controller) = controller_address.read()

    # TODO: Restrict to only_owner

    let (local tower_defence_storage) = IModuleController.get_module_address(
        controller, 2)
    let (local latest_index) = I02_TowerStorage.get_latest_game_index(tower_defence_storage)
    tempvar current_index = latest_index + 1

    # Set initial wall health to 10000
    I02_TowerStorage.set_main_health(tower_defence_storage, current_index, 10000)

    # Save the game start marker
    let (block_number) = get_block_number()
    I02_TowerStorage.set_game_start(tower_defence_storage, current_index, block_number)

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

@external
func attack_tower{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_idx : felt,
        tokens_id : felt,
        amount : felt
    ):
    alloc_locals
    let (local caller) = get_caller_address()
    let (local controller) = controller_address.read()
    let (local element_token) = elements_token_address.read()
    let (local tower_defence_storage) = IModuleController.get_module_address(controller, 2)
    let (local health) = I02_TowerStorage.get_main_health(tower_defence_storage, game_idx) 

    let (_, local odd_id) = unsigned_div_rem(tokens_id, 2)
    if odd_id == 1:
        [ap] = tokens_id + 1;ap++
    else:
        [ap] = tokens_id - 1;ap++
    end    
    tempvar target_element = [ap - 1]
    let (local value) = I02_TowerStorage.get_shield_value(tower_defence_storage, game_idx, target_element) 
    # Damage shield and/or destroy
    let ( local shield_remains) = is_le_felt(amount, value)
    if shield_remains == 1:
        tempvar newValue = value - amount
        I02_TowerStorage.set_shield_value(tower_defence_storage, game_idx, target_element, newValue)
    else:
        I02_TowerStorage.set_shield_value(tower_defence_storage, game_idx, target_element, 0)
        tempvar damage_remaining = amount - value
        let (local health_remains) = is_le_felt(damage_remaining, health-1)  
        if health_remains == 1:
            tempvar new_health = health - damage_remaining
            I02_TowerStorage.set_main_health(tower_defence_storage, game_idx, new_health)
        else:
            I02_TowerStorage.set_main_health(tower_defence_storage, game_idx, 0)
        end
    end

    let (local total_alloc) = I02_TowerStorage.get_total_reward_alloc(tower_defence_storage, game_idx, ShieldGameRole.Attacker)
    let (local user_alloc) = I02_TowerStorage.get_user_reward_alloc(tower_defence_storage, game_idx, caller, ShieldGameRole.Attacker)
    let (local token_pool) = I02_TowerStorage.get_token_reward_pool(tower_defence_storage, game_idx, tokens_id)

    I02_TowerStorage.set_total_reward_alloc(tower_defence_storage, game_idx, ShieldGameRole.Attacker, total_alloc + amount)
    I02_TowerStorage.set_user_reward_alloc(tower_defence_storage, game_idx, caller, ShieldGameRole.Attacker, user_alloc + amount)
    I02_TowerStorage.set_token_reward_pool(tower_defence_storage, game_idx, tokens_id, token_pool + amount)


    let (local contract_address) = get_contract_address()

    IERC1155.safe_transfer_from(
        element_token,
        caller,
        contract_address,
        tokens_id, 
        amount)

    return()
end

@external
func increase_shield{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_idx : felt,
        tokens_id : felt,
        amount : felt
    ):
    alloc_locals
    let (local caller) = get_caller_address()
    let (local controller) = controller_address.read()
    let (local element_token) = elements_token_address.read()
    let (local tower_defence_storage) = IModuleController.get_module_address(controller, 2)
    let (local value) = I02_TowerStorage.get_shield_value(tower_defence_storage, game_idx, tokens_id) 

    # Increase shield
    tempvar newValue = value + amount
    I02_TowerStorage.set_shield_value(tower_defence_storage, game_idx, tokens_id, newValue)

    let (local total_alloc) = I02_TowerStorage.get_total_reward_alloc(tower_defence_storage, game_idx, ShieldGameRole.Shielder)
    let (local user_alloc) = I02_TowerStorage.get_user_reward_alloc(tower_defence_storage, game_idx, caller, ShieldGameRole.Shielder)
    let (local token_pool) = I02_TowerStorage.get_token_reward_pool(tower_defence_storage, game_idx, tokens_id)


    I02_TowerStorage.set_total_reward_alloc(tower_defence_storage, game_idx, ShieldGameRole.Shielder, total_alloc + amount)
    I02_TowerStorage.set_user_reward_alloc(tower_defence_storage, game_idx, caller, ShieldGameRole.Shielder, user_alloc + amount)
    I02_TowerStorage.set_token_reward_pool(tower_defence_storage, game_idx, tokens_id, token_pool + amount)


    let (local contract_address) = get_contract_address()

    IERC1155.safe_transfer_from( 
        element_token,
        caller,
        contract_address,
        tokens_id, 
        amount)
    
    return ()
end

@external
func claim_rewards{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_idx : felt
    ):
    alloc_locals
    let (local caller) = get_caller_address()
    let (local controller) = controller_address.read()
    let (local tower_defence_storage) = IModuleController.get_module_address(controller, 2)
    let (local health) = I02_TowerStorage.get_main_health(tower_defence_storage, game_idx) 
    let (local side_won) = is_le_felt(health, 0) # 0 = Shielders, 1 = Attackers 

    claim_token_reward(
        game_idx,
        caller,
        side_won,
        2,
    )

    return ()
end

func claim_token_reward{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        game_idx : felt,
        user : felt, 
        side : felt, # from ShieldGameRole
        tokens_idx : felt
    ):
    alloc_locals
    if tokens_idx == 0:
        return ()
    end
    let (local contract_address) = get_contract_address()
    let (local controller) = controller_address.read()
    let (local element_token) = elements_token_address.read()
    let (local tower_defence_storage) = IModuleController.get_module_address(controller, 2)

    let (local total_alloc) = I02_TowerStorage.get_total_reward_alloc(tower_defence_storage, game_idx, side) 
    let (local user_alloc) = I02_TowerStorage.get_user_reward_alloc(tower_defence_storage, game_idx, user, side) 
    let (local token_pool) = I02_TowerStorage.get_token_reward_pool(tower_defence_storage, game_idx, tokens_idx)

    let (local alloc_ratio, _) = unsigned_div_rem(total_alloc, user_alloc)
    let (local user_token_reward, _) = unsigned_div_rem(token_pool, alloc_ratio)  

    IERC1155.safe_transfer_from( 
        element_token,
        contract_address,
        user,
        tokens_idx, 
        user_token_reward)

    claim_token_reward(
        game_idx,
        user, 
        side,
        tokens_idx - 1
    )
    return ()
end

# Calculate the multiplier based on block number
# to 2 decimals of precision
@external
func calculate_time_multiplier{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_started_at : felt,
        _current_block_num : felt
    ) -> ( basis_points ):
    alloc_locals

    # Calculate hours passed.     
    let diff = _current_block_num - game_started_at
    # Ex. 15 sec blocktimes = 4 bpm
    let (local l2BlocksPerMinute) = blocks_per_minute.read()
    let (local minutes,_) = unsigned_div_rem(diff,l2BlocksPerMinute)
    let (local hours,_) = unsigned_div_rem(minutes,60)

    # Offset hours by -1 so that the effect starts at the first hour = 0
    tempvar offset_hours = hours + 1
    
    let (local safe_mul) = pow(base=10,exp=4)

    # TODO: Check this for overflow
    # restricting denominator (hours_per_game) should work also   
    let _numerator = offset_hours * safe_mul

    let (local hpg) = hours_per_game.read()
    let (added_effect,_) = unsigned_div_rem(_numerator, hpg)

    # Halve the effect to cap max effect at 50%
    let (effect_halved,_) = unsigned_div_rem(added_effect, 2)

    # TODO: Enforce maximum cap 
    return (basis_points=effect_halved)

end

# Exponential math
func pow(base : felt, exp : felt) -> (res):
    if exp == 0:
        return (res=1)
    end
    let (res) = pow(base=base, exp=exp - 1)
    return (res=res * base)
end