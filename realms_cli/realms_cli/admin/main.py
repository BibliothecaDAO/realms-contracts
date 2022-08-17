# First, import click dependency
import click

from nile.core.declare import declare

from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.shared import uint
from realms_cli.deployer import logged_deploy

resources = uint(100000000 * 10 ** 18)


@click.command()
@click.option("--network", default="goerli")
def mint_resources(network):
    """
    Mint batch resources
    """
    config = Config(nile_network=network)

    uints = []
    amounts = []

    n_resources = len(config.RESOURCES)

    for i in range(n_resources - 2):
        uints.append(str(i+1))
        uints.append("0")

    # WHEAT
    uints.append("10000")
    uints.append("0")

    # FISH
    uints.append("10001")
    uints.append("0")

    for i in range(n_resources):
        amounts.append(100000000 * 10 ** 18)
        amounts.append(0)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_resources",
        function="mintBatch",
        arguments=[int('0x07Deb0dA237EE37276489278FE16EFF3E6A3d62F830446104D93C892df771cA2', 16), n_resources,
                   *uints, n_resources, *amounts, 1, 1],
    )


@click.command()
@click.argument("module_name", nargs=1)
@click.option("--network", default="goerli")
def upgrade_module(module_name, network):
    """
    Upgrades Module
    """

    config = Config(nile_network=network)

    # REMOVES LINE FROM TXT FILE
    with open("goerli.deployments.txt", "r+") as f:
        new_f = f.readlines()
        f.seek(0)
        for line in new_f:
            if module_name + ".json:" + module_name not in line:
                f.write(line)
        f.truncate()

    with open("goerli.declarations.txt", "r+") as f:
        new_f = f.readlines()
        f.seek(0)
        for line in new_f:
            if module_name not in line:
                f.write(line)
        f.truncate()

    compile(contract_alias="contracts/settling_game/" +
            module_name + ".cairo")

    deploy(
        network=network,
        alias=module_name
    )

    module = declare(module_name, network, module_name)

    print(module)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_" + module_name,
        function="upgrade",
        arguments=[strhex_as_strfelt(module)]
    )

    print('Have patience, you might need to wait 30s before invoking this')


@click.command()
@click.argument("to_address", nargs=1)
@click.argument("token_id", nargs=1)
@click.option("--network", default="goerli")
def transfer_to(to_address, network, token_id):
    """
    Transfer a (minted) realm from the admin account to a target account.
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="realms",
        function="transferFrom",
        arguments=[int(config.ADMIN_ADDRESS, 16),
                   int(to_address, 16), token_id],
    )


@click.command()
@click.option("--network", default="goerli")
def set_xoroshiro(network):
    """
    Sets Xoroshiro
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_L06_Combat",
        function="set_xoroshiro",
        arguments=[int(config.XOROSHIRO_ADDRESS, 16)],
    )
