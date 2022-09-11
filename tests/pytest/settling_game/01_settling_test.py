import pytest
import asyncio
import json
from openzeppelin.tests.utils import Signer, uint, str_to_felt, from_uint, felt_to_str
import time
from enum import IntEnum

from realms_cli.realms_cli.binary_converter import map_realm

from .game_structs import BUILDING_COSTS, RESOURCE_UPGRADE_COST

from tests.conftest import set_block_timestamp

realms_data = json.load(open('data/realms.json'))

resources = json.load(open('data/resources.json'))

orders = json.load(open('data/orders.json'))

wonders = json.load(open('data/wonders.json'))

# ACCOUNTS
NUM_SIGNING_ACCOUNTS = 2
signer = Signer(123456789987654321)

# LORDS SUPPLY
INITIAL_SUPPLY = 1000000 * (10 ** 18)

# REALM TOKENS TO MINT
FIRST_TOKEN_ID = uint(1)
WONDER_TOKEN_ID = uint(839)

# 1.5 * 7 Days
DAYS = 1800
STAKED_DAYS = 7

LORDS_RATE = 25
RESOURCES = 100
STAKE_TIME = DAYS * STAKED_DAYS
BUILDING_ID = 8
RESOURCE_ID = 2


@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_mint_realm(game_factory):
    admin_account, treasury_account, starknet, accounts, signers, arbiter, controller, settling_logic, realms, resources, lords, resources_logic, s_realms, buildings_logic, calculator_logic, crypts, s_crypts, crypts_logic, crypts_resources_logic = game_factory

    #################
    # VALUE SETTERS #
    #################

    await signer.send_transaction(
        account=admin_account, to=resources.contract_address, selector_name='mintBatch', calldata=[admin_account.contract_address, 10, *uint(1), *uint(2), *uint(3), *uint(4), *uint(5), *uint(6), *uint(7), *uint(8), *uint(9), *uint(10), 10, *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18)]
    )

    # APPROVE RESOURCE CONTRACT FOR LORDS TRANSFERS - SET AT FULL SUPPLY TODO: NEEDS MORE SECURE SYSTEM
    await signers[1].send_transaction(
        account=treasury_account, to=lords.contract_address, selector_name='approve', calldata=[resources_logic.contract_address, *uint(INITIAL_SUPPLY)]
    )

    await signer.send_transaction(
        account=admin_account, to=lords.contract_address, selector_name='approve', calldata=[buildings_logic.contract_address, *uint(INITIAL_SUPPLY)]
    )

    await signers[1].send_transaction(
        account=treasury_account, to=lords.contract_address, selector_name='approve', calldata=[settling_logic.contract_address, *uint(INITIAL_SUPPLY)]
    )

    # RESOURCE COSTS

    for resource_id, resource_cost in RESOURCE_UPGRADE_COST.items():
        await signer.send_transaction(
            account=admin_account, to=resources_logic.contract_address, selector_name='set_resource_upgrade_cost', calldata=[resource_id.value, resource_cost.resource_count, resource_cost.bits, resource_cost.packed_ids, resource_cost.packed_amounts]
        )
    # for building_id, building_cost in BUILDING_COSTS.items():
    #     await signer.send_transaction(
    #         account=admin_account, to=buildings_state.contract_address, selector_name='set_building_cost', calldata=[building_id.value, building_cost.resource_count, building_cost.bits, building_cost.packed_ids, building_cost.packed_amounts, *uint(building_cost.lords)]
    #     )

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

    await get_resource_lords_claimable(resources_logic)

    ############
    # 😊 STATS #
    ############

    happiness = await calculator_logic.calculate_happiness(FIRST_TOKEN_ID).invoke()
    # assert happiness.result.happiness == 25
    print(f'\033[1;31;40m😊 Happiness level is {happiness.result.happiness}\n')

    culture = await calculator_logic.calculate_culture(FIRST_TOKEN_ID).invoke()
    # assert culture.result.culture == 25
    print(f'\033[1;31;40m😊 Culture level is {culture.result.culture}\n')

    food = await calculator_logic.calculate_food(FIRST_TOKEN_ID).invoke()
    # assert culture.result.culture == 25
    print(f'\033[1;31;40m😊 Culture level is {food.result.food}\n')

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

    # create building
    await signer.send_transaction(
        account=admin_account, to=buildings_logic.contract_address, selector_name='build', calldata=[*FIRST_TOKEN_ID, BUILDING_ID])

    values = await buildings_logic.get_buildings_unpacked(FIRST_TOKEN_ID).call()

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
    assert player_lords_value.result.balance[0] == STAKED_DAYS * \
        LORDS_RATE * (10 ** 18)


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


async def get_resource_lords_claimable(resource_logic):
    """check realms balance"""
    balance_of = await resource_logic.get_all_resource_claimable(FIRST_TOKEN_ID).invoke()
    print(
        f'Claimable resources: {balance_of.result}\n')


async def set_realm_meta(account, realms, token):
    """set realm metadata"""
    await signer.send_transaction(
        account, realms.contract_address, 'set_realm_data', [
            *token, map_realm(
                realms_data[str(from_uint(token))], resources, wonders, orders)]
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
