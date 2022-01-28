import pytest
import asyncio
import enum

from starkware.starknet.business_logic.state import BlockInfo
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.definitions.error_codes import StarknetErrorCode

from fixtures.account import account_factory
from utils.string import str_to_felt

NUM_SIGNING_ACCOUNTS = 4

LIGHT_TOKEN_ID = 1
DARK_TOKEN_ID = 2

SHIELD_ROLE = 0
ATTACK_ROLE = 1

# Boost units are in basis points, so every value needs to be multiplied
BOOST_UNIT_MULTIPLIER = 100

class GameStatus(enum.Enum):
    Active = 0
    Expired = 1

BLOCKS_PER_MINUTE = 4 # 15sec
HOURS_PER_GAME = 36

@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope='module')
async def game_factory(account_factory):
    (starknet, accounts, signers) = account_factory
    admin_key = signers[0]
    admin_account = accounts[0]

    # The Controller is the only unchangeable contract.
    # First deploy Arbiter.
    # Then send the Arbiter address during Controller deployment.
    # Then save the controller address in the Arbiter.
    # Then deploy Controller address during module deployments.
    arbiter = await starknet.deploy(
        source="contracts/l2/settling_game/Arbiter.cairo",
        constructor_calldata=[admin_account.contract_address])
    controller = await starknet.deploy(
        source="contracts/l2/settling_game/ModuleController.cairo",
        constructor_calldata=[arbiter.contract_address])
    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='set_address_of_controller',
        calldata=[controller.contract_address])
    print(admin_account)

    elements_token = await starknet.deploy(
        "contracts/l2/tokens/ERC1155.cairo",
        constructor_calldata=[
            admin_account.contract_address,
            1,1,1,1,1 # TokenURI struct
        ]
    )

    await admin_key.send_transaction(
        account=admin_account,
        to=elements_token.contract_address,
        selector_name='mint_batch',
        calldata=[
            admin_account.contract_address,
            2,
            LIGHT_TOKEN_ID, DARK_TOKEN_ID,
            2,
            3000 * BOOST_UNIT_MULTIPLIER, 3000 * BOOST_UNIT_MULTIPLIER, # Amounts
        ])

    
    tower_defence = await starknet.deploy(
        source="contracts/l2/minigame/01_TowerDefence.cairo",
        constructor_calldata=[
            controller.contract_address,
            elements_token.contract_address,
            BLOCKS_PER_MINUTE,
            HOURS_PER_GAME
        ]
    )
    
    tower_defence_storage = await starknet.deploy(
        source="contracts/l2/minigame/02_TowerDefenceStorage.cairo",
        constructor_calldata=[controller.contract_address]
    )

    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='batch_set_controller_addresses',
        calldata=[
            tower_defence.contract_address, tower_defence_storage.contract_address])
    return starknet, accounts, signers, arbiter, controller, elements_token, tower_defence, tower_defence_storage

@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_game_creation(game_factory):

    starknet, accounts, signers, _, _, _, tower_defence, tower_defence_storage = game_factory
    
    admin_key = signers[0]
    admin_account = accounts[0]

    # Set mock value for get_block_number and get_block_timestamp
    expected_block_number = 69420

    starknet.state.state.block_info = BlockInfo(expected_block_number, 2343243294)

    await admin_key.send_transaction(
        account=admin_account,
        to=tower_defence.contract_address,
        selector_name='create_game',
        calldata=[]
    )

    expected_game_index = 1
    execution_info = await tower_defence_storage.get_latest_game_index().call()
    assert execution_info.result == (expected_game_index,)

    exec2 = await tower_defence_storage.get_game_start(expected_game_index).call()
    assert exec2.result == (expected_block_number,)


@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_time_multiplier(game_factory):
    _, _, _, _, _, _, tower_defence, _ = game_factory

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
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_game_state_expiry(game_factory):

    starknet, accounts, signers, _, _, _, tower_defence, _ = game_factory
    
    admin_key = signers[0]
    admin_account = accounts[0]

    # Set mock value for get_block_number
    mock_block_num = 1

    starknet.state.state.block_info = BlockInfo(mock_block_num, 123456789)

    await admin_key.send_transaction(
        account=admin_account,
        to=tower_defence.contract_address,
        selector_name='create_game',
        calldata=[]
    )

    game_idx = 1

    exec_res = await tower_defence.get_game_state(game_idx).call()
    assert exec_res.result.game_state_enum == GameStatus.Active.value

    after_max_hours = ((BLOCKS_PER_MINUTE * 60) * HOURS_PER_GAME) + 1
    starknet.state.state.block_info = BlockInfo(after_max_hours, 123456789)

    exec_res = await tower_defence.get_game_state(game_idx).call()
    assert exec_res.result.game_state_enum == GameStatus.Expired.value

    # Cannot claim rewards when game is expired
    try:
        await admin_key.send_transaction(
            account=admin_account,
            to=tower_defence.contract_address,
            selector_name="claim_rewards",
            calldata=[game_idx]
        )
        assert False
    except StarkException as err:
        _, error = err.args
        assert error['code'] == StarknetErrorCode.TRANSACTION_FAILED

