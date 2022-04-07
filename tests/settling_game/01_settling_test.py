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
initial_supply = 1000000 * (10 ** 18)

# REALM TOKENS TO MINT
first_token_id = uint(1)
wonder_token_id = uint(839)

# 1.5 * 7 Days
DAYS = 86400
STAKED_DAYS = 7

LORDS_RATE = 25
RESOURCES = 100
stake_time = DAYS * STAKED_DAYS
building_id = 1


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

    # # APPROVE RESOURCE CONTRACT FOR LORDS TRANSFERS - SET AT FULL SUPPLY TODO: NEEDS MORE SECURE SYSTEM
    await signers[1].send_transaction(
        account=treasury_account, to=lords.contract_address, selector_name='approve', calldata=[resources_logic.contract_address, *uint(initial_supply)]
    )

    # RESOURCES
    # SET VALUES (ids,cost) AT 1,2,3,4,5,10,10,10,10,10
    await signer.send_transaction(
        account=admin_account, to=storage.contract_address, selector_name='set_resource_upgrade_value', calldata=[5, 47408855671140352459265]
    )

    # BUILDING 1 IDS 1,2,3,4,5
    await signer.send_transaction(
        account=admin_account, to=storage.contract_address, selector_name='set_building_cost_ids', calldata=[building_id, 21542142465]
    )

    # BUILDING 1 VALUES 10,10,10,10,10
    await signer.send_transaction(
        account=admin_account, to=storage.contract_address, selector_name='set_building_cost_values', calldata=[building_id, 2815437129687050]
    )

    # REALM METADATA

    await set_realm_meta(admin_account, realms, first_token_id)
    await set_realm_meta(admin_account, realms, wonder_token_id)

    ########
    # MINT #
    ########

    await mint_realm(admin_account, realms, first_token_id)
    await mint_realm(admin_account, realms, wonder_token_id)

    # print realm details
    realm_info = await realms.get_realm_info(first_token_id).invoke()
    print(f'\033[1;33;40m🏰 | Realm metadata: {realm_info.result.realm_data}\n')
    assert realm_info.result.realm_data == map_realm(
        json_realms[str(from_uint(first_token_id))])

    unpacked_realm_info = await realms.fetch_realm_data(first_token_id).invoke()
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
    await settle_realm(admin_account, settling_logic, first_token_id)
    await settle_realm(admin_account, settling_logic, wonder_token_id)

    # check transfer
    await checks_realms_balance(admin_account, realms, 0)

    # # increments time by 1.5 days to simulate stake
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

    tax_percentage_info = await calculator_logic.calculate_wonder_tax().call()
    print(
        f'\033[1;31;40m😊 Wonder Tax {tax_percentage_info.result.tax_percentage}\n')

    #####################
    # RESOURCES & LORDS #
    #####################

    # CLAIM RESOURCES
    await claim_resources(admin_account, resources_logic, first_token_id)

    await show_resource_balance(admin_account, resources)

    await show_lords_balance(admin_account, lords)

    # # UPGRADE RESOURCE
    print(
        f'\n \033[1;33;40m🔥 Upgrading Resource.... 🔥\n')

    await signer.send_transaction(
        account=admin_account, to=resources_logic.contract_address, selector_name='upgrade_resource', calldata=[*first_token_id, 5]
    )

    await show_resource_balance(admin_account, resources)

    # increment another time so more resource accure
    set_block_timestamp(starknet.state, round(time.time()) + stake_time)

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
        account=admin_account, to=buildings_logic.contract_address, selector_name='build', calldata=[*first_token_id, building_id])

    values = await buildings_logic.fetch_buildings_by_type(first_token_id).call()

    print(
        f'Realm {first_token_id} buildings: {values.result.realm_buildings}')

    ##################
    # UNSETTLE REALM #
    ##################

    await signer.send_transaction(
        account=admin_account, to=settling_logic.contract_address, selector_name='unsettle', calldata=[*first_token_id]
    )
    await show_resource_balance(admin_account, resources)
    await checks_realms_balance(admin_account, realms, 1)

#########
# CALLS #
#########


async def show_resource_balance(admin_account, resources):
    """prints resource balance"""
    for index in range(22):
        player_resource_value = await resources.balanceOf(admin_account.contract_address, uint(index + 1)).invoke()
        if player_resource_value.result.balance[0] > 0:
            print(
                f'\033[1;33;40m🔥 | Resource {index + 1} balance is: {player_resource_value.result.balance[0]}')


async def show_lords_balance(admin_account, lords):
    """claims lords"""
    player_lords_value = await lords.balanceOf(admin_account.contract_address).invoke()
    print(
        f'\n \033[1;33;40m👛 | $LORDS {player_lords_value.result.balance[0]}\n')
    assert player_lords_value.result.balance[0] == STAKED_DAYS * LORDS_RATE


async def claim_resources(admin_account, resources_logic, token):
    """claims resources"""
    await signer.send_transaction(
        account=admin_account, to=resources_logic.contract_address, selector_name='claim_resources', calldata=[*token]
    )


async def checks_realms_balance(admin_account, realms, assert_value):
    """check realms balance"""
    balance_of = await realms.balanceOf(admin_account.contract_address).invoke()
    assert balance_of.result.balance[0] == assert_value
    print(
        f'🏰 | Realms Balance: {balance_of.result.balance[0]}\n')


async def set_realm_meta(admin_account, realms, token):
    """set realm metadata"""
    await signer.send_transaction(
        admin_account, realms.contract_address, 'set_realm_data', [
            *token, map_realm(json_realms[str(from_uint(token))])]
    )


async def mint_realm(admin_account, realms, token):
    """mint realm"""
    await signer.send_transaction(
        admin_account, realms.contract_address, 'mint', [
            admin_account.contract_address, *token]
    )


async def settle_realm(admin_account, settling_logic, token):
    """settle realm"""
    await signer.send_transaction(
        account=admin_account, to=settling_logic.contract_address, selector_name='settle', calldata=[*token]
    )
