import pytest

@pytest.fixture(scope='module')
async def exchange_factory(ctx_factory):
    print("Constructing exchange factory")
    ctx = ctx_factory()

    exchange = await ctx.starknet.deploy(
        source="contracts/exchange/Exchange_ERC20_1155.cairo",
        constructor_calldata = [
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
    print(res.result)
    assert res.result.currency_address == (ctx.lords.contract_address)

    res = await exchange.get_token_address().call()
    print(res.result)
    assert res.result.token_address == (ctx.resources.contract_address)
