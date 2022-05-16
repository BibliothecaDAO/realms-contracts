import pytest
import asyncio
import json
from openzeppelin.tests.utils import Signer, uint, str_to_felt, from_uint, felt_to_str
import time
from enum import IntEnum

from realms_cli.realms_cli.binary_converter import map_realm

from .game_structs import BUILDING_COSTS, RESOURCE_UPGRADE_COST

from tests.conftest import set_block_timestamp

crypts_data = json.load(open('data/crypts.json'))

resources = json.load(open('data/resources.json'))

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
async def test_mint_crypt(game_factory):
    admin_account, treasury_account, starknet, accounts, signers, arbiter, controller, settling_logic, realms, resources, lords, resources_logic, s_realms, buildings_logic, calculator_logic, crypts, s_crypts, crypts_logic, crypts_resources_logic = game_factory

    #################
    # VALUE SETTERS #
    #################

    await signer.send_transaction(
        account=admin_account, to=resources.contract_address, selector_name='mintBatch', calldata=[admin_account.contract_address, 10, *uint(1), *uint(2), *uint(3), *uint(4), *uint(5), *uint(6), *uint(7), *uint(8), *uint(9), *uint(10), 10, *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500)]
    )

    # APPROVE RESOURCE CONTRACT FOR LORDS TRANSFERS - SET AT FULL SUPPLY TODO: NEEDS MORE SECURE SYSTEM
    # await signers[1].send_transaction(
    #     account=treasury_account, to=lords.contract_address, selector_name='approve', calldata=[resources_logic.contract_address, *uint(INITIAL_SUPPLY)]
    # )

    # await signer.send_transaction(
    #     account=admin_account, to=lords.contract_address, selector_name='approve', calldata=[buildings_logic.contract_address, *uint(INITIAL_SUPPLY)]
    # )
    
    # await signers[1].send_transaction(
    #     account=treasury_account, to=lords.contract_address, selector_name='approve', calldata=[settling_logic.contract_address, *uint(INITIAL_SUPPLY)]
    # )

    # RESOURCE COSTS

    # for resource_id, resource_cost in RESOURCE_UPGRADE_COST.items():
    #     await signer.send_transaction(
    #         account=admin_account, to=resources_logic.contract_address, selector_name='set_resource_upgrade_cost', calldata=[resource_id.value, resource_cost.resource_count, resource_cost.bits, resource_cost.packed_ids, resource_cost.packed_amounts]
    #     )
    # for building_id, building_cost in BUILDING_COSTS.items():
    #     await signer.send_transaction(
    #         account=admin_account, to=buildings_state.contract_address, selector_name='set_building_cost', calldata=[building_id.value, building_cost.resource_count, building_cost.bits, building_cost.packed_ids, building_cost.packed_amounts, *uint(building_cost.lords)]
    #     )

    # IMPORT CRYPTS METADATA (so we can mint)
    await set_crypt_meta(admin_account, crypts, FIRST_TOKEN_ID)

    ########
    # MINT #
    ########

    await mint_crypt(admin_account, crypts, FIRST_TOKEN_ID)

    # print crypt details
    crypt_info = await realms.get_crypt_info(FIRST_TOKEN_ID).invoke()
    print(f'\033[1;33;40m🏰 | Crypt metadata: {crypt_info.result.crypt_data}\n')

    unpacked_crypt_info = await crypts.fetch_crypt_data(FIRST_TOKEN_ID).invoke()
    print(
        f'\033[1;33;40m🏰 | Crypt unpacked: {unpacked_crypt_info.result.crypt_stats}\n')

    # check balance of Crypt on account
    await checks_crypts_balance(admin_account, crypts, 2)

    # set approval for Settling contract to use Realm
    await signer.send_transaction(
        account=admin_account, to=crypts.contract_address, selector_name='setApprovalForAll', calldata=[crypts_logic.contract_address, 1]
    )

    ##########
    # SETTLE #
    ##########

    print(f'\033[2;31🏰 Settling Cryptm...\n')
    await settle_crypt(admin_account, crypts_logic, FIRST_TOKEN_ID)

    # check transfer
    await checks_crypts_balance(admin_account, crypts, 0)

    # # increments time by 1.5 days to simulate stake
    set_block_timestamp(starknet.state, round(time.time()) + STAKE_TIME)


    #############
    # RESOURCES #
    #############

    # CLAIM RESOURCES
    await claim_resources(admin_account, crypts_resources_logic, FIRST_TOKEN_ID)

    await show_resource_balance(admin_account, resources)

    # # # UPGRADE RESOURCE
    # print(
    #     f'\n \033[1;33;40m🔥 Upgrading Resource.... 🔥\n')

    # await signer.send_transaction(
    #     account=admin_account, to=resources_logic.contract_address, selector_name='upgrade_resource', calldata=[*FIRST_TOKEN_ID, RESOURCE_ID]
    # )

    # await show_resource_balance(admin_account, resources)

    # increment another time so more resource accure
    set_block_timestamp(starknet.state, round(
        time.time()) + STAKE_TIME * 2)

    await claim_resources(admin_account, crypts_resources_logic, FIRST_TOKEN_ID)

    await show_resource_balance(admin_account, resources)

    ##################
    # UNSETTLE CRYPT #
    ##################

    await signer.send_transaction(
        account=admin_account, to=crypts_logic.contract_address, selector_name='unsettle', calldata=[*FIRST_TOKEN_ID]
    )
    await show_resource_balance(admin_account, resources)
    await checks_crypts_balance(admin_account, crypts, 1)

#########
# CALLS #
#########


async def show_resource_balance(account, resources):
    """prints resource balance"""
    for index in range(28):
        player_resource_value = await resources.balanceOf(account.contract_address, uint(index + 1)).invoke()
        if player_resource_value.result.balance[0] > 0:
            print(
                f'\033[1;33;40m🔥 | Resource {index + 1} balance is: {player_resource_value.result.balance[0]}')


async def claim_resources(account, crypts_resources_logic, token):
    """claims resources"""
    await signer.send_transaction(
        account=account, to=crypts_resources_logic.contract_address, selector_name='claim_resources', calldata=[*token]
    )


async def checks_crypts_balance(account, crypts, assert_value):
    """check crypts balance"""
    balance_of = await crypts.balanceOf(account.contract_address).invoke()
    assert balance_of.result.balance[0] == assert_value
    print(
        f'☠️ | Crypts Balance: {balance_of.result.balance[0]}\n')


async def set_crypt_meta(account, crypts, token):
    """set crypts metadata"""
    await signer.send_transaction(
        account, crypts.contract_address, 'set_crypt_data', [
            *token, map_realm(  ## TODO: Update map_realm to support crypts (via json)
        crypts_data[str(from_uint(token))], environment)]
    )


async def mint_crypt(account, crypts, token):
    """mint crypt"""
    await signer.send_transaction(
        account, crypts.contract_address, 'mint', [
            account.contract_address, *token]
    )


async def settle_crypt(account, crypts_logic, token):
    """settle crypt"""
    await signer.send_transaction(
        account=account, to=crypts_logic.contract_address, selector_name='settle', calldata=[*token]
    )
