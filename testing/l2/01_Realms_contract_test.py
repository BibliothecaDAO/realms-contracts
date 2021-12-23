import pytest
import asyncio
import random
from utils import Signer, uint, str_to_felt, MAX_UINT256, assert_revert
from fixtures.account import account_factory

NUM_SIGNING_ACCOUNTS = 2
signer = Signer(123456789987654321)
# Params
first_token_id = (5042, 0)
second_token_id = (7921, 1)
third_token_id = (0, 13)


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
        source="contracts/settling_game/Arbiter.cairo",
        constructor_calldata=[admin_account.contract_address])
    controller = await starknet.deploy(
        source="contracts/settling_game/ModuleController.cairo",
        constructor_calldata=[arbiter.contract_address])
    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='set_address_of_controller',
        calldata=[controller.contract_address])
    settling_logic = await starknet.deploy(
        source="contracts/settling_game/01A_Settling.cairo",
        constructor_calldata=[controller.contract_address])
    settling_state = await starknet.deploy(
        source="contracts/settling_game/01B_Settling.cairo",
        constructor_calldata=[controller.contract_address])
    # The admin key controls the arbiter. Use it to have the arbiter
    # set the module deployment addresses in the controller.

    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='batch_set_controller_addresses',
        calldata=[
            settling_logic.contract_address, settling_state.contract_address])

    realms = await starknet.deploy(
        source="contracts/token/ERC721_Mintable.cairo",
        constructor_calldata=[
            str_to_felt("Realms"),  # name
            str_to_felt("Realms"),                 # ticker
            admin_account.contract_address,           # contract_owner
        ])

    return starknet, accounts, signers, arbiter, controller, settling_logic, settling_state, realms


# @pytest.mark.asyncio
# @pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
# async def test_account_unique(game_factory):
#     starknet, accounts, signers, arbiter, controller, \
#         settling_logic, settling_state, realms = game_factory
#     # Test the account deployments.
#     admin_pub = await accounts[0].get_public_key().call()
#     assert admin_pub.result == (signers[0].public_key,)
#     user_1_pub = await accounts[1].get_public_key().call()
#     assert user_1_pub.result == (signers[1].public_key,)
#     assert signers[0].public_key != signers[1].public_key
#     print(f'Signer 0 - {signers[0].public_key} ')
#     print(f'Signer 1 - {signers[1].public_key} ')


#
# Mint Realms to Owner
#
@pytest.mark.asyncio
@pytest.mark.parametrize('tokens, number_of_tokens', [
    [first_token_id, 1],
    [second_token_id, 2],
    [third_token_id, 3],
])
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_mint(game_factory, number_of_tokens, tokens):
    starknet, accounts, signers, arbiter, controller, \
        settling_logic, settling_state, realms = game_factory

    token_index = number_of_tokens - 1
    execution_info = await realms.token_at_index(accounts[0].contract_address, token_index).call()
    print(
        f'Token at Index {token_index} before mint: {execution_info.result.token}')

    await signer.send_transaction(
        accounts[0], realms.contract_address, 'mint', [
            accounts[0].contract_address, *tokens, 2123, 13036712910]
    )

    realm_info = await realms.get_realm_info(uint(5042)).call()
    print(f'Realm Info: {realm_info.result.realm_data}')

    index = 6

    unpacked_realm_info = await realms.fetch_realm_data(uint(5042)).call()
    print(
        f'Unpacked Realm Info at {index}: {unpacked_realm_info.result.realm_stats}')

    execution_info = await realms.balanceOf(accounts[0].contract_address).call()
    print(f'Realms Balance for owner is: {execution_info.result.balance}')
