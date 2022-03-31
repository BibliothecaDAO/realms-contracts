import pytest
import asyncio
import enum
import logging

from starkware.starknet.business_logic.state import BlockInfo
from starkware.starkware_utils.error_handling import StarkException

LOGGER = logging.getLogger(__name__)

TOKEN_BASE_FACTOR = 10
LIGHT_TOKEN_ID_OFFSET = 1
DARK_TOKEN_ID_OFFSET = 2

SHIELD_ROLE = 0
ATTACK_ROLE = 1

# Boost units are in basis points, so every value needs to be multiplied
BOOST_UNIT_MULTIPLIER = 100

INITIAL_TOWER_HEALTH = 1000 * BOOST_UNIT_MULTIPLIER

class GameStatus(enum.Enum):
    Active = 0
    Expired = 1

BLOCKS_PER_MINUTE = 4 # 15sec
HOURS_PER_GAME = 36

@pytest.fixture(scope='module')
async def controller_factory(ctx_factory_desiege):
    ctx = ctx_factory_desiege()

    admin_account = ctx.admin

    # The Controller is the only unchangeable contract.
    # First deploy Arbiter.
    # Then send the Arbiter address during Controller deployment.
    # Then save the controller address in the Arbiter.
    # Then deploy Controller address during module deployments.
    arbiter = await ctx.starknet.deploy(
        source="contracts/desiege/Arbiter.cairo",
        constructor_calldata=[admin_account.contract_address])
    ctx.arbiter = arbiter
    
    controller = await ctx.starknet.deploy(
        source="contracts/desiege/ModuleController.cairo",
        constructor_calldata=[arbiter.contract_address])
    ctx.controller = controller
    
    await ctx.execute(
        "admin",
        ctx.arbiter.contract_address,
        "set_address_of_controller",
        [controller.contract_address]
    )

    elements_token = await ctx.starknet.deploy(
        "contracts/token/ERC1155/ERC1155_Mintable_Ownable.cairo",
        constructor_calldata=[
            admin_account.contract_address
        ]
    )
    ctx.elements_token = elements_token

    # Tests usually use game 1
    game_idx = 1 
    light_token_id = game_idx * TOKEN_BASE_FACTOR + LIGHT_TOKEN_ID_OFFSET
    dark_token_id = game_idx * TOKEN_BASE_FACTOR + DARK_TOKEN_ID_OFFSET
    await ctx.execute(
        "admin",
        elements_token.contract_address,
        "mintBatch",
        [
            admin_account.contract_address,
            2,
            light_token_id, dark_token_id,
            2,
            5000 * BOOST_UNIT_MULTIPLIER, 5000 * BOOST_UNIT_MULTIPLIER, # Amounts
        ]
    )

    return ctx

# These contracts needs to be fresh for each test
# to keep tests simple and understandable
@pytest.fixture()
async def game_factory(controller_factory):
    ctx = controller_factory

    tower_defence = await ctx.starknet.deploy(
        source="contracts/desiege/01_TowerDefence.cairo",
        constructor_calldata=[
            ctx.controller.contract_address,
            ctx.elements_token.contract_address,
            BLOCKS_PER_MINUTE,
            HOURS_PER_GAME,
            ctx.admin.contract_address
        ]
    )
    ctx.tower_defence = tower_defence


    tower_defence_storage = await ctx.starknet.deploy(
        source="contracts/desiege/02_TowerDefenceStorage.cairo",
        constructor_calldata=[ctx.controller.contract_address]
    )
    ctx.tower_defence_storage = tower_defence_storage

    await ctx.execute(
        "admin",
        ctx.arbiter.contract_address,
        "batch_set_controller_addresses",
        [
            ctx.tower_defence.contract_address,
            tower_defence_storage.contract_address
        ]
    )
    return ctx

@pytest.mark.asyncio
async def test_game_creation(game_factory):
    
    starknet = game_factory.starknet
    tower_defence = game_factory.tower_defence
    tower_defence_storage = game_factory.tower_defence_storage

    # Set mock value for get_block_number and get_block_timestamp
    expected_block_number = 69420

    starknet.state.state.block_info = BlockInfo(expected_block_number, 2343243294)

    exec_info = await game_factory.execute(
        "admin",
        tower_defence.contract_address,
        "create_game",
        [ INITIAL_TOWER_HEALTH ]
    )

    expected_game_index = 1
    event = exec_info.raw_events[0]
    assert event.data == [expected_game_index, INITIAL_TOWER_HEALTH]
    
    execution_info = await tower_defence_storage.get_latest_game_index().call()
    assert execution_info.result == (expected_game_index,)

    exec2 = await tower_defence_storage.get_game_start(expected_game_index).call()
    assert exec2.result == (expected_block_number,)


