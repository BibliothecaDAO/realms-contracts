import pytest
import asyncio
import random
from fixtures.account import account_factory
from utils import Signer, uint, str_to_felt, MAX_UINT256, assert_revert
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.definitions.error_codes import StarknetErrorCode

# Params
BASE_URI = str_to_felt('https://realms.digital/token/')
MAX_AMOUNT = 8000

# bools (for readability)
false = 0
true = 1

first_token_id = (5042, 0)
second_token_id = (7921, 1)
third_token_id = (0, 13)
fourth_token_id = (232, 3453)
fifth_token_id = (234, 345)
sixth_token_id = (9999, 9999)

signer = Signer(123456789987654321)
user_signer = Signer(123456789987654322)

transfer_amount = 1000
fee_bips = 500
initial_supply = 1000000

@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()

async def _erc20_approve(ctx, currency_address, marketplace_address, account, amount):
    await ctx.send_transaction(
        account, currency_address, 'approve', [
            marketplace_address, *uint(amount)
        ]
    )


@pytest.fixture(scope='module')
async def marketplace_factory():
    starknet = await Starknet.empty()

    account = await starknet.deploy(
        "contracts/Account.cairo",
        constructor_calldata=[signer.public_key]
    )

    # The Controller is the only unchangeable contract.
    # First deploy Arbiter.
    # Then send the Arbiter address during Controller deployment.
    # Then save the controller address in the Arbiter.
    # Then deploy Controller address during module deployments.
    lords = await starknet.deploy(
        source="contracts/token/ERC20.cairo",
        constructor_calldata=[
            str_to_felt("Lords"),     # name
            str_to_felt("LRD"),       # symbol
            *uint(initial_supply),                # initial supply
            account.contract_address  # recipient])
        ]
    )
    realms = await starknet.deploy(
        source="contracts/token/ERC721.cairo",
        constructor_calldata=[
            str_to_felt("Realms (for Adventurers)"),  # name
            str_to_felt("Realm"),                 # ticker
            BASE_URI,                           # base_uri
            account.contract_address,           # contract_owner
        ])

    marketplace = await starknet.deploy(
        source="contracts/nft_marketplace/bibliotheca_marketplace.cairo",
        constructor_calldata=[
            lords.contract_address,         # currency token address
            realms.contract_address               # nft address
        ])

    return starknet, account, lords, realms, marketplace


#
# Mint Realms to User
#


@pytest.mark.asyncio
@pytest.mark.parametrize('tokens, number_of_tokens', [
    [first_token_id, 1],
    [second_token_id, 2],
    [third_token_id, 3],
])
async def test_mint(marketplace_factory, tokens, number_of_tokens):
    _, account, _, realms, _ = marketplace_factory

    await signer.send_transaction(
        account, realms.contract_address, 'mint', [
            account.contract_address, *tokens]
    )

    execution_info = await realms.balanceOf(account.contract_address).call()
    print(f'Realms Balance for user is: {str(execution_info.result.balance)}')

    assert execution_info.result == (uint(number_of_tokens),)


#
# Open Trade with user
#


@pytest.mark.asyncio
async def test_open_trade(marketplace_factory):
    _, account, _, realms, marketplace = marketplace_factory

    await signer.send_transaction(
        account, realms.contract_address, 'setApprovalForAll', [
            marketplace.contract_address, true]
    )

    await signer.send_transaction(
        account, marketplace.contract_address, 'open_trade', [
            *first_token_id, 420, 1221542]
    )

    #Require Trade Counter To Increase
    trade_counter = await marketplace.get_trade_counter().call()
    assert trade_counter.result == (1,)

    trade = await marketplace.get_trade(0).call()
    print(f'New Trade was: {trade.result}')

@pytest.mark.asyncio
async def test_execute_trade(marketplace_factory):
    starknet, account, lords, realms, marketplace = marketplace_factory

    purchaser = await starknet.deploy(
        "contracts/Account.cairo",
        constructor_calldata=[user_signer.public_key]
    )
    
    await signer.send_transaction(
        account, lords.contract_address, 'transfer', [
            purchaser.contract_address, *uint(transfer_amount)
        ]
    )

    await _erc20_approve(user_signer, lords.contract_address, marketplace.contract_address, purchaser, 1000)

    await user_signer.send_transaction(
        purchaser, marketplace.contract_address, 'execute_trade', [
            0]
    )

    #Require Trade Status to change
    trade_status = await marketplace.get_trade_status(0).call()
    print(f'Trade status execution: {trade_status.result.status}')

    trade_item = await marketplace.get_trade_item(0).call()
    print(f'Trade item execution: {trade_item.result.item}')

    item_owner_of = await realms.ownerOf(trade_item.result.item).call()
    print(f'Owner after execution: {item_owner_of.result.owner}')

    purchaser_currency_balance = await lords.balanceOf(purchaser.contract_address).call()
    print(f'Purchaser balance after execution: {purchaser_currency_balance.result.balance}')

    account_currency_balance = await lords.balanceOf(account.contract_address).call()
    print(f'Account balance after execution: {account_currency_balance.result.balance}')

    trade_result = await marketplace.get_trade(0).call()
    print(f'Trade status execution: {trade_result.result.trade}')

    fee = int(trade_result.result.trade.price * fee_bips / 10000)
    print(f'Fee is {fee}')
    #Require Trade status to change to Executed
    assert trade_status.result.status == 1

    #Require purchaser to be the owner of Item from trade
    assert item_owner_of.result.owner == purchaser.contract_address

    #Require purchaser balance to have decresase by trade price
    assert purchaser_currency_balance.result.balance == uint(transfer_amount - trade_result.result.trade.price)

    #Require seller balance to have increase by trade price less fee
    assert account_currency_balance.result.balance == uint(initial_supply - transfer_amount + trade_result.result.trade.price - fee)

@pytest.mark.asyncio
async def test_cancel_trade(marketplace_factory):
    _, account, _, realms, marketplace = marketplace_factory


    await signer.send_transaction(
        account, marketplace.contract_address, 'open_trade', [
            *second_token_id, 420, 1221542]
    )

    trade_counter = await marketplace.get_trade_counter().call()

    await signer.send_transaction(
        account, marketplace.contract_address, 'cancel_trade', [
            trade_counter.result.trade_counter - 1]
    )

    #Require Trade status to change to Cancelled
    trade_status = await marketplace.get_trade_status(trade_counter.result.trade_counter - 1).call()
    assert trade_status.result.status == 2
