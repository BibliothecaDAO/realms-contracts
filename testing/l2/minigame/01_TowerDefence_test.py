import pytest
import asyncio

from fixtures.account import account_factory
from utils.string import str_to_felt

NUM_SIGNING_ACCOUNTS = 4

LIGHT_TOKEN_ID = 1
DARK_TOKEN_ID = 2

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
            2,
            LIGHT_TOKEN_ID, DARK_TOKEN_ID,
            2,
            3000,3000,
            1,1,1,1,1
        ]
    )
            
    tower_defence = await starknet.deploy(
        source="contracts/l2/minigame/01_TowerDefence.cairo",
        constructor_calldata=[
            controller.contract_address,
            elements_token.contract_address
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

    _, accounts, signers, _, _, _, tower_defence, tower_defence_storage = game_factory
    
    admin_key = signers[0]
    admin_account = accounts[0]

    await admin_key.send_transaction(
        account=admin_account,
        to=tower_defence.contract_address,
        selector_name='create_game',
        calldata=[]
    )

    execution_info = await tower_defence_storage.get_latest_game_index().call()
    assert execution_info.result == (1,)

@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_shield_and_attack_tower(game_factory):

    _, accounts, signers, _, _, elements_token, tower_defence, tower_defence_storage = game_factory
    
    admin_key = signers[0]
    admin_account = accounts[0]

    player_one_key = signers[1]
    player_one_account = accounts[1]

    player_two_key = signers[2]
    player_two_account = accounts[2]

    player_three_key = signers[3]
    player_three_account = accounts[3]

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
            1000,1000])

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
            1000,1000])

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
            1000,1000])
  
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

    await player_one_key.send_transaction(
        account=player_one_account,
        to=tower_defence.contract_address,
        selector_name="increase_shield",
        calldata=[
            1,
            LIGHT_TOKEN_ID,
            100
        ]
    )
    execution_info = await elements_token.balance_of(player_one_account.contract_address, LIGHT_TOKEN_ID).call()
    assert execution_info.result.res == 900

    execution_info = await tower_defence_storage.get_shield_value(1,LIGHT_TOKEN_ID).call()
    assert execution_info.result.value == 100

    execution_info = await tower_defence_storage.get_user_reward_alloc(1,player_one_account.contract_address,0).call()
    assert execution_info.result.value == 100

    execution_info = await tower_defence_storage.get_total_reward_alloc(1,0).call()
    assert execution_info.result.value == 100

    execution_info = await elements_token.balance_of(tower_defence.contract_address,LIGHT_TOKEN_ID).call()
    assert execution_info.result.res == 100

    # Player 2 Attacks with 50 DARK

    await player_two_key.send_transaction(
        account=player_two_account,
        to=tower_defence.contract_address,
        selector_name="attack_tower",
        calldata=[
            1,
            DARK_TOKEN_ID, 
            50
        ]
    )
    execution_info = await elements_token.balance_of(player_two_account.contract_address,DARK_TOKEN_ID).call()
    assert execution_info.result.res == 950

    execution_info = await tower_defence_storage.get_main_health(1).call()
    assert execution_info.result.health == 10000

    execution_info = await tower_defence_storage.get_shield_value(1,LIGHT_TOKEN_ID).call()
    assert execution_info.result.value == 50

    execution_info = await tower_defence_storage.get_user_reward_alloc(1,player_two_account.contract_address,1).call()
    assert execution_info.result.value == 50

    execution_info = await elements_token.balance_of(tower_defence.contract_address,DARK_TOKEN_ID).call()
    assert execution_info.result.res == 50

    # Player 3 Increases shield by 400 LIGHT

    await player_three_key.send_transaction(
        account=player_three_account,
        to=tower_defence.contract_address,
        selector_name="increase_shield",
        calldata=[
            1,
            LIGHT_TOKEN_ID,
            400
        ]
    )
    execution_info = await elements_token.balance_of(player_three_account.contract_address, LIGHT_TOKEN_ID).call()
    assert execution_info.result.res == 600

    execution_info = await tower_defence_storage.get_shield_value(1,LIGHT_TOKEN_ID).call()
    assert execution_info.result.value == 450

    execution_info = await tower_defence_storage.get_user_reward_alloc(1,player_three_account.contract_address,0).call()
    assert execution_info.result.value == 400

    execution_info = await tower_defence_storage.get_total_reward_alloc(1,0).call()
    assert execution_info.result.value == 500

    execution_info = await elements_token.balance_of(tower_defence.contract_address,LIGHT_TOKEN_ID).call()
    assert execution_info.result.res == 500

    # Player 1 claims if tower is alive, should only get 10 DARK

    execution_info = await elements_token.balance_of(player_one_account.contract_address,DARK_TOKEN_ID).call()
    assert execution_info.result.res == 1000

    await player_one_key.send_transaction(
        account=player_one_account,
        to=tower_defence.contract_address,
        selector_name="claim_rewards",
        calldata=[1]
    )

    execution_info = await elements_token.balance_of(player_one_account.contract_address,DARK_TOKEN_ID).call()
    assert execution_info.result.res == 1010