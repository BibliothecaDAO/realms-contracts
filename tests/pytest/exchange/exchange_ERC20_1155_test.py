import pytest
from fractions import Fraction
import tests.conftest as conftest
from openzeppelin.tests.utils import Signer, uint, assert_revert
from math import floor
from tests.conftest import proxy_builder, compiled_proxy
import sys

NUM_SIGNING_ACCOUNTS = 2

sys.setrecursionlimit(1500)


def expanded_uint_list(arr):
    """
    Convert array of ints into flattened array of uints.
    """
    return list(sum([uint(a) for a in arr], ()))


royalty_fee = 100


@pytest.fixture(scope='module')
async def exchange_factory(exchange_token_factory, compiled_proxy):
    print("Constructing exchange factory")

    starknet, admin_key, admin_account, treasury_account, accounts, signers, proxy_lords, proxy_resources = exchange_token_factory

    exchange = await proxy_builder(compiled_proxy, starknet, admin_key, admin_account, "contracts/exchange/Exchange_ERC20_1155.cairo", [
        proxy_lords.contract_address,
        proxy_resources.contract_address,
        *uint(100),
        *uint(100),
        admin_account.contract_address,  # Royalty receiver
        admin_account.contract_address,
    ])

    await signers[0].send_transaction(
        account=admin_account, to=proxy_resources.contract_address, selector_name='mintBatch', calldata=[admin_account.contract_address, 10, *uint(1), *uint(2), *uint(3), *uint(4), *uint(5), *uint(6), *uint(7), *uint(8), *uint(9), *uint(10), 10, *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18), *uint(500 * 10 ** 18)])

    return starknet, admin_key, admin_account, treasury_account, accounts, signers, proxy_lords, proxy_resources, exchange


# @pytest.mark.asyncio
# @pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
# async def test_check_addr(exchange_factory):
#     starknet, admin_key, admin_account, treasury_account, accounts, signers, proxy_lords, proxy_resources, exchange = exchange_factory

#     res = await exchange.get_currency_address().invoke()
#     assert res.result.currency_address == (proxy_lords.contract_address)

#     res = await exchange.get_token_address().invoke()
#     assert res.result.token_address == (proxy_resources.contract_address)

# @pytest.mark.asyncio
# @pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
# async def test_liquidity(exchange_factory):
#     print("test_liquidity")
#     starknet, admin_key, admin_account, treasury_account, accounts, signers, proxy_lords, proxy_resources, exchange = exchange_factory
#     admin_signer = signers[0]
#     admin_account = admin_account
#     exchange = exchange
#     lords = proxy_lords
#     resources = proxy_resources
#     currency_amount = 10000
#     token_spent = 1000
#     token_id = 1

#     # Before states
#     before_lords_bal, before_resources_bal = await get_token_bals(admin_account, lords, resources, token_id)

#     # Do it
#     await initial_liq(admin_signer, admin_account, exchange, lords, resources,  [currency_amount], [token_id], [token_spent])

#     # After states
#     after_lords_bal, after_resources_bal = await get_token_bals(admin_account, lords, resources, token_id)
#     assert uint(before_lords_bal[0] - currency_amount) == after_lords_bal
#     assert uint(before_resources_bal[0] - token_spent) == after_resources_bal

#     # Contract balances
#     exchange_lords_bal, exchange_resources_bal = await get_token_bals(exchange, lords, resources, token_id)
#     assert exchange_lords_bal == uint(currency_amount)
#     assert exchange_resources_bal == uint(token_spent)

#     # Check LP tokens
#     res = await exchange.balanceOf(admin_account.contract_address, uint(token_id)).invoke()
#     assert res.result.balance == uint(currency_amount)

#     # Add more liquidity using the same spread
#     await add_liq(admin_signer, admin_account, exchange, lords, resources, [currency_amount], [token_id], [token_spent], starknet)

#     # After states
#     after_lords_bal, after_resources_bal = await get_token_bals(admin_account, lords, resources, token_id)
#     assert uint(before_lords_bal[0] - (currency_amount * 2)) == after_lords_bal
#     assert uint(before_resources_bal[0] -
#                 (token_spent * 2)) == after_resources_bal

#     # Contract balances
#     exchange_lords_bal, exchange_resources_bal = await get_token_bals(exchange, lords, resources, token_id)
#     assert exchange_lords_bal == uint(currency_amount * 2)
#     assert exchange_resources_bal == uint(token_spent * 2)

