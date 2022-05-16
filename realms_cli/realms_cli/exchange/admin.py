# First, import click dependency
import click

from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.shared import uint, expanded_uint_list
from realms_cli.deployer import logged_deploy


@click.command()
@click.option("--network", default="goerli")
def set_initial_liq(network):
    """
    Claim available resources
    """
    config = Config(nile_network=network)

    resource_ids = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
                    12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22]
    resource_values = [100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
                       100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100]
    currency_values = [1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000,
                       1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000]

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="initial_liquidity",
        arguments=[
            len(resource_ids),
            *expanded_uint_list(currency_values),
            len(resource_ids),
            *expanded_uint_list(resource_ids),
            len(resource_ids),
            *expanded_uint_list(resource_values)
        ],
    )

@click.command()
@click.option("--network", default="goerli")
def set_lords_approval(network):
    """
    Claim available resources
    """
    config = Config(nile_network=network)


    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_lords",
        function="increaseAllowance",
        arguments=[strhex_as_strfelt(config.Exchange_ERC20_1155_PROXY_ADDRESS), *uint(50000 * (10 ** 18))],
    )

@click.command()
@click.option("--network", default="goerli")
def set_resources_approval(network):
    """
    Claim available resources
    """
    config = Config(nile_network=network)


    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_resources",
        function="setApprovalForAll",
        arguments=[strhex_as_strfelt(config.Exchange_ERC20_1155_PROXY_ADDRESS), 1],
    )
