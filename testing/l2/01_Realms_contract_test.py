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

initial_supply = 1000000 * (10 ** 18)


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
        source="contracts/settling_game/01A_Settling.cairo",
        constructor_calldata=[controller.contract_address])
    settling_state = await starknet.deploy(
        source="contracts/settling_game/01B_Settling.cairo",
        constructor_calldata=[controller.contract_address])
    resources_logic = await starknet.deploy(
        source="contracts/settling_game/02A_Resources.cairo",
        constructor_calldata=[controller.contract_address])
    resources_state = await starknet.deploy(
        source="contracts/settling_game/02B_Resources.cairo",
        constructor_calldata=[controller.contract_address])
    buildings_logic = await starknet.deploy(
        source="contracts/settling_game/03A_Buildings.cairo",
        constructor_calldata=[controller.contract_address])
    buildings_state = await starknet.deploy(
        source="contracts/settling_game/03B_Buildings.cairo",
        constructor_calldata=[controller.contract_address])        
    # The admin key controls the arbiter. Use it to have the arbiter
    # set the module deployment addresses in the controller.

    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='batch_set_controller_addresses',
        calldata=[
            settling_logic.contract_address, settling_state.contract_address, resources_logic.contract_address, resources_state.contract_address, buildings_logic.contract_address, buildings_state.contract_address])

    return starknet, accounts, signers, arbiter, controller, settling_logic, settling_state, realms, resources, lords, resources_logic, resources_state, s_realms, buildings_logic, buildings_state

#
# Mint Realms to Owner
#


@pytest.mark.asyncio
@pytest.mark.parametrize('tokens, number_of_tokens', [
    [first_token_id, 1]
])
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_mint(game_factory, number_of_tokens, tokens):
    starknet, accounts, signers, arbiter, controller, settling_logic, settling_state, realms, resources, lords, resources_logic, resources_state, s_realms, buildings_logic, buildings_state = game_factory

    await signer.send_transaction(
        accounts[0], realms.contract_address, 'mint', [
            accounts[0].contract_address, *tokens, 2123, 44526227375906105210343834517767]
    )

    # realm_info = await realms.get_realm_info(uint(5042)).call()
    # print(f'Realm Info: {realm_info.result.realm_data}')

    # unpacked_realm_info = await realms.fetch_realm_data(uint(5042)).call()
    # print(
    #     f'Unpacked Realm Info at: {unpacked_realm_info.result.realm_stats}')

    # execution_info = await realms.balanceOf(accounts[0].contract_address).call()
    # print(f'Realms Balance for owner is: {execution_info.result.balance}')

    # set approval for Settling contract to use Realm
    await signer.send_transaction(
        account=accounts[0], to=s_realms.contract_address, selector_name='setApprovalForAll', calldata=[settling_logic.contract_address, 1]
    )

    # settle Realm
    await signer.send_transaction(
        account=accounts[0], to=settling_logic.contract_address, selector_name='settle', calldata=[*uint(5042)]
    )

    # await signer.send_transaction(
    #     account=accounts[0], to=settling_state.contract_address, selector_name='set_approval', calldata=[]
    # )   

    # check transfer
    # execution_info = await realms.balanceOf(accounts[0].contract_address).call()
    # print(f'Realms Balance for owner is: {execution_info.result.balance}')

    # claim resources
    # await signer.send_transaction(
    #     account=accounts[0], to=resources_logic.contract_address, selector_name='claim_resources', calldata=[*uint(5042)]
    # )




    # player_resource_value = await resources.balanceOf(accounts[0].contract_address, 5).call()
    # player_resource_value_10 = await resources.balanceOf(accounts[0].contract_address, 10).call()
    # player_resource_value_12 = await resources.balanceOf(accounts[0].contract_address, 12).call()
    # player_resource_value_21 = await resources.balanceOf(accounts[0].contract_address, 21).call()
    # player_resource_value_9 = await resources.balanceOf(accounts[0].contract_address, 9).call()
    # print(
    #     f'Resource 5 Balance for player is: {player_resource_value.result.balance}')
    # print(
    #     f'Resource 10 Balance for player is: {player_resource_value_10.result.balance}')
    # print(
    #     f'Resource 12 Balance for player is: {player_resource_value_12.result.balance}')
    # print(
    #     f'Resource 21 Balance for player is: {player_resource_value_21.result.balance}')
    # print(
    #     f'Resource 9 Balance for player is: {player_resource_value_9.result.balance}') 

    # # set resource upgrade IDS
    # await signer.send_transaction(
    #     account=accounts[0], to=resources_state.contract_address, selector_name='set_resource_upgrade_ids', calldata=[5, 47408855671157818132997]
    # )
    # # upgrade resource
    # await signer.send_transaction(
    #     account=accounts[0], to=resources_logic.contract_address, selector_name='upgrade_resource', calldata=[*uint(5042), 
    #     5, 5, 5, 10, 12, 21, 9, 5, 10,10,10,10,10]
    # )

    # _player_resource_value = await resources.balanceOf(accounts[0].contract_address, 5).call()
    # _player_resource_value_10 = await resources.balanceOf(accounts[0].contract_address, 10).call()
    # _player_resource_value_12 = await resources.balanceOf(accounts[0].contract_address, 12).call()
    # _player_resource_value_21 = await resources.balanceOf(accounts[0].contract_address, 21).call()
    # _player_resource_value_9 = await resources.balanceOf(accounts[0].contract_address, 9).call()
    # print(
    #     f'BURNING!')
    # print(
    #     f'Resource 5 Balance for player is: {_player_resource_value.result.balance}')
    # print(
    #     f'Resource 10 Balance for player is: {_player_resource_value_10.result.balance}')
    # print(
    #     f'Resource 12 Balance for player is: {_player_resource_value_12.result.balance}')
    # print(
    #     f'Resource 21 Balance for player is: {_player_resource_value_21.result.balance}')
    # print(
    #     f'Resource 9 Balance for player is: {_player_resource_value_9.result.balance}') 

    # set resource upgrade IDS
    await signer.send_transaction(
        account=accounts[0], to=buildings_state.contract_address, selector_name='set_building_cost_ids', calldata=[0, 47390263963055590408705]
    )

    # set resource values 
    await signer.send_transaction(
        account=accounts[0], to=buildings_state.contract_address, selector_name='set_building_cost_values', calldata=[0, 3245978011684776246407343248547850]
    )

    ids = await buildings_logic.fetch_building_cost_ids(0).call()
    values = await buildings_logic.fetch_building_cost_values(0).call()
    
    print(
        f'Resource 9 Balance for player is: {ids.result[0]}')  
    print(
        f'Resource 9 Balance for player is: {values.result}') 

    # create building
    await signer.send_transaction(
        account=accounts[0], to=buildings_logic.contract_address, selector_name='build', calldata=[*uint(5042),
        0, 10, 1, 2, 3, 4, 5,6,7,8,9,10, 10, 10,10,10,10,10, 10,10,10,10,10]
    )

    # await signer.send_transaction(
    #     account=accounts[0], to=buildings_logic.contract_address, selector_name='build', calldata=[*uint(5042),
    #     0, 10, 1, 2, 3, 4, 5,6,7,8,9,10, 10, 10,10,10,10,10, 10,10,10,10,10]
    # )
    
    values = await buildings_logic.fetch_buildings_by_type(uint(5042)).call()
    
    print(
        f'Buildings: {values.result.realm_buildings}')  

    # # settle Realm
    # await signer.send_transaction(
    #     account=accounts[0], to=settling_logic.contract_address, selector_name='unsettle', calldata=[*uint(5042)]
    # )