#     # Check LP tokens
#     res = await exchange.balanceOf(admin_account.contract_address, uint(token_id)).invoke()
#     assert res.result.balance == uint(currency_amount * 2)

#     # Remove liquidity
#     await admin_signer.send_transaction(
#         admin_account,
#         exchange.contract_address,  # LP tokens
#         'setApprovalForAll',
#         [exchange.contract_address, True]
#     )
#     current_time = conftest.get_block_timestamp(starknet.state)
#     await admin_signer.send_transaction(
#         admin_account,
#         exchange.contract_address,
#         'remove_liquidity',
#         [
#             1,
#             *uint(currency_amount),
#             1,
#             *uint(token_id),
#             1,
#             *uint(token_spent),
#             1,
#             *uint(currency_amount),  # LP amount directly to currency_amount
#             current_time + 1000,
#         ]
#     )
#     # Cannot remove liquidity when min amounts not met
#     await assert_revert(admin_signer.send_transaction(
#         admin_account,
#         exchange.contract_address,
#         'remove_liquidity',
#         [
#             *uint(currency_amount + 100),
#             *uint(token_id),
#             *uint(token_spent),
#             *uint(currency_amount),
#             current_time + 1000,
#         ]
#     ))
#     await assert_revert(admin_signer.send_transaction(
#         admin_account,
#         exchange.contract_address,
#         'remove_liquidity',
#         [
#             *uint(currency_amount),
#             *uint(token_id),
#             *uint(token_spent + 100),
#             *uint(currency_amount),
#             current_time + 1000,
#         ]
#     ))

#     # After states
#     after_lords_bal, after_resources_bal = await get_token_bals(admin_account, lords, resources, token_id)
#     assert uint(before_lords_bal[0] - currency_amount) == after_lords_bal
#     assert uint(before_resources_bal[0] - token_spent) == after_resources_bal

#     # Contract balances
#     exchange_lords_bal, exchange_resources_bal = await get_token_bals(exchange, lords, resources, token_id)
#     assert exchange_lords_bal == uint(currency_amount)
#     assert exchange_resources_bal == uint(token_spent)

#     # Check LP tokens
#     res = await exchange.balanceOf(admin_account.contract_address, uint(token_id)).invoke()
#     assert res.result.balance == uint(currency_amount)

@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_buy_price(exchange_factory):
    print("test_buy_price")
    starknet, admin_key, admin_account, treasury_account, accounts, signers, proxy_lords, proxy_resources, exchange = exchange_factory
    admin_signer = signers[0]
    admin_account = admin_account
    currency_reserve = 10000
    token_reserve = 5000
    token_id = 2
    token_id2 = 4

    await initial_liq(admin_signer, admin_account, exchange, proxy_lords, proxy_resources,  [currency_reserve, currency_reserve], [token_id, token_id2], [token_reserve, token_reserve])
    # price = (amnt * cur_res * 1000) / ((tok_res - amnt)  * (1000 - fee))
    # price = (100 * 10000 * 1000) / ((5000 - 100) * (1000 - 100))
    # price = 227 (round up)
    await buy_and_check(starknet, admin_account, admin_signer, exchange, proxy_lords, proxy_resources, [token_id], [100], [227])
    # price = (100 * 10227 * 1000) / ((4900 - 100) * (1000 - 100))
    # price = 237 (round up)
    # Second value has same LP value, price, amounts as the first buy_and_check request
    await buy_and_check(starknet, admin_account, admin_signer, exchange, proxy_lords, proxy_resources, [token_id, token_id2], [100, 100], [237, 227])

    # Test reduced max fails
    buy_amount = 100
    exchange = exchange
    lords = proxy_lords
    resources = proxy_resources
    before_currency_reserve = (await exchange.get_currency_reserves(uint(token_id)).invoke()).result.currency_reserves
    token_reserve = (await resources.balanceOf(exchange.contract_address, uint(token_id)).invoke()).result.balance
    # Check price math
    # res = await exchange.get_buy_price(uint(buy_amount), before_currency_reserve, token_reserve).invoke()
    # # Make sale
    # current_time = conftest.get_block_timestamp(starknet.state)
    # max_currency = res.result.price[0] - 10  # Not enough!
    # await set_erc20_allowance(admin_signer, admin_account, lords, exchange.contract_address, max_currency)
    # await assert_revert(admin_signer.send_transaction(
    #     admin_account,
    #     exchange.contract_address,
    #     'buy_tokens',
    #     [
    #         *uint(max_currency),
    #         *uint(token_id),
    #         *uint(buy_amount),
    #         current_time + 1000,
    #     ]
    # ))


