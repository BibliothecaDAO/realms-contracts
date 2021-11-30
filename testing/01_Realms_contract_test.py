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

    ## The Controller is the only unchangeable contract.
    ## First deploy Arbiter.
    ## Then send the Arbiter address during Controller deployment.
    ## Then save the controller address in the Arbiter.
    ## Then deploy Controller address during module deployments.
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
    engine = await starknet.deploy(
        source="contracts/01_Realms.cairo",
        constructor_calldata=[controller.contract_address])
    settling = await starknet.deploy(
        source="contracts/02A_Settling.cairo",
        constructor_calldata=[controller.contract_address])
    building = await starknet.deploy(
        source="contracts/03A_Building.cairo",
        constructor_calldata=[controller.contract_address])
    resources = await starknet.deploy(
        source="contracts/04A_Resources.cairo",
        constructor_calldata=[controller.contract_address])
    army = await starknet.deploy(
        source="contracts/05A_Army.cairo",
        constructor_calldata=[controller.contract_address])
    raiding = await starknet.deploy(
        source="contracts/06A_Raiding.cairo",
        constructor_calldata=[controller.contract_address])
    pseudorandom = await starknet.deploy(
        source="contracts/07_PseudoRandom.cairo",
        constructor_calldata=[controller.contract_address])

    # The admin key controls the arbiter. Use it to have the arbiter
    # set the module deployment addresses in the controller.

    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='batch_set_controller_addresses',
        calldata=[
            engine.contract_address,
            settling.contract_address,
            building.contract_address,
            resources.contract_address,
            army.contract_address,
            raiding.contract_address,
            pseudorandom.contract_address])
    return starknet, accounts, signers, arbiter, controller, engine, \
        settling, building, resources, army, raiding

@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_account_unique(game_factory):
    starknet, accounts, signers, arbiter, controller, engine, \
       settling, building, resources, army, raiding = game_factory
    # Test the account deployments.
    admin_pub = await accounts[0].get_public_key().call()
    assert admin_pub.result == (signers[0].public_key,)
    user_1_pub = await accounts[1].get_public_key().call()
    assert user_1_pub.result == (signers[1].public_key,)
    assert signers[0].public_key != signers[1].public_key
