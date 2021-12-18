import pytest
import asyncio
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

transfer_amount = 500 * (10 ** 18)
fee_bips = 500
initial_supply = 1000000  * (10 ** 18)

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
    accounts = []
    
    account = await starknet.deploy(
        "contracts/Account.cairo",
        constructor_calldata=[signer.public_key]
    )
    accounts.append(account)
    purchaser = await starknet.deploy(
        "contracts/Account.cairo",
        constructor_calldata=[user_signer.public_key]
    )
    accounts.append(purchaser)

    # The Controller is the only unchangeable contract.
    # First deploy Arbiter.
    # Then send the Arbiter address during Controller deployment.
    # Then save the controller address in the Arbiter.
    # Then deploy Controller address during module deployments.
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
        source="contracts/token/ERC721_Mintable.cairo",
        constructor_calldata=[
            str_to_felt("Realms"),  # name
            str_to_felt("Realms"),                 # ticker
            accounts[0].contract_address,           # contract_owner
        ])

    marketplace = await starknet.deploy(
        source="contracts/nft_marketplace/bibliotheca_marketplace.cairo",
        constructor_calldata=[
            lords.contract_address,         # currency token address
            realms.contract_address               # nft address
        ])

    return starknet, accounts, lords, realms, marketplace

#
# Set Realms Currency Address
#

@pytest.mark.asyncio

async def test_update_currency_token(marketplace_factory):
    _, accounts, lords, realms, _ = marketplace_factory

    await signer.send_transaction(
        accounts[0], realms.contract_address, 'update_currency_token', [
            lords.contract_address]
    )

    execution_info = await realms.get_currency_token().call()
    print(f'Realms Currency Address is: {execution_info.result.currency_token_address}')

    assert execution_info.result.currency_token_address == lords.contract_address

#
# Mint Realms to Owner
#
@pytest.mark.asyncio
@pytest.mark.parametrize('tokens, number_of_tokens', [
    [first_token_id, 1],
    [second_token_id, 2],
    [third_token_id, 3],
])

async def test_mint(marketplace_factory, tokens, number_of_tokens):
    _, accounts, _, realms, _ = marketplace_factory

    token_index = number_of_tokens - 1
    execution_info = await realms.token_at_index(accounts[0].contract_address, token_index).call()
    print(f'Token at Index {token_index} before mint: {execution_info.result.token}')

    await signer.send_transaction(
        accounts[0], realms.contract_address, 'mint', [
            accounts[0].contract_address, *tokens]
    )

    execution_info = await realms.balanceOf(accounts[0].contract_address).call()
    print(f'Realms Balance for owner is: {execution_info.result.balance}')

    assert execution_info.result == (uint(number_of_tokens),)

    execution_info = await realms.get_all_tokens_for_owner(accounts[0].contract_address).call()
    print(f'Tokens for owner are: {execution_info.result.tokens}')

    execution_info = await realms.token_at_index(accounts[0].contract_address, token_index).call()
    print(f'Token at Index: {execution_info.result.token}')

#
# Mint user lords and approve realms to spend
#
@pytest.mark.asyncio

async def test_user_mint_lords_approve_realms(marketplace_factory):
    _, accounts, lords, realms, _ = marketplace_factory

    await user_signer.send_transaction(
        accounts[1], lords.contract_address, 'publicMint', [
            *uint(transfer_amount)
        ]
    )
    await user_signer.send_transaction(
        accounts[1], lords.contract_address, 'approve', [
            realms.contract_address, *uint(transfer_amount)]
    )


@pytest.mark.asyncio
@pytest.mark.parametrize('user_tokens, number_of_user_tokens', [
    [fourth_token_id, 1],
    [fifth_token_id, 2],
    [sixth_token_id, 3],
])
async def test_user_mint(marketplace_factory, user_tokens, number_of_user_tokens):
    _, accounts, lords, realms, marketplace = marketplace_factory

    await user_signer.send_transaction(
        accounts[1], realms.contract_address, 'publicMint', [
            *user_tokens]
    )
    execution_info = await realms.balanceOf(accounts[1].contract_address).call()
    print(f'Realms Balance for user is: {str(execution_info.result.balance)}')

    assert execution_info.result == (uint(number_of_user_tokens),)



