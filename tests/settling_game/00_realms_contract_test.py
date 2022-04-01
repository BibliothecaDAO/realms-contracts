import pytest
import asyncio
import json
from openzeppelin.tests.utils import Signer, uint, str_to_felt
import time

from scripts.binary_converter import map_realm

from tests.conftest import set_block_timestamp

json_realms = json.load(open('data/realms.json'))

# ACCOUNTS
NUM_SIGNING_ACCOUNTS = 2
signer = Signer(123456789987654321)

# LORDS SUPPLY
initial_supply = 1000000 * (10 ** 18)

# REALM TOKENS TO MINT
first_token_id = uint(1)
building_id = 1

# 1.5 * 7 Days
stake_time = 129600 * 7


@pytest.fixture(scope='module')
async def game_factory(account_factory):
    (starknet, accounts, signers) = account_factory
    admin_key = signers[0]
    admin_account = accounts[0]
    treasury_account = accounts[1]

    set_block_timestamp(starknet.state, round(time.time()))

    # ERC Contracts
    lords = await starknet.deploy(
        source="contracts/token/ERC20_Mintable.cairo",
        constructor_calldata=[
            str_to_felt("Lords"),     # name
            str_to_felt("LRD"),       # symbol
            *uint(initial_supply),                # initial supply
            treasury_account.contract_address,  # recipient
            treasury_account.contract_address   # owner
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
        source="contracts/settling_game/tokens/Resources_ERC1155_Mintable_Burnable.cairo",
        constructor_calldata=[
            1234,
            admin_account.contract_address
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

    # The admin key controls the arbiter. Use it to have the arbiter
    # set the module deployment addresses in the controller.
    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='batch_set_controller_addresses',
        calldata=[
            settling_logic.contract_address, settling_state.contract_address, resources_logic.contract_address, resources_state.contract_address, buildings_logic.contract_address, buildings_state.contract_address, calculator_logic.contract_address])

    await admin_key.send_transaction(
        account=admin_account,
        to=s_realms.contract_address,
        selector_name='Set_module_access',
        calldata=[
            settling_logic.contract_address])

    return starknet, accounts, signers, arbiter, controller, settling_logic, settling_state, realms, resources, lords, resources_logic, resources_state, s_realms, buildings_logic, buildings_state, calculator_logic


@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_mint_realm(game_factory):
    starknet, accounts, signers, arbiter, controller, settling_logic, settling_state, realms, resources, lords, resources_logic, resources_state, s_realms, buildings_logic, buildings_state, calculator_logic = game_factory

    #################
    # VALUE SETTERS #
    #################

    await signer.send_transaction(
        account=accounts[0], to=resources.contract_address, selector_name='mintBatch', calldata=[accounts[0].contract_address, 5, *uint(1), *uint(2), *uint(3), *uint(4), *uint(5), 5, *uint(100), *uint(100), *uint(100), *uint(100), *uint(100)]
    )

    # APPROVE RESOURCE CONTRACT FOR LORDS TRANSFERS - SET AT FULL SUPPLY TODO: NEEDS MORE SECURE SYSTEM
    await signers[1].send_transaction(
        account=accounts[1], to=lords.contract_address, selector_name='approve', calldata=[resources_logic.contract_address, *uint(initial_supply)]
    )

    # RESOURCES
    # SET VALUES (ids,cost) AT 1,2,3,4,5,10,10,10,10,10
    await signer.send_transaction(
        account=accounts[0], to=resources_state.contract_address, selector_name='set_resource_upgrade_value', calldata=[5, 47408855671140352459265]
    )

    # BUILDING 1 IDS 1,2,3,4,5
    await signer.send_transaction(
        account=accounts[0], to=buildings_state.contract_address, selector_name='set_building_cost_ids', calldata=[building_id, 21542142465]
    )

    # BUILDING 2 VALUES 10,10,10,10,10
    await signer.send_transaction(
        account=accounts[0], to=buildings_state.contract_address, selector_name='set_building_cost_values', calldata=[building_id, 2815437129687050]
    )

    # REALM METADATA
    await signer.send_transaction(
        accounts[0], realms.contract_address, 'set_realm_data', [
            *first_token_id, map_realm(json_realms['1'])]
    )

    ########
    # MINT #
    ########

    await signer.send_transaction(
        accounts[0], realms.contract_address, 'mint', [
            accounts[0].contract_address, *first_token_id]
    )

    # print realm details
    realm_info = await realms.get_realm_info(first_token_id).invoke()
    print(f'\033[0;31;37m🏰 Realm metadata: {realm_info.result.realm_data}\n')
    unpacked_realm_info = await realms.fetch_realm_data(first_token_id).invoke()
    print(
        f'🏰 Realm unpacked: {unpacked_realm_info.result.realm_stats}\n')

    # check balance of Realm on account
    balance_of = await realms.balanceOf(accounts[0].contract_address).invoke()
    assert balance_of.result.balance[0] == 1
    print(f'🏰 Balance of Realms: {balance_of.result.balance[0]}\n')

    # set approval for Settling contract to use Realm
    await signer.send_transaction(
        account=accounts[0], to=realms.contract_address, selector_name='setApprovalForAll', calldata=[settling_logic.contract_address, 1]
    )

    ##########
    # SETTLE #
    ##########

    await signer.send_transaction(
        account=accounts[0], to=settling_logic.contract_address, selector_name='settle', calldata=[*first_token_id]
    )
    print(f'\033[2;31🏰 Settling Realm...\n')

    # check transfer
    balance_of = await realms.balanceOf(accounts[0].contract_address).invoke()
    assert balance_of.result.balance[0] == 0
    print(
        f'🏰 Realms Balance for owner after Staking: {balance_of.result.balance[0]}\n')

    # increments time by 1.5 days to simulate stake
    set_block_timestamp(starknet.state, round(time.time()) + stake_time)

    ############
    # 😊 STATS #
    ############

    happiness = await calculator_logic.calculateHappiness(first_token_id).invoke()
    assert happiness.result.happiness == 25
    print(f'\033[1;31;40m😊 Happiness level is {happiness.result.happiness}\n')

    culture = await calculator_logic.calculateCulture(first_token_id).invoke()
    assert culture.result.culture == 25
    print(f'\033[1;31;40m😊 Culture level is {culture.result.culture}\n')

    #####################
    # RESOURCES & LORDS #
    #####################

    # CLAIM RESOURCES
    await signer.send_transaction(
        account=accounts[0], to=resources_logic.contract_address, selector_name='claim_resources', calldata=[*first_token_id]
    )
    for index in range(22):
        player_resource_value = await resources.balanceOf(accounts[0].contract_address, uint(index + 1)).invoke()
        print(
            f'\033[1;33;40m🔥 Resource {index + 1} balance is: {player_resource_value.result.balance[0]}')

    player_lords_value = await lords.balanceOf(accounts[0].contract_address).invoke()

    print(
        f'\n \033[1;33;40m$LORDS {player_lords_value.result.balance}\n')

    print(
        f'\n \033[1;33;40m🔥 Upgrading Resource.... 🔥\n')

    # UPGRADE RESOURCE
    await signer.send_transaction(
        account=accounts[0], to=resources_logic.contract_address, selector_name='upgrade_resource', calldata=[*first_token_id, 5]
    )

    for index in range(22):
        player_resource_value = await resources.balanceOf(accounts[0].contract_address, uint(index + 1)).invoke()
        print(
            f'\033[1;33;40m🔥 Resource {index + 1} balance is: {player_resource_value.result.balance[0]}')

    #############
    # BUILDINGS #
    #############

    ids = await buildings_logic.fetch_building_cost_ids(building_id).call()
    values = await buildings_logic.fetch_building_cost_values(building_id).call()

    print(
        f'Building {building_id} Cost IDS: {ids.result[0]}')
    print(
        f'Building {building_id} Cost Values: {values.result[0]}')

    # create building
    await signer.send_transaction(
        account=accounts[0], to=buildings_logic.contract_address, selector_name='build', calldata=[*first_token_id, building_id])

    values = await buildings_logic.fetch_buildings_by_type(first_token_id).call()

    print(
        f'Realm {first_token_id} buildings: {values.result.realm_buildings}')

    ##################
    # UNSETTLE REALM #
    ##################

    # TODO: ALLOW SETTLING LOGIC TO TRANSFER REALMS FROM STATE
    # await signer.send_transaction(
    #     account=accounts[0], to=settling_logic.contract_address, selector_name='unsettle', calldata=[*uint(5042)]
    # )

    # # CHECK
    # balance_of = await realms.balanceOf(accounts[0].contract_address).invoke()
    # assert balance_of.result.balance[0] == 1
    # print(
    #     f'🏰 Realms Balance for owner after Staking: {balance_of.result.balance[0]}\n')
