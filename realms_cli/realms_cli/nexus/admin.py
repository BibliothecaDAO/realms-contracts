# First, import click dependency
import click

from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.utils import uint


@click.command()
@click.option("--network", default="goerli")
def check_splitter_lords(network):
    """
    Check $LORDS balance
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_lords",
        function="balanceOf",
        arguments=[int(config.PROXY_NEXUS, 16)]
    )

    print(out)


@click.command()
@click.option("--network", default="goerli")
def split(network):
    """
    Splits Lords between Nexus and Treasury
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Splitter",
        function="split",
        arguments=[],
    )


@click.command()
@click.option("--network", default="goerli")
def deposit(network):
    """
    Splits Lords between Nexus and Treasury
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_SingleSidedStaking",
        function="deposit",
        arguments=[*uint(5000 * (10 ** 18)), int(config.USER_ADDRESS, 16)],
    )


@click.command()
@click.option("--network", default="goerli")
def increase_allowance_nexus(network):
    """
    Splits Lords between Nexus and Treasury
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_lords",
        function="approve",
        arguments=[int(config.PROXY_NEXUS, 16), *uint(5000 * (10 ** 18))],
    )
