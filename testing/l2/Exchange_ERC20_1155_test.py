import pytest
import math
from utils import uint

@pytest.fixture(scope='module')
async def exchange_factory(ctx_factory):
    print("Constructing exchange factory")
    ctx = ctx_factory()

    exchange = await ctx.starknet.deploy(
        source="contracts/exchange/Exchange_ERC20_1155.cairo",
        constructor_calldata=[
            ctx.lords.contract_address,
            ctx.resources.contract_address,
        ]
    )

    ctx.exchange = exchange

    return ctx


@pytest.mark.asyncio
async def test_check_addr(exchange_factory):
    print("test_check_addr")
    ctx = exchange_factory
    exchange = ctx.exchange

    res = await exchange.get_currency_address().call()
    assert res.result.currency_address == (ctx.lords.contract_address)

    res = await exchange.get_token_address().call()
    assert res.result.token_address == (ctx.resources.contract_address)


async def set_erc20_allowance(signer, account, erc20, who, amount):
    await signer.send_transaction(
        account,
        erc20.contract_address,
        'approve',
        [who, *uint(amount)]
    )

async def provide_liq(admin_signer, admin_account, exchange, lords, resources, max_currency, token_spent):
    # Approve access
    await set_erc20_allowance(admin_signer, admin_account, lords, exchange.contract_address, max_currency)
    await admin_signer.send_transaction(
        admin_account,
        resources.contract_address,
        'setApprovalForAll',
        [exchange.contract_address, True]
    )

    # Provide liquidity
    await admin_signer.send_transaction(
        admin_account,
        exchange.contract_address,
        'add_liquidity',
        [*uint(max_currency), 1, token_spent]
    )


async def get_token_bals(account, lords, resources):
    """ Get the current balances. """
    res = await lords.balanceOf(account.contract_address).call()
    before_lords_bal = res.result.balance
    res = await resources.balanceOf(account.contract_address, 1).call()
    before_resources_bal = res.result.balance
    return before_lords_bal, before_resources_bal


@pytest.mark.asyncio
async def xtest_add_liquidity(exchange_factory):
    print("test_add_liquidity")
    ctx = exchange_factory
    admin_signer = ctx.signers['admin']
    admin_account = ctx.admin
    exchange = ctx.exchange
    lords = ctx.lords
    resources = ctx.resources
    max_currency = 10000
    token_spent = 1000

    # Before states
    before_lords_bal, before_resources_bal = await get_token_bals(admin_account, lords, resources)

    # Do it
    await provide_liq(admin_signer, admin_account, exchange, lords, resources, max_currency, token_spent)

    # After states
    after_lords_bal, after_resources_bal = await get_token_bals(admin_account, lords, resources)
    assert uint(before_lords_bal[0] - max_currency) == after_lords_bal
    assert before_resources_bal - token_spent == after_resources_bal
    # Contract balances
    exchange_lords_bal, exchange_resources_bal = await get_token_bals(exchange, lords, resources)
    assert exchange_lords_bal == uint(max_currency)
    assert exchange_resources_bal == token_spent
    # Check LP tokens
    res = await exchange.balanceOf(admin_account.contract_address, 1).call()
    assert res.result.balance == max_currency


def calc_price(old_x, old_y, d_y):
    """ Find the new value of x in a x*y=k equation given dy. """
    k = old_x * old_y
    new_x = k / (old_y - d_y)
    d_x = new_x - old_x
    return math.floor(d_x)


@pytest.mark.asyncio
async def test_price(exchange_factory):
    print("test_price")
    ctx = exchange_factory
    admin_signer = ctx.signers['admin']
    admin_account = ctx.admin
    exchange = ctx.exchange
    lords = ctx.lords
    resources = ctx.resources
    currency_reserve = 10000
    token_reserve = 1000
    token_to_buy = 10

    await provide_liq(admin_signer, admin_account, exchange, lords, resources, currency_reserve, token_reserve)
    before_lords_bal, before_resources_bal = await get_token_bals(admin_account, lords, resources)

    currency_diff_required = calc_price(currency_reserve, token_reserve, token_to_buy)

    # Check price math
    res = await exchange.get_buy_price(uint(token_to_buy), uint(currency_reserve), uint(token_reserve)).call()
    assert res.result.price == uint(currency_diff_required)

    # Make purchase
    usable_currency = currency_diff_required + 100 # Increment max currency to ensure correct buy price is used
    await set_erc20_allowance(admin_signer, admin_account, lords, exchange.contract_address, usable_currency)
    await admin_signer.send_transaction(
        admin_account,
        exchange.contract_address,
        'buy_tokens',
        [
            *uint(usable_currency),
            1,
            token_to_buy,
        ]
    )
    after_lords_bal, after_resources_bal = await get_token_bals(admin_account, lords, resources)
    assert uint(before_lords_bal[0] - currency_diff_required) == after_lords_bal
    assert before_resources_bal + token_to_buy == after_resources_bal
