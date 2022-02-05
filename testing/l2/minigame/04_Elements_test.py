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
            
    elements_module = await starknet.deploy(
        source="contracts/l2/minigame/04_Elements.cairo",
        constructor_calldata=[
            controller.contract_address,
            elements_token.contract_address,
            admin_account.contract_address,
        ]
    )
    
    await admin_key.send_transaction(
        account=admin_account,
        to=elements_token.contract_address,
        selector_name='set_owner',
        calldata=[
            elements_module.contract_address
        ])

    tower_defence = await starknet.deploy(
        source="contracts/l2/minigame/01_TowerDefence.cairo",
        constructor_calldata=[
            controller.contract_address,
            elements_token.contract_address,
            4, # blocks per minute
            36 # hours per game
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
            tower_defence.contract_address, tower_defence_storage.contract_address
        ]
    )

    return starknet, accounts, signers, arbiter, controller, elements_token, elements_module

@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_elements_minting(game_factory):

    starknet, accounts, signers, _, _, elements_token, elements_module = game_factory
    
    admin_key = signers[0]
    admin_account = accounts[0]

    player_one_key = signers[1]
    player_one_account = accounts[1]


    execution_info = await elements_token.balance_of(player_one_account.contract_address, LIGHT_TOKEN_ID).call()
    old_bal = execution_info.result.res

    # Tests will start at game index 0
    next_game_idx = 1

    l1_address = 2342432432432423

    amount_to_mint = 1000

    await admin_key.send_transaction(
        account=admin_account,
        to=elements_module.contract_address,
        selector_name='mint_elements',
        calldata=[
            next_game_idx,
            l1_address,
            player_one_account.contract_address,
            LIGHT_TOKEN_ID,
            amount_to_mint
        ])

    execution_info = await elements_token.balance_of(player_one_account.contract_address, LIGHT_TOKEN_ID).call()
    assert execution_info.result.res == old_bal + amount_to_mint

    execution_info = await elements_module.get_total_minted( LIGHT_TOKEN_ID ).call()
    assert execution_info.result.total == amount_to_mint

