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

initial_supply = 1000000  * (10 ** 18)

@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()


@pytest.fixture(scope='module')
async def game_factory(account_factory):
    (starknet, accounts, signers) = account_factory
    admin_key = signers[0]
    admin_account = accounts[0]


    # ERC Contracts 
    lords = await starknet.deploy(
        source="contracts/token/ERC20_Mintable.cairo",
        constructor_calldata=[
            str_to_felt("Lords"),     # name
            str_to_felt("LRD"),       # symbol
            *uint(initial_supply),                # initial supply
            accounts[0].contract_address,
            accounts[0].contract_address   # recipient
        ]
    )

    realms = await starknet.deploy(
        source="contracts/settling_game/Realms_ERC721_Mintable.cairo",
        constructor_calldata=[
            str_to_felt("Realms"),  # name
            str_to_felt("Realms"),                 # ticker
            admin_account.contract_address,           # contract_owner
        ])

    resources = await starknet.deploy(
        source="contracts/token/ERC1155/ERC1155_Mintable.cairo",
        constructor_calldata=[
            admin_account.contract_address,
            2,
            1,2,
            2,
            1000,5000
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
        constructor_calldata=[arbiter.contract_address, lords.contract_address, resources.contract_address, realms.contract_address])
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
    claim_logic = await starknet.deploy(
        source="contracts/settling_game/02A_Claim.cairo",
        constructor_calldata=[controller.contract_address])        
    claim_state = await starknet.deploy(
        source="contracts/settling_game/02B_Claim.cairo",
        constructor_calldata=[controller.contract_address])               
    # The admin key controls the arbiter. Use it to have the arbiter
    # set the module deployment addresses in the controller.

    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='batch_set_controller_addresses',
        calldata=[
            settling_logic.contract_address, settling_state.contract_address, claim_logic.contract_address, claim_state.contract_address])



    return starknet, accounts, signers, arbiter, controller, settling_logic, settling_state, realms, resources, lords, claim_logic, claim_state

#
# Mint Realms to Owner
#
@pytest.mark.asyncio
@pytest.mark.parametrize('tokens, number_of_tokens', [
    [first_token_id, 1]
])
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_mint(game_factory, number_of_tokens, tokens):
    starknet, accounts, signers, arbiter, controller, settling_logic, settling_state, realms, resources, lords, claim_logic, claim_state = game_factory

    await signer.send_transaction(
        accounts[0], realms.contract_address, 'mint', [     
            accounts[0].contract_address, *tokens, 2123, 4036322236326278]
    )
    
    await signer.send_transaction(
        account=accounts[0], to=settling_logic.contract_address, selector_name='settle', calldata=[*uint(5042)]
    )

    await signer.send_transaction(
        account=accounts[0], to=claim_logic.contract_address, selector_name='claim_resources', calldata=[*uint(5042)]
    )