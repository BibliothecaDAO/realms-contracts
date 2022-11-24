# First, import click dependency
import json
import click

from nile.core.account import Account

from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.utils import strhex_as_strfelt


@click.command()
@click.option("--address", default="", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def check_lords(address, network):
    """
    Check $LORDS balance
    """
    config = Config(nile_network=network)

    if address == "":
        nile_account = Account(config.USER_ALIAS, network)
        address = nile_account.address

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_lords",
        function="balanceOf",
        arguments=[address],
    )

    print(out)


@click.command()
@click.option("--address", default="2391140167327979619938051357136306508268704638528932947906243138584057924271", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def transfer_lords(address, network):
    """
    Transfer Lords  2391140167327979619938051357136306508268704638528932947906243138584057924271
    """
    config = Config(nile_network=network)
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_lords",
        function="transfer",
        arguments=[
            address,
            100000 * 10 ** 18,   # uint 1
            0,                # uint 2
        ],
    )

@click.command()
@click.option("--network", default="goerli")
@click.option('--spender', is_flag=False,
              metavar='<columns>', type=click.STRING, help='spender address format 0x...', prompt=True)
@click.option('--amount', is_flag=False,
              metavar='<columns>', type=click.STRING, help='amount to approve', prompt=True)
def approve_lords(spender, amount, network):
    """
    Approve Lords
    """
    config = Config(nile_network=network)
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias=config.Lords_ERC20_Mintable_alias,
        function="approve",
        arguments=[
            strhex_as_strfelt(spender),
            amount,           # uint 1
            0,                # uint 2
        ],
    )

@click.command()
@click.option("--network", default="goerli")
@click.option('--to', is_flag=False,
              metavar='<columns>', type=click.STRING, help='address to mint to format 0x...', prompt=True)
@click.option('--amount', is_flag=False,
              metavar='<columns>', type=click.STRING, help='amount to mint', prompt=True)
def mint_lords(to, amount, network):
    """
    Mint Lords
    """
    config = Config(nile_network=network)
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias=config.Lords_ERC20_Mintable_alias,
        function="mint",
        arguments=[
            strhex_as_strfelt(to),
            amount,           # uint 1
            0,                # uint 2
        ],
    )