@pytest.mark.asyncio
async def test_time_multiplier(game_factory):
    tower_defence = game_factory.tower_defence

    blocks_per_hour = BLOCKS_PER_MINUTE * 60

    expected_basis_points = [
        138, # hour 1
        277, # hour 2
        # ...
        5000 # hour 36
    ]

    execution_info = await tower_defence.calculate_time_multiplier(
        0,
        blocks_per_hour * 0 # First hour
    ).call()
    assert execution_info.result.basis_points == expected_basis_points[0]

    execution_info = await tower_defence.calculate_time_multiplier(
        0,
        (blocks_per_hour * 1) + 1 # second hour
    ).call()
    assert execution_info.result.basis_points == expected_basis_points[1]

    execution_info = await tower_defence.calculate_time_multiplier(
        0,
        (blocks_per_hour * (HOURS_PER_GAME - 1)) + 1 # last hour
    ).call()
    assert execution_info.result.basis_points == expected_basis_points[2]

    # TODO: Implement this case
    # execution_info = await tower_defence.calculate_time_multiplier(
    #     0,
    #     (blocks_per_hour * (HOURS_PER_GAME + 1)) + 1 # over the last possible game limit
    # ).call()
    # assert execution_info.result.basis_points == 5000

@pytest.mark.asyncio
async def test_game_state_expiry(game_factory):

    starknet = game_factory.starknet
    tower_defence = game_factory.tower_defence
    elements_token = game_factory.elements_token
    

    # Set mock value for get_block_number
    mock_block_num = 69421

    starknet.state.state.block_info = BlockInfo(mock_block_num, 2343243296)

    small_health = 500
    game_idx = 1
    dark_token_id = game_idx * TOKEN_BASE_FACTOR + DARK_TOKEN_ID_OFFSET
    await game_factory.execute(
        "admin",
        tower_defence.contract_address,
        "create_game",
        [ small_health ]
    )

    await game_factory.execute(
        "admin",
        elements_token.contract_address,
        "safeBatchTransferFrom",
        [
            game_factory.admin.contract_address,
            game_factory.player1.contract_address,
            1,
            dark_token_id, # Token IDs
            1,
            1000 * BOOST_UNIT_MULTIPLIER
        ]
    )

    await game_factory.execute(
        "player1",
        elements_token.contract_address,
        "setApprovalForAll",
        [
            tower_defence.contract_address,
            1
        ]
    )
        
    exec_res = await tower_defence.get_game_state(game_idx).call()
    assert exec_res.result.game_state_enum == GameStatus.Active.value

    # Bring tower health to 0
    await game_factory.execute(
        "player1",
        tower_defence.contract_address,
        "attack_tower",
        [
            game_idx,
            dark_token_id,
            small_health
        ]
    )

    exec_res = await tower_defence.get_game_state(game_idx).call()
    assert exec_res.result.game_state_enum == GameStatus.Expired.value

    after_max_hours = mock_block_num + ((BLOCKS_PER_MINUTE * 60) * HOURS_PER_GAME) + 1
    starknet.state.state.block_info = BlockInfo(after_max_hours, 123456789)

    # Note: This assertion also works but is meaningless because
    # game status is already expired. TODO: Create separate test
    exec_res = await tower_defence.get_game_state(game_idx).call()
    assert exec_res.result.game_state_enum == GameStatus.Expired.value
        
