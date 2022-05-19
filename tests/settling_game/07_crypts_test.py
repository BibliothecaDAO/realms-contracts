import pytest
import asyncio
import json
from openzeppelin.tests.utils import Signer, uint, str_to_felt, from_uint, felt_to_str
import time
from enum import IntEnum

from realms_cli.realms_cli.binary_converter import map_crypt

from .game_structs import BUILDING_COSTS, RESOURCE_UPGRADE_COST

from tests.conftest import set_block_timestamp

crypts_data = json.load(open('data/crypts.json'))

environments = json.load(open("data/crypts_environments.json"))

affinities = json.load(open("data/crypts_affinities.json"))


# ACCOUNTS
NUM_SIGNING_ACCOUNTS = 2
signer = Signer(123456789987654321)

# LORDS SUPPLY
INITIAL_SUPPLY = 1000000 * (10 ** 18)

# CRYPTS TOKENS TO MINT
FIRST_TOKEN_ID = uint(1)

# 1.5 * 7 Days
DAYS = 1800
STAKED_DAYS = 7

RESOURCES = 100
STAKE_TIME = DAYS * STAKED_DAYS
RESOURCE_ID = 2


@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_mint_crypt(game_factory):
    admin_account, treasury_account, starknet, accounts, signers, arbiter, controller, settling_logic, realms, resources, lords, resources_logic, s_realms, buildings_logic, calculator_logic, crypts, s_crypts, crypts_logic, crypts_resources_logic = game_factory

    #################
    # VALUE SETTERS #
    #################

    # IMPORT CRYPTS METADATA (so we can mint)
    await set_crypt_meta(admin_account, crypts, FIRST_TOKEN_ID)

    ########
    # MINT #
    ########

    await mint_crypt(admin_account, crypts, FIRST_TOKEN_ID)

    # print crypt details
    crypt_info = await crypts.get_crypt_info(FIRST_TOKEN_ID).invoke()
    print(f'\033[1;33;40m🏰 | Crypt metadata: {crypt_info.result.crypt_data}\n')

    unpacked_crypt_info = await crypts.fetch_crypt_data(FIRST_TOKEN_ID).invoke()
    print(
        f'\033[1;33;40m🏰 | Crypt unpacked: {unpacked_crypt_info.result.crypt_stats}\n')

    # check balance of Crypt on account
    await checks_crypts_balance(admin_account, crypts, 1)   # Check that we've minted one

    # set approval for Crypts Logic contract to use Crypts
    await signer.send_transaction(
        account=admin_account, to=crypts.contract_address, selector_name='setApprovalForAll', calldata=[crypts_logic.contract_address, 1]
    )

    ##########
    # SETTLE #
    ##########

    print(f'\033[2;31🏰 Settling Cryptm...\n')
    await settle_crypt(admin_account, crypts_logic, FIRST_TOKEN_ID)

    # check transfer
    await checks_crypts_balance(admin_account, crypts, 0)   # We settled and don't have any crypts (only s_crypts)

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
            *token, map_crypt(
                crypts_data[str(from_uint(token))], environments, affinities)]
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