@pytest.mark.asyncio
async def test_sell_price(exchange_factory):
    print("test_sell_price")
    starknet, admin_key, admin_account, treasury_account, accounts, signers, proxy_lords, proxy_resources, exchange = exchange_factory
    admin_signer = signers[0]
    admin_account = admin_account
    currency_reserve = 1000
    token_reserve = 1000
    token_id = 3
    token_id2 = 5

    await initial_liq(admin_signer, admin_account, exchange, proxy_lords, proxy_resources,  [currency_reserve, currency_reserve], [token_id, token_id2], [token_reserve, token_reserve])
    # price = (amnt * cur_res * (1000 - fee)) / ((tok_res * 1000) + (amnt * (1000 - fee)))
    # price = (100 * 1000 * (1000 - 100)) / (1000 * 1000 + (100 * (1000 - 100)))
    # price = 82
    await sell_and_check(starknet, admin_account, admin_signer, exchange, proxy_lords, proxy_resources, [token_id], [100], [82])
    # price = (100 * (1000 - 100) * 918) / (1100 * 1000 + (100 * (1000 - 100)))
    # price = 69
    # Second value has same LP value, price, amounts as the first buy_and_check request
    await sell_and_check(starknet, admin_account, admin_signer, exchange, proxy_lords, proxy_resources, [token_id, token_id2], [100, 100], [69, 82])

    # Test increased min fails
    sell_amount = 100
    before_currency_reserve = (await exchange.get_currency_reserves(uint(token_id)).invoke()).result.currency_reserves
    token_reserve = (await proxy_resources.balanceOf(exchange.contract_address, uint(token_id)).invoke()).result.balance
    # Check price math
    res = await exchange.get_sell_price(uint(sell_amount), before_currency_reserve, token_reserve).invoke()
    # Make sale
    current_time = conftest.get_block_timestamp(starknet.state)
    min_currency = res.result.price[0] + 2  # Increase min amount (will fail)
    await assert_revert(admin_signer.send_transaction(
        admin_account,
        exchange.contract_address,
        'sell_tokens',
        [
            *uint(min_currency),
            *uint(token_id),
            *uint(sell_amount),
            current_time + 1000,
        ]
    ))


@pytest.mark.asyncio
async def test_deadlines_respected(exchange_factory):
    print("test_deadlines_respected")
    starknet, admin_key, admin_account, treasury_account, accounts, signers, proxy_lords, proxy_resources, exchange = exchange_factory
    admin_signer = signers[0]
    admin_account = admin_account
    lords = proxy_lords
    resources = proxy_resources
    currency_amount = 10000
    token_amount = 1000
    token_id = 1
    earlier_time = conftest.get_block_timestamp(starknet.state) - 1000

    # Before states
    before_lords_bal, before_resources_bal = await get_token_bals(admin_account, lords, resources, token_id)
    before_ex_lords_bal, before_ex_resources_bal = await get_token_bals(exchange, lords, resources, token_id)

    # Approve access
    await set_erc20_allowance(admin_signer, admin_account, lords, exchange.contract_address, currency_amount)
    await admin_signer.send_transaction(
        admin_account,
        resources.contract_address,
        'setApprovalForAll',
        [exchange.contract_address, True]
    )
    # Provide liquidity
    await assert_revert(admin_signer.send_transaction(
        admin_account,
        exchange.contract_address,
        'add_liquidity',
        [
            1,
            *uint(currency_amount),
            1,
            *uint(token_id),
            1,
            *uint(token_amount),
            earlier_time,
        ]
    ))
    # Remove liquidity
    await assert_revert(admin_signer.send_transaction(
        admin_account,
        exchange.contract_address,
        'remove_liquidity',
        [
            *uint(currency_amount),
            *uint(token_id),
            *uint(token_amount),
            *uint(currency_amount),
            earlier_time,
        ]
    ))
    # Buy
    await assert_revert(admin_signer.send_transaction(
        admin_account,
        exchange.contract_address,
        'buy_tokens',
        [
            *uint(currency_amount),
            *uint(token_id),
            *uint(token_amount),
            earlier_time,
        ]
    ))
    # Sell
    await assert_revert(admin_signer.send_transaction(
        admin_account,
        exchange.contract_address,
        'sell_tokens',
        [
            *uint(currency_amount),
            *uint(token_id),
            *uint(token_amount),
            earlier_time,
        ]
    ))

    # After states
    after_lords_bal, after_resources_bal = await get_token_bals(admin_account, lords, resources, token_id)
    after_ex_lords_bal, after_ex_resources_bal = await get_token_bals(exchange, lords, resources, token_id)

    assert before_lords_bal == after_lords_bal
    assert before_resources_bal == after_resources_bal
    assert before_ex_lords_bal == after_ex_lords_bal
    assert before_ex_resources_bal == after_ex_resources_bal


