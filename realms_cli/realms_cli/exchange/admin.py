# First, import click dependency
import click

from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.shared import uint, expanded_uint_list, from_bn
from realms_cli.deployer import logged_deploy


@click.command()
@click.option("--network", default="goerli")
def set_initial_liq(network):
    """
    Claim available resources
    """
    config = Config(nile_network=network)
    n_resources = 24
    price = [37.356,
             29.356,
             28.551,
             19.687,
             16.507,
             12.968,
             8.782,
             7.128,
             6.808,
             4.425,
             2.235,
             1.840,
             1.780,
             1.780,
             1.281,
             1.207,
             1.035,
             0.827,
             0.693,
             0.410,
             0.276,
             0.171, 2000, 2000]

    resource_ids = []
    for i in range(n_resources - 2):
        resource_ids.append(str(i+1))
        resource_ids.append("0")

    # WHEAT
    resource_ids.append("10000")
    resource_ids.append("0")

    # FISH
    resource_ids.append("10001")
    resource_ids.append("0")

    resource_values = []
    for i, resource in enumerate(price):
        resource_values.append(int((resource * 10000) * 10 ** 18))
        resource_values.append("0")

    currency_values = []
    for i in range(n_resources):
        currency_values.append(str(10000 * 10 ** 18))
        currency_values.append("0")

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="initial_liquidity",
        arguments=[
            n_resources,
            *currency_values,
            n_resources,
            *resource_ids,
            n_resources,
            *resource_values
        ],
    )


@click.command()
@click.option("--network", default="goerli")
def set_approval(network):
    """
    Set Lords approval for AMM
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_lords",
        function="increaseAllowance",
        arguments=[strhex_as_strfelt(
            config.Exchange_ERC20_1155_PROXY_ADDRESS), *uint(50000 * (10 ** 18))],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_resources",
        function="setApprovalForAll",
        arguments=[strhex_as_strfelt(
            config.Exchange_ERC20_1155_PROXY_ADDRESS), 1],
    )


@click.command()
@click.option("--network", default="goerli")
def update_treasury(network):
    """
    Update royalty info
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="set_royalty_info",
        arguments=[*uint(30), strhex_as_strfelt(
            config.PROXY_NEXUS)],
    )
