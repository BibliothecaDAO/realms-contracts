import pytest
from tests.utils import str_to_felt, uint


# Params
BASE_URI = str_to_felt('https://realms.digital/token/')
MAX_AMOUNT = 8000

# bools (for readability)
false = 0
true = 1

fee_bips = 500

first_token_id = (23, 0)
second_token_id = (7225, 0)
third_token_id = (0, 13)
fourth_token_id = (232, 3453)
fifth_token_id = (234, 345)
sixth_token_id = (9999, 9999)
trade_cost = 40 * (10 ** 18)


async def _erc20_approve(ctx, account, contract_address, amount):
    await ctx.execute(
        account,
        ctx.lords.contract_address,
        'approve',
        [contract_address, *uint(amount)]
    )


async def _mint_realms(ctx, account, *tokens):
    await ctx.execute(
        account,
        ctx.realms.contract_address,
        'publicMint',
        [*tokens]
    )


@pytest.fixture(scope='module')
async def marketplace_factory(ctx_factory):
    ctx = ctx_factory()

    marketplace = await ctx.starknet.deploy(
        source="contracts/nft_marketplace/bibliotheca_marketplace.cairo",
        constructor_calldata=[
            ctx.lords.contract_address,
            ctx.marketplace.contract_address,
            ctx.account.contract_address         # currency token address
        ])

    ctx.marketplace = marketplace

    await _erc20_approve(ctx, "user1", ctx.marketplace.contract_address, 40 * (10 ** 18))
    await ctx.execute(
        "user1",
        ctx.realms.contract_address,
        "setApprovalForAll",
        [ctx.marketplace.contract_address, true],
    )
    await _erc20_approve(ctx, "user2", ctx.marketplace.contract_address, 40 * (10 ** 18))

    return ctx


#
# Set Realms Currency Address
#

@pytest.mark.asyncio
async def test_update_currency_token(marketplace_factory):
    ctx = marketplace_factory

    await ctx.execute(
        "admin",
        ctx.realms.contract_address,
        "set_currency_address",
        [ctx.lords.contract_address],
    )

    currency_address = (await ctx.realms.get_currency_token().call()).result.currency_token_address
    assert currency_address == ctx.lords.contract_address

#
# Test trade bitmapping
#

# @pytest.mark.asyncio
# async def test_trade_bitmapping(marketplace_factory):
#     ctx = marketplace_factory
#     testing = await ctx.fetch_trade_data() #.invoke(10,10,10)
#     print("hellO" + testing.result)

#     return ctx

# #
# # Open Trade with user
# #

# @pytest.mark.asyncio
# async def test_open_trade_and_execute(marketplace_factory):
#     ctx = marketplace_factory

#     trade_counter_initial = (await ctx.marketplace.get_trade_counter().call()).result.trade_counter

#     await ctx.execute(
#         "user1",
#         ctx.marketplace.contract_address,
#         "open_trade",
#         [ctx.realms.contract_address, *first_token_id, trade_cost, 1221542],
#     )

#     #Require Trade Counter To Increase
#     trade_counter = (await ctx.marketplace.get_trade_counter().call()).result.trade_counter
#     assert trade_counter == trade_counter_initial + 1

#     trade = (await ctx.marketplace.get_trade(trade_counter_initial).call()).result.trade
#     assert trade.status == 0
#     assert trade.price == trade_cost
#     open_trade = (await ctx.marketplace.get_open_trade_by_token(ctx.realms.contract_address, first_token_id).call()).result.trade
#     assert open_trade.idx == trade_counter_initial
#     assert open_trade.trade == trade

#     await ctx.execute(
#         "user2",
#         ctx.marketplace.contract_address,
#         "execute_trade",
#         [trade_counter_initial]
#     )

#     trade_status = (await ctx.marketplace.get_trade_status(trade_counter_initial).call()).result.status
#     trade_token_id = (await ctx.marketplace.get_trade_token_id(trade_counter_initial).call()).result.token_id
#     item_owner_of = (await ctx.realms.ownerOf(trade_token_id).call()).result.owner
#     purchaser_currency_balance = (await ctx.lords.balanceOf(ctx.user2.contract_address).call()).result.balance
#     seller_currency_balance = (await ctx.lords.balanceOf(ctx.user1.contract_address).call()).result.balance
#     trade_result = (await ctx.marketplace.get_trade(trade_counter_initial).call()).result.trade

#     fee = int(trade_result.price * fee_bips / 10000)

#     #Require Trade status to change to Executed
#     assert trade_status == 1

#     #Require user2 to be the new owner of Item from trade
#     assert item_owner_of == ctx.user2.contract_address

#     #Require user2 balance to have decresase by trade price
#     assert purchaser_currency_balance == uint(ctx.consts.INITIAL_USER_FUNDS - trade_result.price)

#     #Require seller balance to have increase by trade price less fee and 3x mint price
#     assert seller_currency_balance == uint(ctx.consts.INITIAL_USER_FUNDS + trade_result.price - fee -  (2 * ctx.consts.REALM_MINT_PRICE))

# @pytest.mark.asyncio
# async def test_cancel_trade(marketplace_factory):
#     ctx = marketplace_factory

#     await ctx.execute(
#         "user1",
#         ctx.marketplace.contract_address,
#         "open_trade",
#         [ctx.realms.contract_address, *second_token_id, trade_cost, 1221542],
#     )

#     trade_counter = (await ctx.marketplace.get_trade_counter().call()).result.trade_counter

#     await ctx.execute(
#         "user1",
#         ctx.marketplace.contract_address,
#         "cancel_trade",
#         [trade_counter - 1],
#     )

#     #Require Trade status to change to Cancelled
#     trade_status = (await ctx.marketplace.get_trade_status(trade_counter - 1).call()).result.status
#     assert trade_status == 2

#     open_trade = (await ctx.marketplace.get_open_trade_by_token(ctx.realms.contract_address, second_token_id).call()).result.trade
#     assert open_trade.idx == 0
