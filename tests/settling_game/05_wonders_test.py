import resource
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
first_wonder_id = uint(839)
second_wonder_id = uint(2771)

# 1.5 * 7 Days
DAYS = 86400
STAKED_DAYS = 7

LORDS_RATE = 25
RESOURCES = 100
stake_time = DAYS * STAKED_DAYS
building_id = 1


@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_tax_claiming(game_factory):
    admin_account, treasury_account, starknet, accounts, signers, arbiter, controller, settling_logic, settling_state, realms, resources, lords, resources_logic, resources_state, s_realms, buildings_logic, buildings_state, calculator_logic, wonders_logic, wonders_state, storage = game_factory

    #################
    # VALUE SETTERS #
    #################

    # mint wonder upkeep
    await signer.send_transaction(
        account=admin_account, to=resources.contract_address, selector_name='mintBatch', calldata=[admin_account.contract_address, 4, *uint(19), *uint(20), *uint(21), *uint(22), 4, *uint(100), *uint(100), *uint(100), *uint(100)]
    )

    # # APPROVE RESOURCE CONTRACT FOR LORDS TRANSFERS - SET AT FULL SUPPLY TODO: NEEDS MORE SECURE SYSTEM
    await signers[1].send_transaction(
        account=treasury_account, to=lords.contract_address, selector_name='approve', calldata=[resources_logic.contract_address, *uint(initial_supply)]
    )

    # set approval for Settling contract to use Realm
    await signer.send_transaction(
        account=admin_account, to=realms.contract_address, selector_name='setApprovalForAll', calldata=[settling_logic.contract_address, 1]
    )

    # set approval for resource withdrawals
    await signer.send_transaction(
        account=admin_account, to=resources.contract_address, selector_name='setApprovalForAll', calldata=[wonders_logic.contract_address, 1]
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
    await set_realm_meta(admin_account, realms, first_wonder_id)
    await set_realm_meta(admin_account, realms, second_wonder_id)

    ########
    # MINT #
    ########

    await mint_realm(admin_account, realms, first_token_id)
    await mint_realm(admin_account, realms, first_wonder_id)
    await mint_realm(admin_account, realms, second_wonder_id)

    ##########
    # SETTLE #
    ##########

    print(f'\033[2;31🏰 Settling Realms...\n')

    await settle_realm(admin_account, settling_logic, first_token_id)
    await settle_realm(admin_account, settling_logic, first_wonder_id)
    await settle_realm(admin_account, settling_logic, second_wonder_id)
    
    ########################
    # PAY WONDERTAX UPKEEP #
    ########################
    
    epoch_res = await calculator_logic.calculate_epoch().invoke()
    epoch = epoch_res.result.epoch
    print(
        f'\n \033[1;33;40m | Current epoch {epoch}\n')
        
    await pay_wonder_upkeep(admin_account, wonders_logic, epoch + 1, first_wonder_id)
    await pay_wonder_upkeep(admin_account, wonders_logic, epoch + 2, first_wonder_id)

    await show_resource_balance(admin_account, resources)
    
    # forward epoch
    set_block_timestamp(starknet.state, round(time.time()) + stake_time)

    ###################
    # CLAIM RESOURCES #
    ###################

    epoch_res = await calculator_logic.calculate_epoch().invoke()
    epoch = epoch_res.result.epoch
    print(
        f'\n \033[1;33;40m | Current epoch {epoch}\n')

    total_wonders_staked_res = await wonders_logic.fetch_updated_total_wonders_staked(epoch).invoke()
    total_wonders_staked = total_wonders_staked_res.result.amount
    print(
        f'\n \033[1;33;40m | Wonders Staked this epoch: {total_wonders_staked}\n')

    await claim_resources(admin_account, resources_logic, first_token_id)

    await show_tax_pools(wonders_state, epoch)
    await show_resource_balance(admin_account, resources)

    # forward epoch
    set_block_timestamp(starknet.state, round(time.time()) + (stake_time * 2))

    await claim_resources(admin_account, resources_logic, first_token_id)

    # forward epoch
    set_block_timestamp(starknet.state, round(time.time()) + (stake_time * 3))

    await claim_resources(admin_account, resources_logic, first_token_id)

    ####################
    # CLAIM WONDER TAX #
    ####################

    # forward epoch
    set_block_timestamp(starknet.state, round(time.time()) + (stake_time * 4))

    epoch_res = await calculator_logic.calculate_epoch().invoke()
    epoch = epoch_res.result.epoch
    print(
        f'\n \033[1;33;40m | Current epoch {epoch}\n')

    # Should only be 2 epochs worth of resources
    await show_available_tax_claim(wonders_logic, first_wonder_id)

    await claim_wonder_tax(admin_account, resources_logic, first_wonder_id)

    await show_resource_balance(admin_account, resources)

    player_resource_value = await resources.balanceOf(admin_account.contract_address, uint(2)).invoke()

    total_pre_tax_claimed = 1400 * 0.75 * 3 # token amount claimed for 3 epochs assuming tax of 25% from realm 1
    claimable_tax = ( 1400 * 0.25 * 2 ) / 2 # wonder pays 2 epochs of upkeep, divided by the staked wonders

    assert player_resource_value.result.balance[0] == (total_pre_tax_claimed + claimable_tax)

#########
# CALLS #
#########

async def show_resource_balance(admin_account, resources):
    """prints resource balance"""
    for index in range(22):
        player_resource_value = await resources.balanceOf(admin_account.contract_address, uint(index + 1)).invoke()
        print(
            f'\033[1;33;40m🔥 | Resource {index + 1} balance is: {player_resource_value.result.balance[0]}')

async def show_tax_share(wonders_logic, epoch):
    """prints resource balance"""
    resource_tax_share_res = await wonders_logic.fetch_updated_epoch_tax_share(epoch).invoke()
    for index in range(22):
        print(
            f'\033[1;33;40m🔥 | Tax Share {index + 1} balance is: {resource_tax_share_res.result.resource_claim_amounts[index][0]}')

async def show_available_tax_claim(wonders_logic, token_id):
    """prints resource balance"""
    available_tax_claim = await wonders_logic.fetch_available_tax_claim(token_id).invoke()
    for index in range(22):
        print(
            f'\033[1;33;40m🔥 | Tax Claim for {token_id} {index + 1} is: {available_tax_claim.result.resource_claim_amounts[index][0]}')

async def show_tax_pools(wonders_state, epoch):
    """prints resource balance"""
    for index in range(22):
        tax_pool = await wonders_state.get_tax_pool(epoch, uint(index+1)).invoke()
        print(
            f'\033[1;33;40m🔥 | Epoch {epoch} Taxpool for Resource {index + 1} is: {tax_pool.result.supply[0]}')


async def show_lords_balance(admin_account, lords):
    """claims lords"""
    player_lords_value = await lords.balanceOf(admin_account.contract_address).invoke()
    print(
        f'\n \033[1;33;40m👛 | $LORDS {player_lords_value.result.balance[0]}\n')
    assert player_lords_value.result.balance[0] == STAKED_DAYS * LORDS_RATE

async def show_current_epoch(calculator_logic):
    """show epoch"""
    epoch = await calculator_logic.calculate_epoch().invoke()
    print(
        f'\n \033[1;33;40m👛 | EPOCH {epoch.result.epoch}\n')


async def claim_resources(admin_account, resources_logic, token):
    """claims resources"""
    await signer.send_transaction(
        account=admin_account, to=resources_logic.contract_address, selector_name='claim_resources', calldata=[*token]
    )

async def claim_wonder_tax(admin_account, wonder_logic, token):
    """claims resources"""
    await signer.send_transaction(
        account=admin_account, to=wonder_logic.contract_address, selector_name='claim_wonder_tax', calldata=[*token]
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

async def pay_wonder_upkeep(admin_account, wonders_logic, epoch, token):
    """"""
    await signer.send_transaction(
        admin_account, wonders_logic.contract_address, 'pay_wonder_upkeep', [
            epoch, *token]
    )