# Convenience to calculate boosted amount
def calc_amount_plus_boost(base_amount, bips):
    return (base_amount * BOOST_UNIT_MULTIPLIER) + ((base_amount * bips) // 100)

@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_shield_and_attack_tower(game_factory):

    starknet, accounts, signers, _, _, elements_token, tower_defence, tower_defence_storage = game_factory
    
    admin_key = signers[0]
    admin_account = accounts[0]

    player_one_key = signers[1]
    player_one_account = accounts[1]

    player_two_key = signers[2]
    player_two_account = accounts[2]

    player_three_key = signers[3]
    player_three_account = accounts[3]

    # Account for time boost
    # For simplicity the following assertions will assume
    # game played in the first hour, which has a 138 basis point boost
    boost_bips = 138

    tower_start_value = 10000


    mock_block_num = 1
    starknet.state.state.block_info = BlockInfo(mock_block_num, 123456789)

    await admin_key.send_transaction(
        account=admin_account,
        to=tower_defence.contract_address,
        selector_name="create_game",
        calldata=[]
    )

    await admin_key.send_transaction(
        account=admin_account,
        to=elements_token.contract_address,
        selector_name='safe_batch_transfer_from',
        calldata=[
            admin_account.contract_address,
            player_one_account.contract_address, 
            2,
            LIGHT_TOKEN_ID, DARK_TOKEN_ID,
            2,
            1000 * BOOST_UNIT_MULTIPLIER,
            1000 * BOOST_UNIT_MULTIPLIER
        ])

    await admin_key.send_transaction(
        account=admin_account,
        to=elements_token.contract_address,
        selector_name='safe_batch_transfer_from',
        calldata=[
            admin_account.contract_address,
            player_two_account.contract_address,            
            2,
            LIGHT_TOKEN_ID, DARK_TOKEN_ID,
            2,
            1000 * BOOST_UNIT_MULTIPLIER,
            1000 * BOOST_UNIT_MULTIPLIER
        ])

    await admin_key.send_transaction(
        account=admin_account,
        to=elements_token.contract_address,
        selector_name='safe_batch_transfer_from',
        calldata=[
            admin_account.contract_address,
            player_three_account.contract_address,            
            2,
            LIGHT_TOKEN_ID, DARK_TOKEN_ID,
            2,
            1000 * BOOST_UNIT_MULTIPLIER,
            1000 * BOOST_UNIT_MULTIPLIER
        ])
  
    await player_one_key.send_transaction(
        account=player_one_account,
        to=elements_token.contract_address,
        selector_name="set_approval_for_all",
        calldata=[
            tower_defence.contract_address,
            1
        ]
    )
    await player_two_key.send_transaction(
        account=player_two_account,
        to=elements_token.contract_address,
        selector_name="set_approval_for_all",
        calldata=[
            tower_defence.contract_address,
            1
        ]
    )
    await player_three_key.send_transaction(
        account=player_three_account,
        to=elements_token.contract_address,
        selector_name="set_approval_for_all",
        calldata=[
            tower_defence.contract_address,
            1
        ]
    )

    # Player 1 Increases shield by 100 LIGHT

    mock_block_num = 2
    starknet.state.state.block_info = BlockInfo(mock_block_num, 123456790)

    game_idx = 1

    await player_one_key.send_transaction(
        account=player_one_account,
        to=tower_defence.contract_address,
        selector_name="increase_shield",
        calldata=[
            game_idx,
            LIGHT_TOKEN_ID,
            100 * BOOST_UNIT_MULTIPLIER
        ]
    )
    execution_info = await elements_token.balance_of(player_one_account.contract_address, LIGHT_TOKEN_ID).call()
    assert execution_info.result.res == 900 * BOOST_UNIT_MULTIPLIER

    execution_info = await tower_defence_storage.get_shield_value(game_idx,LIGHT_TOKEN_ID).call()
    assert execution_info.result.value == calc_amount_plus_boost(100, boost_bips)

    execution_info = await tower_defence_storage.get_user_reward_alloc(game_idx,player_one_account.contract_address,0).call()
    assert execution_info.result.value == 100 * BOOST_UNIT_MULTIPLIER

    execution_info = await tower_defence_storage.get_total_reward_alloc(game_idx,SHIELD_ROLE).call()
    assert execution_info.result.value == 100 * BOOST_UNIT_MULTIPLIER

    execution_info = await elements_token.balance_of(tower_defence.contract_address,LIGHT_TOKEN_ID).call()
    assert execution_info.result.res == 100 * BOOST_UNIT_MULTIPLIER

    # Player 2 Attacks with 50 DARK

    await player_two_key.send_transaction(
        account=player_two_account,
        to=tower_defence.contract_address,
        selector_name="attack_tower",
        calldata=[
            game_idx,
            DARK_TOKEN_ID, 
            50 * BOOST_UNIT_MULTIPLIER
        ]
    )
    execution_info = await elements_token.balance_of(player_two_account.contract_address,DARK_TOKEN_ID).call()
    assert execution_info.result.res == 950 * BOOST_UNIT_MULTIPLIER

    execution_info = await tower_defence_storage.get_main_health(game_idx).call()
    assert execution_info.result.health == tower_start_value

    execution_info = await tower_defence_storage.get_shield_value(game_idx,LIGHT_TOKEN_ID).call()
    shield_val = calc_amount_plus_boost(100, boost_bips) - calc_amount_plus_boost(50, boost_bips)
    assert execution_info.result.value == shield_val

    execution_info = await tower_defence_storage.get_user_reward_alloc(game_idx,player_two_account.contract_address,ATTACK_ROLE).call()
    assert execution_info.result.value == 50 * BOOST_UNIT_MULTIPLIER

    execution_info = await elements_token.balance_of(tower_defence.contract_address,DARK_TOKEN_ID).call()
    assert execution_info.result.res == 50 * BOOST_UNIT_MULTIPLIER

    # Player 3 Increases shield by 400 LIGHT

    await player_three_key.send_transaction(
        account=player_three_account,
        to=tower_defence.contract_address,
        selector_name="increase_shield",
        calldata=[
            game_idx,
            LIGHT_TOKEN_ID,
            400 * BOOST_UNIT_MULTIPLIER
        ]
    )
    execution_info = await elements_token.balance_of(player_three_account.contract_address, LIGHT_TOKEN_ID).call()
    assert execution_info.result.res == 600 * BOOST_UNIT_MULTIPLIER

    execution_info = await tower_defence_storage.get_shield_value(game_idx,LIGHT_TOKEN_ID).call()
    assert execution_info.result.value == calc_amount_plus_boost(450, boost_bips)

    execution_info = await tower_defence_storage.get_user_reward_alloc(game_idx,player_three_account.contract_address,SHIELD_ROLE).call()
    assert execution_info.result.value == 400 * BOOST_UNIT_MULTIPLIER

    execution_info = await tower_defence_storage.get_total_reward_alloc(game_idx,SHIELD_ROLE).call()
    assert execution_info.result.value == 500 * BOOST_UNIT_MULTIPLIER

    execution_info = await elements_token.balance_of(tower_defence.contract_address,LIGHT_TOKEN_ID).call()
    assert execution_info.result.res == 500 * BOOST_UNIT_MULTIPLIER

    # Player 1 claims if tower is alive, should only get 10 DARK
    # Calculation
    # Player 1 plays shield role, which has 500 in total pool
    # Player 1 contributed 100 Light tokens, so alloc_ratio is 500/100 = 5
    # The shield roles have won, so the claim comes out of the dark pool

    execution_info = await elements_token.balance_of(player_one_account.contract_address,DARK_TOKEN_ID).call()
    assert execution_info.result.res == 1000 * BOOST_UNIT_MULTIPLIER

    # Must claim rewards after game has expired
    after_max_hours = ((BLOCKS_PER_MINUTE * 60) * HOURS_PER_GAME) + 1
    starknet.state.state.block_info = BlockInfo(after_max_hours, 123456789)


    await player_one_key.send_transaction(
        account=player_one_account,
        to=tower_defence.contract_address,
        selector_name="claim_rewards",
        calldata=[game_idx]
    )

    execution_info = await elements_token.balance_of(player_one_account.contract_address,DARK_TOKEN_ID).call()
    assert execution_info.result.res == 1010 * BOOST_UNIT_MULTIPLIER
