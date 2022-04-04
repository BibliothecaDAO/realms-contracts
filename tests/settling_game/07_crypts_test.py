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
wonder_token_id = uint(839)

# BUILDING UPGRADE
building_id = 1

# 1.5 * 7 Days
stake_time = 129600 * 7


@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_mint_realm(game_factory):
    admin_account, treasury_account, starknet, accounts, signers, arbiter, controller, settling_logic, settling_state, realms, resources, lords, resources_logic, resources_state, s_realms, buildings_logic, buildings_state, calculator_logic = game_factory

    #################
    # VALUE SETTERS #
    #################

    await signer.send_transaction(
        account=admin_account, to=resources.contract_address, selector_name='mintBatch', calldata=[admin_account.contract_address, 5, *uint(1), *uint(2), *uint(3), *uint(4), *uint(5), 5, *uint(100), *uint(100), *uint(100), *uint(100), *uint(100)]
    )

    # TODO: Set CRYPTS
    # METADATA
    await signer.send_transaction(
        admin_account, realms.contract_address, 'set_realm_data', [
            *first_token_id, map_realm(json_realms['1'])]
    )
    # WONDER REALM METADATA
    await signer.send_transaction(
        admin_account, realms.contract_address, 'set_realm_data', [
            *wonder_token_id, map_realm(json_realms['839'])]
    )
    ########
    # MINT #
    ########

    await signer.send_transaction(
        admin_account, realms.contract_address, 'mint', [
            admin_account.contract_address, *first_token_id]
    )

    # TODO: Mint CRYPTS
    # print realm details
    realm_info = await realms.get_realm_info(first_token_id).invoke()
    print(f'\033[1;33;40m🏰 | Realm metadata: {realm_info.result.realm_data}\n')
    unpacked_realm_info = await realms.fetch_realm_data(first_token_id).invoke()
    print(
        f'\033[1;33;40m🏰 | Realm unpacked: {unpacked_realm_info.result.realm_stats}\n')

    # check balance of Realm on account
    balance_of = await realms.balanceOf(admin_account.contract_address).invoke()
    assert balance_of.result.balance[0] == 2
    print(f'🏰 | Balance of Realms: {balance_of.result.balance[0]}\n')

    # set approval for Settling contract to use Realm
    await signer.send_transaction(
        account=admin_account, to=realms.contract_address, selector_name='setApprovalForAll', calldata=[settling_logic.contract_address, 1]
    )

    ##########
    # SETTLE #
    ##########

    await signer.send_transaction(
        account=admin_account, to=settling_logic.contract_address, selector_name='settle', calldata=[*first_token_id]
    )
    await signer.send_transaction(
        account=admin_account, to=settling_logic.contract_address, selector_name='settle', calldata=[*wonder_token_id]
    )
    print(f'\033[2;31🏰 Settling Realm...\n')

    # check transfer
    balance_of = await realms.balanceOf(admin_account.contract_address).invoke()
    assert balance_of.result.balance[0] == 0
    print(
        f'🏰 Realms Balance for owner after Staking: {balance_of.result.balance[0]}\n')

    # increments time by 1.5 days to simulate stake
    set_block_timestamp(starknet.state, round(time.time()) + stake_time)

    #####################
    # RESOURCES & LORDS #
    #####################

    # CLAIM RESOURCES
    await signer.send_transaction(
        account=admin_account, to=resources_logic.contract_address, selector_name='claim_resources', calldata=[*first_token_id]
    )
    for index in range(29):
        player_resource_value = await resources.balanceOf(admin_account.contract_address, uint(index + 1)).invoke()
        print(
            f'\033[1;33;40m🔥 Resource {index + 1} balance is: {player_resource_value.result.balance[0]}')

    ##################
    # UNSETTLE REALM #
    ##################

    # TODO: ALLOW SETTLING LOGIC TO TRANSFER REALMS FROM STATE
    # await signer.send_transaction(
    #     account=admin_account, to=settling_logic.contract_address, selector_name='unsettle', calldata=[*uint(5042)]
    # )

    # # CHECK
    # balance_of = await realms.balanceOf(admin_account.contract_address).invoke()
    # assert balance_of.result.balance[0] == 1
    # print(
    #     f'🏰 Realms Balance for owner after Staking: {balance_of.result.balance[0]}\n')
