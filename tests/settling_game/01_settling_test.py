import pytest
import asyncio
import json
from openzeppelin.tests.utils import Signer, uint, str_to_felt, from_uint, felt_to_str
import time

from scripts.binary_converter import map_realm

from tests.conftest import set_block_timestamp

json_realms = json.load(open('data/realms.json'))

# ACCOUNTS
NUM_SIGNING_ACCOUNTS = 2
signer = Signer(123456789987654321)

# LORDS SUPPLY
INITIAL_SUPPLY = 1000000 * (10 ** 18)

# REALM TOKENS TO MINT
FIRST_TOKEN_ID = uint(1)
WONDER_TOKEN_ID = uint(839)

# 1.5 * 7 Days
DAYS = 86400
STAKED_DAYS = 7

LORDS_RATE = 25
RESOURCES = 100
STAKE_TIME = DAYS * STAKED_DAYS
BUILDING_ID = 1
RESOURCE_ID = 2


@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_mint_realm(game_factory):
    admin_account, treasury_account, starknet, accounts, signers, arbiter, controller, settling_logic, settling_state, realms, resources, lords, resources_logic, resources_state, s_realms, buildings_logic, buildings_state, calculator_logic, storage = game_factory

    #################
    # VALUE SETTERS #
    #################

    await signer.send_transaction(
        account=admin_account, to=resources.contract_address, selector_name='mintBatch', calldata=[admin_account.contract_address, 5, *uint(1), *uint(2), *uint(3), *uint(4), *uint(5), 5, *uint(100), *uint(100), *uint(100), *uint(100), *uint(100)]
    )

    # APPROVE RESOURCE CONTRACT FOR LORDS TRANSFERS - SET AT FULL SUPPLY TODO: NEEDS MORE SECURE SYSTEM
    await signers[1].send_transaction(
        account=treasury_account, to=lords.contract_address, selector_name='approve', calldata=[resources_logic.contract_address, *uint(INITIAL_SUPPLY)]
    )

    await signers[1].send_transaction(
        account=treasury_account, to=lords.contract_address, selector_name='approve', calldata=[settling_logic.contract_address, *uint(INITIAL_SUPPLY)]
    )

    # RESOURCES
    # SET VALUES (ids,cost) AT 1,2,3,4,5,10,10,10,10,10
    await signer.send_transaction(
        account=admin_account, to=storage.contract_address, selector_name='set_resource_upgrade_value', calldata=[RESOURCE_ID, 47408855671140352459265]
    )

    # BUILDING 1 IDS 1,2,3,4,5
    await signer.send_transaction(
        account=admin_account, to=storage.contract_address, selector_name='set_building_cost_ids', calldata=[BUILDING_ID, 21542142465]
    )

    # BUILDING 1 VALUES 10,10,10,10,10
    await signer.send_transaction(
        account=admin_account, to=storage.contract_address, selector_name='set_building_cost_values', calldata=[BUILDING_ID, 2815437129687050]
    )

    # REALM METADATA

    await set_realm_meta(admin_account, realms, FIRST_TOKEN_ID)
    await set_realm_meta(admin_account, realms, WONDER_TOKEN_ID)

    ########
    # MINT #
    ########

    await mint_realm(admin_account, realms, FIRST_TOKEN_ID)
    await mint_realm(admin_account, realms, WONDER_TOKEN_ID)

    # print realm details
    realm_info = await realms.get_realm_info(FIRST_TOKEN_ID).invoke()
    print(f'\033[1;33;40m🏰 | Realm metadata: {realm_info.result.realm_data}\n')
    assert realm_info.result.realm_data == map_realm(
        json_realms[str(from_uint(FIRST_TOKEN_ID))])

    unpacked_realm_info = await realms.fetch_realm_data(FIRST_TOKEN_ID).invoke()
    print(
        f'\033[1;33;40m🏰 | Realm unpacked: {unpacked_realm_info.result.realm_stats}\n')

    # check balance of Realm on account
    await checks_realms_balance(admin_account, realms, 2)

    # set approval for Settling contract to use Realm
    await signer.send_transaction(
        account=admin_account, to=realms.contract_address, selector_name='setApprovalForAll', calldata=[settling_logic.contract_address, 1]
    )

    ##########
    # SETTLE #
    ##########

    print(f'\033[2;31🏰 Settling Realm...\n')
    await settle_realm(admin_account, settling_logic, FIRST_TOKEN_ID)
    await settle_realm(admin_account, settling_logic, WONDER_TOKEN_ID)

    # check transfer
    await checks_realms_balance(admin_account, realms, 0)

    # # increments time by 1.5 days to simulate stake
    set_block_timestamp(starknet.state, round(time.time()) + STAKE_TIME)

    ############
    # 😊 STATS #
    ############

    happiness = await calculator_logic.calculateHappiness(FIRST_TOKEN_ID).invoke()
    assert happiness.result.happiness == 25
    print(f'\033[1;31;40m😊 Happiness level is {happiness.result.happiness}\n')

    culture = await calculator_logic.calculateCulture(FIRST_TOKEN_ID).invoke()
    assert culture.result.culture == 25
    print(f'\033[1;31;40m😊 Culture level is {culture.result.culture}\n')

    tax_percentage_info = await calculator_logic.calculate_wonder_tax().call()
    print(
        f'\033[1;31;40m😊 Wonder Tax {tax_percentage_info.result.tax_percentage}\n')

    #####################
    # RESOURCES & LORDS #
    #####################

    # CLAIM RESOURCES
    await claim_resources(admin_account, resources_logic, FIRST_TOKEN_ID)

    await show_resource_balance(admin_account, resources)

    await show_lords_balance(admin_account, lords)

    # # UPGRADE RESOURCE
    print(
        f'\n \033[1;33;40m🔥 Upgrading Resource.... 🔥\n')

    await signer.send_transaction(
        account=admin_account, to=resources_logic.contract_address, selector_name='upgrade_resource', calldata=[*FIRST_TOKEN_ID, RESOURCE_ID]
    )

    await show_resource_balance(admin_account, resources)

    # increment another time so more resource accure
    set_block_timestamp(starknet.state, round(
        time.time()) + STAKE_TIME * 2)

    await claim_resources(admin_account, resources_logic, FIRST_TOKEN_ID)

    await show_resource_balance(admin_account, resources)

    #############
    # BUILDINGS #
    #############

    ids = await buildings_logic.fetch_building_cost_ids(BUILDING_ID).call()
    values = await buildings_logic.fetch_building_cost_values(BUILDING_ID).call()

    print(
        f'Building {BUILDING_ID} Cost IDS: {ids.result[0]}')
    print(
        f'Building {BUILDING_ID} Cost Values: {values.result[0]}')

    # create building
    await signer.send_transaction(
        account=admin_account, to=buildings_logic.contract_address, selector_name='build', calldata=[*FIRST_TOKEN_ID, BUILDING_ID])

    values = await buildings_logic.fetch_buildings_by_type(FIRST_TOKEN_ID).call()

    print(
        f'Realm {FIRST_TOKEN_ID} buildings: {values.result.realm_buildings}')

    set_block_timestamp(starknet.state, round(
        time.time()) + STAKE_TIME * 3)

    ##################
    # UNSETTLE REALM #
    ##################

    await signer.send_transaction(
        account=admin_account, to=settling_logic.contract_address, selector_name='unsettle', calldata=[*FIRST_TOKEN_ID]
    )
    await show_resource_balance(admin_account, resources)
    await checks_realms_balance(admin_account, realms, 1)