############
# FUNCTIONS #
############

async def set_erc20_allowance(signer, account, erc20, who, amount):
    await signer.send_transaction(
        account,
        erc20.contract_address,
        'approve',
        [who, *uint(amount)]
    )


async def initial_liq(admin_signer, admin_account, exchange, lords, resources, currency_amounts, token_ids, token_spents):

    # Approve access
    await set_erc20_allowance(admin_signer, admin_account, lords, exchange.contract_address, sum(currency_amounts))
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
        'initial_liquidity',
        [
            len(currency_amounts),
            *expanded_uint_list(currency_amounts),
            len(token_ids),
            *expanded_uint_list(token_ids),
            len(token_spents),
            *expanded_uint_list(token_spents),
        ]
    )


async def add_liq(admin_signer, admin_account, exchange, lords, resources, max_currencies, token_ids, token_spents, starknet):

    # Approve access
    await set_erc20_allowance(admin_signer, admin_account, lords, exchange.contract_address, sum(max_currencies))
    await admin_signer.send_transaction(
        admin_account,
        resources.contract_address,
        'setApprovalForAll',
        [exchange.contract_address, True]
    )

    # Provide liquidity
    current_time = conftest.get_block_timestamp(starknet.state)
    await admin_signer.send_transaction(
        admin_account,
        exchange.contract_address,
        'add_liquidity',
        [
            len(max_currencies),
            *expanded_uint_list(max_currencies),
            len(token_ids),
            *expanded_uint_list(token_ids),
            len(token_spents),
            *expanded_uint_list(token_spents),
            current_time + 1000,
        ]
    )


async def get_token_bals(account, lords, resources, token_id):
    """ Get the current balances. """
    res = await lords.balanceOf(account.contract_address).invoke()
    before_lords_bal = res.result.balance
    res = await resources.balanceOf(account.contract_address, uint(token_id)).invoke()
    before_resources_bal = res.result.balance
    return before_lords_bal, before_resources_bal

def calc_d_x(old_x, old_y, d_y):
    """ Find the new value of x in a x*y=k equation given dy. """
    k = old_x * old_y
    new_x = Fraction(k, (old_y - d_y))
    d_x = new_x - old_x
    return d_x