#
# Open Trade with user
#

@pytest.mark.asyncio
async def test_open_trade(marketplace_factory):
    _, accounts, _, realms, marketplace = marketplace_factory

    await signer.send_transaction(
        accounts[0], realms.contract_address, 'setApprovalForAll', [
            marketplace.contract_address, true]
    )

    await signer.send_transaction(
        accounts[0], marketplace.contract_address, 'open_trade', [
            *first_token_id, 40 * (10 ** 18), 1221542]
    )

    #Require Trade Counter To Increase
    trade_counter = await marketplace.get_trade_counter().call()
    assert trade_counter.result == (1,)

    trade = await marketplace.get_trade(0).call()
    print(f'New Trade was: {trade.result}')


@pytest.mark.asyncio
async def test_execute_trade(marketplace_factory):
    starknet, accounts, lords, realms, marketplace = marketplace_factory

    await _erc20_approve(user_signer, lords.contract_address, marketplace.contract_address, accounts[1], 40 * (10 ** 18))

    await user_signer.send_transaction(
        accounts[1], marketplace.contract_address, 'execute_trade', [
            0]
    )
    execution_info = await realms.get_all_tokens_for_owner(accounts[1].contract_address).call()
    print(f'Tokens for purhcaser are: {execution_info.result.tokens}')

    execution_info = await realms.get_all_tokens_for_owner(accounts[0].contract_address).call()
    print(f'Tokens for seller are: {execution_info.result.tokens}')

    #Require Trade Status to change
    trade_status = await marketplace.get_trade_status(0).call()
    print(f'Trade status execution: {trade_status.result.status}')

    trade_item = await marketplace.get_trade_item(0).call()
    print(f'Trade item execution: {trade_item.result.item}')

    item_owner_of = await realms.ownerOf(trade_item.result.item).call()
    print(f'Owner after execution: {item_owner_of.result.owner}')

    purchaser_currency_balance = await lords.balanceOf(accounts[1].contract_address).call()
    print(f'accounts[1] balance after execution: {purchaser_currency_balance.result.balance}')

    seller_currency_balance = await lords.balanceOf(accounts[0].contract_address).call()
    print(f'Accounts balance after execution: {seller_currency_balance.result.balance}')

    trade_result = await marketplace.get_trade(0).call()
    print(f'Trade status execution: {trade_result.result.trade}')

    fee = int(trade_result.result.trade.price * fee_bips / 10000)
    print(f'Fee is {fee}')
    #Require Trade status to change to Executed
    assert trade_status.result.status == 1

    #Require accounts[1] to be the owner of Item from trade
    assert item_owner_of.result.owner == accounts[1].contract_address

    #Require accounts[1] balance to have decresase by trade price and 3x mint price
    assert purchaser_currency_balance.result.balance == uint(transfer_amount - trade_result.result.trade.price - (3 * 10 * (10 ** 18)))

    #Require seller balance to have increase by trade price less fee
    assert seller_currency_balance.result.balance == uint(initial_supply + trade_result.result.trade.price - fee)

@pytest.mark.asyncio
async def test_cancel_trade(marketplace_factory):
    _, accounts, _, _, marketplace = marketplace_factory


    await signer.send_transaction(
        accounts[0], marketplace.contract_address, 'open_trade', [
            *second_token_id, 40 * (10 ** 18), 1221542]
    )

    trade_counter = await marketplace.get_trade_counter().call()

    await signer.send_transaction(
        accounts[0], marketplace.contract_address, 'cancel_trade', [
            trade_counter.result.trade_counter - 1]
    )

    #Require Trade status to change to Cancelled
    trade_status = await marketplace.get_trade_status(trade_counter.result.trade_counter - 1).call()
    assert trade_status.result.status == 2