#########
# CALLS #
#########


async def show_resource_balance(account, resources):
    """prints resource balance"""
    for index in range(22):
        player_resource_value = await resources.balanceOf(account.contract_address, uint(index + 1)).invoke()
        if player_resource_value.result.balance[0] > 0:
            print(
                f'\033[1;33;40m🔥 | Resource {index + 1} balance is: {player_resource_value.result.balance[0]}')


async def show_lords_balance(account, lords):
    """claims lords"""
    player_lords_value = await lords.balanceOf(account.contract_address).invoke()
    print(
        f'\n \033[1;33;40m👛 | $LORDS {player_lords_value.result.balance[0]}\n')
    assert player_lords_value.result.balance[0] == STAKED_DAYS * LORDS_RATE


async def claim_resources(account, resources_logic, token):
    """claims resources"""
    await signer.send_transaction(
        account=account, to=resources_logic.contract_address, selector_name='claim_resources', calldata=[*token]
    )


async def checks_realms_balance(account, realms, assert_value):
    """check realms balance"""
    balance_of = await realms.balanceOf(account.contract_address).invoke()
    assert balance_of.result.balance[0] == assert_value
    print(
        f'🏰 | Realms Balance: {balance_of.result.balance[0]}\n')


async def set_realm_meta(account, realms, token):
    """set realm metadata"""
    await signer.send_transaction(
        account, realms.contract_address, 'set_realm_data', [
            *token, map_realm(json_realms[str(from_uint(token))])]
    )


async def mint_realm(account, realms, token):
    """mint realm"""
    await signer.send_transaction(
        account, realms.contract_address, 'mint', [
            account.contract_address, *token]
    )


async def settle_realm(account, settling_logic, token):
    """settle realm"""
    await signer.send_transaction(
        account=account, to=settling_logic.contract_address, selector_name='settle', calldata=[*token]
    )