async def buy_and_check(starknet, admin_account, admin_signer, exchange, lords, resources,  resource_ids, token_to_buys, expected_prices):
    # Store before values for asserting after tests
    befores = []
    before_lords_bal = 0
    res = await lords.balanceOf(admin_account.contract_address).invoke()
    before_royalty_lords = res.result.balance

    for i in range(0, len(resource_ids)):
        before_lords_bal, before_resources_bal = await get_token_bals(admin_account, lords, resources, resource_ids[i])

        before_currency_reserve = (await exchange.get_currency_reserves(uint(resource_ids[i])).invoke()).result.currency_reserves
        token_reserve = (await resources.balanceOf(exchange.contract_address, uint(resource_ids[i])).invoke()).result.balance

        # Check price math
        # res = await exchange.get_buy_price(uint(token_to_buys[i]), before_currency_reserve, token_reserve).invoke()
        # assert res.result.price == uint(expected_prices[i])

        # befores.append({
        #     'before_resources_bal': before_resources_bal,
        #     'before_currency_reserve': before_currency_reserve,
        # })

    # Make sale
    current_time = conftest.get_block_timestamp(starknet.state)
    # Increment max currency to ensure correct price is used
    max_currency = floor(sum(expected_prices) * 1.1) + 10
    await set_erc20_allowance(admin_signer, admin_account, lords, exchange.contract_address, max_currency)
    await admin_signer.send_transaction(
        admin_account,
        exchange.contract_address,
        'buy_tokens',
        [
            *uint(max_currency),
            len(resource_ids),
            *expanded_uint_list(resource_ids),
            len(token_to_buys),
            *expanded_uint_list(token_to_buys),
            current_time + 1000,
        ]
    )

    # Check values
    for i in range(0, len(resource_ids)):
        res = await resources.balanceOf(admin_account.contract_address, uint(resource_ids[i])).invoke()
        after_resources_bal = res.result.balance
        assert uint(befores[i]['before_resources_bal'][0] +
                    token_to_buys[i]) == after_resources_bal
        after_currency_reserve = (await exchange.get_currency_reserves(uint(resource_ids[i])).invoke()).result.currency_reserves
        assert uint(befores[i]['before_currency_reserve']
                    [0] + expected_prices[i]) == after_currency_reserve

    # Check lords in bulk
    res = await lords.balanceOf(admin_account.contract_address).invoke()
    after_lords_bal = res.result.balance
    # Calculate prices with royalty included
    royalties = sum([floor(p * royalty_fee / 1000)
                    for p in expected_prices])
    prices_inc_royalty = sum(expected_prices) + royalties
    assert uint(before_lords_bal[0] - prices_inc_royalty) == after_lords_bal
    # Check royalties paid out
    res = await lords.balanceOf(admin_account.contract_address).invoke()
    assert uint(before_royalty_lords[0] + royalties) == res.result.balance


async def sell_and_check(starknet, admin_account, admin_signer, exchange, lords, resources,  resource_ids, token_to_sells, expected_prices):

    # Store before values for asserting after tests
    befores = []
    before_lords_bal = 0
    res = await lords.balanceOf(ctx.user1.contract_address).invoke()
    before_royalty_lords = res.result.balance

    for i in range(0, len(resource_ids)):
        before_lords_bal, before_resources_bal = await get_token_bals(admin_account, lords, resources, resource_ids[i])

        before_currency_reserve = (await exchange.get_currency_reserves(uint(resource_ids[i])).invoke()).result.currency_reserves
        token_reserve = (await resources.balanceOf(exchange.contract_address, uint(resource_ids[i])).invoke()).result.balance

        # Check price math
        res = await exchange.get_sell_price(uint(token_to_sells[i]), before_currency_reserve, token_reserve).invoke()
        assert res.result.price == uint(expected_prices[i])

        befores.append({
            'before_resources_bal': before_resources_bal,
            'before_currency_reserve': before_currency_reserve,
        })

    # Make sale
    current_time = conftest.get_block_timestamp(starknet.state)
    min_currency = floor(sum(expected_prices) * 0.9) - \
        2  # Royalty + add a bit of fat
    await admin_signer.send_transaction(
        admin_account,
        exchange.contract_address,
        'sell_tokens',
        [
            *uint(min_currency),
            len(resource_ids),
            *expanded_uint_list(resource_ids),
            len(token_to_sells),
            *expanded_uint_list(token_to_sells),
            current_time + 1000,
        ]
    )

    # Check values
    for i in range(0, len(resource_ids)):
        res = await resources.balanceOf(admin_account.contract_address, uint(resource_ids[i])).invoke()
        after_resources_bal = res.result.balance
        assert uint(befores[i]['before_resources_bal'][0] -
                    token_to_sells[i]) == after_resources_bal
        after_currency_reserve = (await exchange.get_currency_reserves(uint(resource_ids[i])).invoke()).result.currency_reserves
        assert uint(befores[i]['before_currency_reserve']
                    [0] - expected_prices[i]) == after_currency_reserve
    # Check lords in bulk
    res = await lords.balanceOf(admin_account.contract_address).invoke()
    after_lords_bal = res.result.balance
    # Calculate prices with royalty included
    royalties = sum([floor(p * ctx.royalty_fee / 1000)
                    for p in expected_prices])
    prices_inc_royalty = sum(expected_prices) - royalties
    assert uint(before_lords_bal[0] + prices_inc_royalty) == after_lords_bal
    # Check royalties paid out
    res = await lords.balanceOf(ctx.user1.contract_address).invoke()
    assert uint(before_royalty_lords[0] + royalties) == res.result.balance