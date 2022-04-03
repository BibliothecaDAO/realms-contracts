import pytest
import asyncio
import random
from tests.utils import Signer, uint, str_to_felt, MAX_UINT256, assert_revert
from tests.conftest import account_factory

NUM_SIGNING_ACCOUNTS = 2
signer = Signer(123456789987654321)
# Params
first_token_id = (5042, 0)
second_token_id = (7921, 1)
third_token_id = (0, 13)

lords_initial_supply = 1000000 * (10 ** 18)


@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()


@pytest.fixture(scope='module')
async def game_factory(account_factory):
    (starknet, accounts, signers) = account_factory
    admin_key = signers[0]
    admin_account = accounts[0]
    treasury_account = accounts[1]

    # ERC Contracts
    lords = await starknet.deploy(
        source="contracts/token/ERC20/ERC20_Mintable.cairo",
        constructor_calldata=[
            str_to_felt("Lords"),     # name
            str_to_felt("LRD"),       # symbol
            *uint(lords_initial_supply),                # initial supply
            accounts[0].contract_address,
            accounts[0].contract_address   # recipient
        ]
    )

    realms = await starknet.deploy(
        source="contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo",
        constructor_calldata=[
            str_to_felt("Realms"),  # name
            str_to_felt("Realms"),                 # ticker
            admin_account.contract_address,           # contract_owner
        ])

    s_realms = await starknet.deploy(
        source="contracts/settling_game/tokens/S_Realms_ERC721_Mintable.cairo",
        constructor_calldata=[
            str_to_felt("SRealms"),  # name
            str_to_felt("SRealms"),                 # ticker
            admin_account.contract_address,           # contract_owner
        ])

    resources = await starknet.deploy(
        source="contracts/token/ERC1155/ERC1155_Mintable.cairo",
        constructor_calldata=[
            admin_account.contract_address,
            2,
            1, 2,
            2,
            1000, 5000
        ])

    # The Controller is the only unchangeable contract.
    # First deploy Arbiter.
    # Then send the Arbiter address during Controller deployment.
    # Then save the controller address in the Arbiter.
    # Then deploy Controller address during module deployments.
    arbiter = await starknet.deploy(
        source="contracts/settling_game/Arbiter.cairo",
        constructor_calldata=[admin_account.contract_address])
    controller = await starknet.deploy(
        source="contracts/settling_game/ModuleController.cairo",
        constructor_calldata=[arbiter.contract_address, lords.contract_address, resources.contract_address, realms.contract_address, treasury_account.contract_address, s_realms.contract_address])
    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='set_address_of_controller',
        calldata=[controller.contract_address])
    settling_logic = await starknet.deploy(
        source="contracts/settling_game/L01_Settling.cairo",
        constructor_calldata=[controller.contract_address])
    settling_state = await starknet.deploy(
        source="contracts/settling_game/S01_Settling.cairo",
        constructor_calldata=[controller.contract_address])
    resources_logic = await starknet.deploy(
        source="contracts/settling_game/L02_Resources.cairo",
        constructor_calldata=[controller.contract_address])
    resources_state = await starknet.deploy(
        source="contracts/settling_game/S02_Resources.cairo",
        constructor_calldata=[controller.contract_address])
    buildings_logic = await starknet.deploy(
        source="contracts/settling_game/L03_Buildings.cairo",
        constructor_calldata=[controller.contract_address])
    buildings_state = await starknet.deploy(
        source="contracts/settling_game/S03_Buildings.cairo",
        constructor_calldata=[controller.contract_address])
    calculator_logic = await starknet.deploy(
        source="contracts/settling_game/L04_Calculator.cairo",
        constructor_calldata=[controller.contract_address])
    wonders_logic = await starknet.deploy(
        source="contracts/settling_game/L05_Wonders.cairo",
        constructor_calldata=[controller.contract_address])
    wonders_state = await starknet.deploy(
        source="contracts/settling_game/S05_Wonders.cairo",
        constructor_calldata=[controller.contract_address])
    # The admin key controls the arbiter. Use it to have the arbiter
    # set the module deployment addresses in the controller.

    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='batch_set_controller_addresses',
        calldata=[
            settling_logic.contract_address, settling_state.contract_address,
            resources_logic.contract_address, resources_state.contract_address,
            buildings_logic.contract_address, buildings_state.contract_address,
            calculator_logic.contract_address, wonders_logic.contract_address,
            wonders_state.contract_address
        ])

    return starknet, accounts, signers, arbiter, controller, settling_logic, settling_state, realms, resources, lords, resources_logic, resources_state, s_realms, buildings_logic, buildings_state, calculator_logic, wonders_state

#
# Mint Realms to Owner
#


