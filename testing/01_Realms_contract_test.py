import pytest
import asyncio
import random
from fixtures.account import account_factory

NUM_SIGNING_ACCOUNTS = 2

# Params


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
        source="contracts/Arbiter.cairo",
        constructor_calldata=[admin_account.contract_address])
    controller = await starknet.deploy(
        source="contracts/ModuleController.cairo",
        constructor_calldata=[arbiter.contract_address])
    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='set_address_of_controller',
        calldata=[controller.contract_address])
    settling_logic = await starknet.deploy(
        source="contracts/01A_Settling.cairo",
        constructor_calldata=[controller.contract_address])
    settling_state = await starknet.deploy(
        source="contracts/01B_Settling.cairo",
        constructor_calldata=[controller.contract_address])
    # The admin key controls the arbiter. Use it to have the arbiter
    # set the module deployment addresses in the controller.

    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='batch_set_controller_addresses',
        calldata=[
            settling_logic.contract_address, settling_state.contract_address])
    return starknet, accounts, signers, arbiter, controller, settling_logic, settling_state


@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_account_unique(game_factory):
    starknet, accounts, signers, arbiter, controller, \
        settling_logic, settling_state = game_factory
    # Test the account deployments.
    admin_pub = await accounts[0].get_public_key().call()
    assert admin_pub.result == (signers[0].public_key,)
    user_1_pub = await accounts[1].get_public_key().call()
    assert user_1_pub.result == (signers[1].public_key,)
    assert signers[0].public_key != signers[1].public_key
