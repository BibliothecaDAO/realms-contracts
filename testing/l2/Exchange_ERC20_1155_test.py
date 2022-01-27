import pytest
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


@pytest.mark.asyncio
async def test_add_liquidity(exchange_factory):
    print("test_add_liquidity")
    ctx = exchange_factory
    admin_signer = ctx.signers['admin']
    admin = ctx.admin
    exchange = ctx.exchange
    lords = ctx.lords
    resources = ctx.resources
    max_currency = 10000
    token_spent = 1000

    # Before states
    res = await lords.balanceOf(admin.contract_address).call()
    before_lords_bal = res.result.balance
    res = await resources.balanceOf(admin.contract_address, 1).call()
    before_resources_bal = res.result.balance

    # Approve access
    await admin_signer.send_transaction(
        admin,
        lords.contract_address,
        'approve',
        [exchange.contract_address, *uint(max_currency)]
    )
    await admin_signer.send_transaction(
        admin,
        resources.contract_address,
        'setApprovalForAll',
        [exchange.contract_address, True]
    )

    # Provide liquidity
    await admin_signer.send_transaction(
        admin,
        exchange.contract_address,
        'add_liquidity',
        [*uint(max_currency), 1, token_spent]
    )

    # After states
    res = await lords.balanceOf(admin.contract_address).call()
    assert uint(before_lords_bal[0] - max_currency) == res.result.balance
    res = await resources.balanceOf(admin.contract_address, 1).call()
    assert before_resources_bal - token_spent == res.result.balance
    # Contract balances
    res = await lords.balanceOf(exchange.contract_address).call()
    assert res.result.balance == uint(max_currency)
    res = await resources.balanceOf(exchange.contract_address, 1).call()
    assert res.result.balance == token_spent