# Convenience to calculate boosted amount
def calc_amount_plus_boost(base_amount, bips):
    return (base_amount * BOOST_UNIT_MULTIPLIER) + ((base_amount * bips) // 100)

@pytest.mark.asyncio
async def test_shield_and_attack_tower(game_factory):
    starknet = game_factory.starknet
    tower_defence = game_factory.tower_defence
    tower_defence_storage = game_factory.tower_defence_storage
    elements_token = game_factory.elements_token
    
    # Account for time boost
    # For simplicity the following assertions will assume
    # game played in the first hour, which has a 138 basis point boost
    boost_bips = 138

    tower_start_value = INITIAL_TOWER_HEALTH

    game_idx = 1
    # Deterministic token IDs
    light_token_id = game_idx * TOKEN_BASE_FACTOR + LIGHT_TOKEN_ID_OFFSET
    dark_token_id = game_idx * TOKEN_BASE_FACTOR + DARK_TOKEN_ID_OFFSET


    mock_block_num = 1
    starknet.state.state.block_info = BlockInfo(mock_block_num, 123456789)

    await game_factory.execute(
        "admin",
        tower_defence.contract_address,
        "create_game",
        [ INITIAL_TOWER_HEALTH ]
    )

    await game_factory.execute(
        "admin",
        elements_token.contract_address,
        "safeBatchTransferFrom",
        [
            game_factory.admin.contract_address,
            game_factory.player1.contract_address,
            2,
            light_token_id, dark_token_id,
            2,
            1000 * BOOST_UNIT_MULTIPLIER,
            1000 * BOOST_UNIT_MULTIPLIER
        ]
    )

    await game_factory.execute(
        "admin",
        elements_token.contract_address,
        "safeBatchTransferFrom",
        [
            game_factory.admin.contract_address,
            game_factory.player2.contract_address,
            2,
            light_token_id, dark_token_id,
            2,
            1000 * BOOST_UNIT_MULTIPLIER,
            1000 * BOOST_UNIT_MULTIPLIER
        ]
    )

    await game_factory.execute(
        "admin",
        elements_token.contract_address,
        "safeBatchTransferFrom",
        [
            game_factory.admin.contract_address,
            game_factory.player3.contract_address,
            2,
            light_token_id, dark_token_id,
            2,
            1000 * BOOST_UNIT_MULTIPLIER,
            1000 * BOOST_UNIT_MULTIPLIER
        ]
    )

    await game_factory.execute(
        "player1",
        elements_token.contract_address,
        "setApprovalForAll",
        [
            tower_defence.contract_address,
            1
        ]
    )

    await game_factory.execute(
        "player2",
        elements_token.contract_address,
        "setApprovalForAll",
        [
            tower_defence.contract_address,
            1
        ]
    )

    await game_factory.execute(
        "player3",
        elements_token.contract_address,
        "setApprovalForAll",
        [
            tower_defence.contract_address,
            1
        ]
    )
  
    # Player 1 Increases shield by 100 LIGHT
    mock_block_num = mock_block_num + 24
    starknet.state.state.block_info = BlockInfo(mock_block_num, 123456791)

    # Test token restrictions
    # Cannot use wrong game index - token ID mismatch
    with pytest.raises(StarkException):
        await game_factory.execute(
            "player1",
            tower_defence.contract_address,
            "increase_shield",
            [
                2930, # Wrong game index
                light_token_id,
                100 * BOOST_UNIT_MULTIPLIER
            ]
        )

    
    await game_factory.execute(
        "player1",
        tower_defence.contract_address,
        "increase_shield",
        [
            game_idx,
            light_token_id,
            100 * BOOST_UNIT_MULTIPLIER
        ]
    )

    player_one_account = game_factory.player1
    player_two_account = game_factory.player2
    player_three_account = game_factory.player3

    execution_info = await elements_token.balanceOf(player_one_account.contract_address, light_token_id).call()
    assert execution_info.result.balance == 900 * BOOST_UNIT_MULTIPLIER

    execution_info = await tower_defence_storage.get_shield_value(game_idx,light_token_id).call()
    assert execution_info.result.value == calc_amount_plus_boost(100, boost_bips)

    execution_info = await tower_defence_storage.get_user_reward_alloc(game_idx,player_one_account.contract_address,0).call()
    assert execution_info.result.value == 100 * BOOST_UNIT_MULTIPLIER

    execution_info = await tower_defence_storage.get_total_reward_alloc(game_idx,SHIELD_ROLE).call()
    assert execution_info.result.value == 100 * BOOST_UNIT_MULTIPLIER

    execution_info = await elements_token.balanceOf(tower_defence.contract_address,light_token_id).call()
    assert execution_info.result.balance == 100 * BOOST_UNIT_MULTIPLIER

    # Player 2 Attacks with 50 DARK
    await game_factory.execute(
        "player2",
        tower_defence.contract_address,
        "attack_tower",
        [
            game_idx,
            dark_token_id,
            50 * BOOST_UNIT_MULTIPLIER
        ]
    )
    execution_info = await elements_token.balanceOf(player_two_account.contract_address,dark_token_id).call()
    assert execution_info.result.balance == 950 * BOOST_UNIT_MULTIPLIER

    execution_info = await tower_defence_storage.get_main_health(game_idx).call()
    assert execution_info.result.health == tower_start_value

    execution_info = await tower_defence_storage.get_shield_value(game_idx,light_token_id).call()
    shield_val = calc_amount_plus_boost(100, boost_bips) - calc_amount_plus_boost(50, boost_bips)
    assert execution_info.result.value == shield_val

    execution_info = await tower_defence_storage.get_user_reward_alloc(game_idx,player_two_account.contract_address,ATTACK_ROLE).call()
    assert execution_info.result.value == 50 * BOOST_UNIT_MULTIPLIER

    execution_info = await elements_token.balanceOf(tower_defence.contract_address,dark_token_id).call()
    assert execution_info.result.balance == 50 * BOOST_UNIT_MULTIPLIER

    # Player 3 Increases shield by 400 LIGHT

    await game_factory.execute(
        "player3",
        tower_defence.contract_address,
        "increase_shield",
        [
            game_idx,
            light_token_id,
            400 * BOOST_UNIT_MULTIPLIER
        ]
    )
    execution_info = await elements_token.balanceOf(player_three_account.contract_address, light_token_id).call()
    assert execution_info.result.balance == 600 * BOOST_UNIT_MULTIPLIER

    execution_info = await tower_defence_storage.get_shield_value(game_idx,light_token_id).call()
    assert execution_info.result.value == calc_amount_plus_boost(450, boost_bips)

    execution_info = await tower_defence_storage.get_user_reward_alloc(game_idx,player_three_account.contract_address,SHIELD_ROLE).call()
    assert execution_info.result.value == 400 * BOOST_UNIT_MULTIPLIER

    execution_info = await tower_defence_storage.get_total_reward_alloc(game_idx,SHIELD_ROLE).call()
    assert execution_info.result.value == 500 * BOOST_UNIT_MULTIPLIER

    execution_info = await elements_token.balanceOf(tower_defence.contract_address,light_token_id).call()
    assert execution_info.result.balance == 500 * BOOST_UNIT_MULTIPLIER

    # Must claim rewards after game has expired
    after_max_hours = mock_block_num + ((BLOCKS_PER_MINUTE * 60) * HOURS_PER_GAME) + 1
    starknet.state.state.block_info = BlockInfo(after_max_hours, 123456789)

    # TODO: Test reward claiming

@pytest.mark.asyncio
async def test_get_game_context_variables(game_factory):

    
    starknet = game_factory.starknet
    tower_defence = game_factory.tower_defence
    
    start_block_num = 1
    starknet.state.state.block_info = BlockInfo(start_block_num, 123456789)

    await game_factory.execute(
        "admin",
        tower_defence.contract_address,
        "create_game",
        [ INITIAL_TOWER_HEALTH ]
    )

    curr_mock_block_num = 2
    starknet.state.state.block_info = BlockInfo(curr_mock_block_num, 123456789)

    exec_info = await tower_defence.get_game_context_variables().call()

    assert exec_info.result.game_idx == 1 # Game index starts at 1
    assert exec_info.result.bpm == BLOCKS_PER_MINUTE
    assert exec_info.result.hpg == HOURS_PER_GAME
    assert exec_info.result.curr_block == curr_mock_block_num
    assert exec_info.result.game_start == start_block_num
    assert exec_info.result.main_health == INITIAL_TOWER_HEALTH
    assert exec_info.result.curr_boost == 138 # The initial basis points at hour 1

@pytest.mark.asyncio
async def test_game_start_restrictions(game_factory):
    starknet = game_factory.starknet
    tower_defence = game_factory.tower_defence
    
    start_block_num = 1
    starknet.state.state.block_info = BlockInfo(start_block_num, 123456789)

    # Only the admin can start game, not player 1
    with pytest.raises(StarkException):
        await game_factory.execute(
            "player1",
            tower_defence.contract_address,
            "create_game",
            [ INITIAL_TOWER_HEALTH ]
        )