@pytest.mark.asyncio
@pytest.mark.parametrize('tokens, number_of_tokens', [
    [first_token_id, 1]
])
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_mint(game_factory, number_of_tokens, tokens):
    starknet, accounts, signers, arbiter, controller, settling_logic, settling_state, realms, resources, lords, resources_logic, resources_state, s_realms, buildings_logic, buildings_state, calculator_logic, wonders_state = game_factory

    await signer.send_transaction(
        accounts[0], realms.contract_address, 'mint', [
            accounts[0].contract_address, *tokens, 2123, 44526227356702393855067989737735]
    )

    # set approval for Settling contract to use Realm
    await signer.send_transaction(
        account=accounts[0], to=realms.contract_address, selector_name='setApprovalForAll', calldata=[settling_logic.contract_address, 1]
    )

    # settle Realm
    await signer.send_transaction(
        account=accounts[0], to=settling_logic.contract_address, selector_name='settle', calldata=[*uint(5042)]
    )

    # set approval for logic module
    await signer.send_transaction(
        account=accounts[0], to=settling_state.contract_address, selector_name='set_approval', calldata=[]
    )

    # claim resources
    await signer.send_transaction(
        account=accounts[0], to=resources_logic.contract_address, selector_name='claim_resources', calldata=[*uint(5042)]
    )

    player_resource_value = await resources.balanceOf(accounts[0].contract_address, 1).call()
    player_resource_value_1 = await resources.balanceOf(accounts[0].contract_address, 2).call()
    player_resource_value_2 = await resources.balanceOf(accounts[0].contract_address, 3).call()
    player_resource_value_3 = await resources.balanceOf(accounts[0].contract_address, 4).call()
    player_resource_value_4 = await resources.balanceOf(accounts[0].contract_address, 5).call()

    print(
        f'Resource 1 Balance for player is: {player_resource_value.result.balance}')
    print(
        f'Resource 2 Balance for player is: {player_resource_value_1.result.balance}')
    print(
        f'Resource 3 Balance for player is: {player_resource_value_2.result.balance}')
    print(
        f'Resource 4 Balance for player is: {player_resource_value_3.result.balance}')
    print(
        f'Resource 5 Balance for player is: {player_resource_value_4.result.balance}')

    wonder_pool_resource_value = await resources.balanceOf(wonders_state.contract_address, 1).call()
    wonder_pool_resource_value_1 = await resources.balanceOf(wonders_state.contract_address, 2).call()
    wonder_pool_resource_value_2 = await resources.balanceOf(wonders_state.contract_address, 3).call()
    wonder_pool_resource_value_3 = await resources.balanceOf(wonders_state.contract_address, 4).call()
    wonder_pool_resource_value_4 = await resources.balanceOf(wonders_state.contract_address, 5).call()

    print(
        f'Resource 1 Balance for wonder_pool is: {wonder_pool_resource_value.result.balance}')
    print(
        f'Resource 2 Balance for wonder_pool is: {wonder_pool_resource_value_1.result.balance}')
    print(
        f'Resource 3 Balance for wonder_pool is: {wonder_pool_resource_value_2.result.balance}')
    print(
        f'Resource 4 Balance for wonder_pool is: {wonder_pool_resource_value_3.result.balance}')
    print(
        f'Resource 5 Balance for wonder_pool is: {wonder_pool_resource_value_4.result.balance}')

    # assert 0 == 1


@pytest.mark.asyncio
@pytest.mark.parametrize('tokens, number_of_tokens', [
    [first_token_id, 1]
])
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_tax_formula(game_factory, number_of_tokens, tokens):
    starknet, accounts, signers, arbiter, controller, settling_logic, settling_state, realms, resources, lords, resources_logic, resources_state, s_realms, buildings_logic, buildings_state, calculator_logic, wonders_logic, wonders_state = game_factory

    await signer.send_transaction(
        accounts[0], realms.contract_address, 'mint', [
            accounts[0].contract_address, *tokens, 2123, 44526227356702393855067989737735]
    )

    # set approval for Settling contract to use Realm
    await signer.send_transaction(
        account=accounts[0], to=realms.contract_address, selector_name='setApprovalForAll', calldata=[settling_logic.contract_address, 1]
    )

    # settle Realm
    await signer.send_transaction(
        account=accounts[0], to=settling_logic.contract_address, selector_name='settle', calldata=[*uint(5042)]
    )

    realms_settled_info = await settling_state.get_total_realms_settled().call()

    print(
        f'Total realms settled: {realms_settled_info.result.realms_settled}')

    tax_percentage_info = await calculator_logic.calculateWonderTax().call()

    print(
        f'Percent tax: {tax_percentage_info.result.tax_percentage}')

    # assert 0 == 1
