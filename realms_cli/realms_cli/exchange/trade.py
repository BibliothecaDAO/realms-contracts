# First, import click dependency
import click
from nile.core.account import Account
from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.shared import uint, expanded_uint_list, expanded_uint_list_decimals, uint_decimal, from_bn
from realms_cli.deployer import logged_deploy
from realms_cli.utils import print_over_colums
import time
import sys

# TODO: make this more dynamic, too hardcoded...


def get_values():
    n_resources = 24

    values = []
    for i in range(n_resources):
        values.append(100 * 10 ** 18)
        values.append("0")
    return values


def get_ids():
    n_resources = 24

    uints = []

    for i in range(n_resources - 2):
        uints.append(str(i+1))
        uints.append("0")

    # WHEAT
    uints.append("10000")
    uints.append("0")

    # FISH
    uints.append("10001")
    uints.append("0")
    return uints


@click.command()
@click.option('--max_currency', type=click.STRING, help='Maximum to sell', prompt=True)
@click.option('--resource_ids', is_flag=False,
              metavar='<columns>', type=click.STRING, help='Resource Ids', prompt=True)
@click.option('--resource_values', is_flag=False,
              metavar='<columns>', type=click.STRING, help='Resource values', prompt=True)
@click.option("--network", default="goerli")
def buy_tokens(resource_ids, resource_values, max_currency, network):
    """
    Claim available resources
    """
    config = Config(nile_network=network)

    resource_ids = [c.strip() for c in resource_ids.split(',')]
    resource_values = [c.strip() for c in resource_values.split(',')]

    if len(resource_ids) != len(resource_values):
        raise Exception('you must pass equal length ids and values')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="buy_tokens",
        arguments=[
            *uint_decimal(max_currency),  # computed
            len(resource_ids),
            *expanded_uint_list(resource_ids),
            len(resource_ids),
            *expanded_uint_list_decimals(resource_values),
            int(time.time() + 3000)
        ],
    )


@click.command()
@click.option('--min_currency', type=click.STRING, help='Maximum to sell', prompt=True)
@click.option('--resource_ids', is_flag=False, metavar='<columns>', type=click.STRING, help='Resource Ids', prompt=True)
@click.option('--resource_values', is_flag=False,
              metavar='<columns>', type=click.STRING, help='Resource values', prompt=True)
@click.option("--network", default="goerli")
def sell_tokens(resource_ids, resource_values, min_currency, network):
    """
    Claim available resources
    """
    # split columns by ',' and remove whitespace
    resource_ids = [c.strip() for c in resource_ids.split(',')]
    resource_values = [c.strip() for c in resource_values.split(',')]

    if len(resource_ids) != len(resource_values):
        raise Exception('you must pass equal length ids and values')

    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="sell_tokens",
        arguments=[
            *uint_decimal(min_currency),  # computed
            len(resource_ids),
            *expanded_uint_list(resource_ids),
            len(resource_ids),
            *expanded_uint_list_decimals(resource_values),
            int(time.time() + 3000)
        ],
    )


@click.command()
@click.option("--network", default="goerli")
def get_market(network):
    """
    Get all sell price
    """
    config = Config(nile_network=network)

    uints = get_ids()
    values = get_values()
    n_resources = 24

    out_sell = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="get_all_sell_price",
        arguments=[
            n_resources,
            *uints,
            n_resources,
            *values,
        ],
    )

    out_buy = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="get_all_buy_price",
        arguments=[
            n_resources,
            *uints,
            n_resources,
            *values,
        ],
    )

    out_sell = out_sell.split(" ")
    pretty_out_sell = []
    for i, resource in enumerate(config.RESOURCES):
        pretty_out_sell.append(
            f"1 {resource} sells {from_bn(out_sell[i*2+1])}  $LORDS")
    print('------------------MARKET SELL PRICES PER LORDS------------------')
    print_over_colums(pretty_out_sell)

    out_buy = out_buy.split(" ")
    pretty_out_buy = []
    for i, resource in enumerate(config.RESOURCES):
        pretty_out_buy.append(
            f"1 {resource} sells {from_bn(out_buy[i*2+1])}  $LORDS")
    print('------------------MARKET BUY PRICES PER LORDS------------------')
    print_over_colums(pretty_out_buy)


@click.command()
@click.option('--resource_ids', is_flag=False, metavar='<columns>', type=click.STRING, help='Resource Ids', prompt=True)
@click.option('--resource_values', is_flag=False,
              metavar='<columns>', type=click.STRING, help='Resource values', prompt=True)
@click.option("--network", default="goerli")
def get_buy_price(resource_ids, resource_values, network):
    """
    Get specific buy price
    """
    # split columns by ',' and remove whitespace
    resource_ids = [c.strip() for c in resource_ids.split(',')]
    resource_values = [c.strip() for c in resource_values.split(',')]

    if len(resource_ids) != len(resource_values):
        raise Exception('you must pass equal length ids and values')

    config = Config(nile_network=network)
    n_resources = len(resource_ids)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="get_all_buy_price",
        arguments=[
            n_resources,
            *expanded_uint_list(resource_ids),
            n_resources,
            *expanded_uint_list_decimals(resource_values),
        ],
    )
    print(out)


@click.command()
@click.option('--max_currency', is_flag=False, metavar='<columns>', type=click.STRING, help='Max currency', prompt=True)
@click.option('--resource_ids', is_flag=False, metavar='<columns>', type=click.STRING, help='Resource Ids', prompt=True)
@click.option('--resource_values', is_flag=False,
              metavar='<columns>', type=click.STRING, help='Resource values', prompt=True)
@click.option("--network", default="goerli")
def add_liq(resource_ids, resource_values, max_currency, network):
    """
    Claim available resources
    """
    # split columns by ',' and remove whitespace
    currency = [c.strip() for c in max_currency.split(',')]
    resource_ids = [c.strip() for c in resource_ids.split(',')]
    resource_values = [c.strip() for c in resource_values.split(',')]

    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="add_liquidity",
        arguments=[
            len(resource_ids),
            *expanded_uint_list_decimals(currency),
            len(resource_ids),
            *expanded_uint_list(resource_ids),
            len(resource_ids),
            *expanded_uint_list_decimals(resource_values),
            int(time.time() + 3000)
        ],
    )


@click.command()
@click.option("--address", default="", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def get_lp_pos(address, network):
    """
    Check address resources
    If no account is specified, it uses the env account.
    """
    config = Config(nile_network=network)

    if address == "":
        nile_account = Account(config.ADMIN_ALIAS, network)
        address = nile_account.address

    n_resources = len(config.RESOURCES)

    uints = []
    for i in range(n_resources):
        uints.append(str(i+1))
        uints.append("0")

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="balanceOfBatch",
        arguments=[
            n_resources,
            *[address for _ in range(n_resources)],
            n_resources,
            *uints,
        ],
    )

    out = out.split(" ")
    pretty_out = []
    for i, resource in enumerate(config.RESOURCES):
        pretty_out.append(f"LP {resource} : {from_bn(out[i*2+1])}")

    print_over_colums(pretty_out)


@click.command()
@click.argument("token_id", nargs=1)
@click.option("--network", default="goerli")
def get_currency_r(token_id, network):
    """
    Get currency level of specific resource
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="get_currency_reserves",
        arguments=[
            *uint(token_id)
        ],
    )
    out = out.split(" ")
    print(from_bn(out[0]))
    # print(int(out[0]))


@click.command()
@click.argument("token_id", nargs=1)
@click.option("--network", default="goerli")
def get_token_r(token_id, network):
    """
    Get token level of specific resource
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_resources",
        function="balanceOf",
        arguments=[
            strhex_as_strfelt(config.Exchange_ERC20_1155_PROXY_ADDRESS),
            *uint(token_id)
        ],
    )
    out = out.split(" ")
    print(from_bn(out[0]))
    # print(int(out[0]))


@click.command()
@click.option("--network", default="goerli")
def get_all_rates(network):
    """
    Get all rates excluding any fees
    """
    config = Config(nile_network=network)
    n_resources = len(config.RESOURCES)

    uints = []
    values = []
    for i in range(n_resources):
        uints.append(str(i+1))
        uints.append("0")
        values.append(1 * 10 ** 18)
        values.append("0")

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="get_all_rates",
        arguments=[
            n_resources,
            *uints,
            n_resources,
            *values,
        ],
    )

    out = out.split(" ")
    pretty_out = []
    for i, resource in enumerate(config.RESOURCES):
        pretty_out.append(f"1 {resource} sells {from_bn(out[i*2+1])}  $LORDS")
    print('MARKET SELL PRICES PER LORDS')
    print_over_colums(pretty_out)


@click.command()
@click.option("--network", default="goerli")
def market_approval(network):
    """
    Set resource & lords approval for AMM
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_resources",
        function="setApprovalForAll",
        arguments=[strhex_as_strfelt(
            config.Exchange_ERC20_1155_PROXY_ADDRESS), 1],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_lords",
        function="increaseAllowance",
        arguments=[strhex_as_strfelt(
            config.Exchange_ERC20_1155_PROXY_ADDRESS), *uint(50000 * (10 ** 18))],
    )


@click.command()
@click.option("--network", default="goerli")
def get_all_currency_reserves(network):
    """
    Get all rates excluding any fees
    """
    config = Config(nile_network=network)

    uints = get_ids()
    values = get_values()
    n_resources = 24

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="get_all_currency_reserves",
        arguments=[
            n_resources,
            *uints
        ],
    )

    out = out.split(" ")
    pretty_out = []
    for i, resource in enumerate(config.RESOURCES):
        pretty_out.append(
            f"{resource} {from_bn(out[i*2+1])}  {from_bn(out[((i)*2 + 1) + (n_resources * 2) + 1 ])}")
    print(out)
    print_over_colums(pretty_out)


@click.command()
@click.option("--network", default="goerli")
def get_owed_currency_tokens(network):
    """
    Get all rates excluding any fees
    """
    config = Config(nile_network=network)

    uints = get_ids()
    values = get_values()
    n_resources = 24

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="get_owed_currency_tokens",
        arguments=[
            n_resources,
            *uints,
            n_resources,
            *values
        ],
    )

    out = out.split(" ")
    pretty_out = []
    for i, resource in enumerate(config.RESOURCES):
        pretty_out.append(
            f"{resource} {from_bn(out[i*2+1])}  {from_bn(out[((i)*2 + 1) + (n_resources * 2) + 1 ])}")
    print(out)
    print_over_colums(pretty_out)
