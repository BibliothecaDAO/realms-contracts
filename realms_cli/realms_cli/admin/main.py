# First, import click dependency
import click

from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.shared import uint
from realms_cli.deployer import logged_deploy


@click.command()
@click.option("--network", default="goerli")
def mint_resources(network):
    """
    Claim available resources
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_resources",
        function="mintBatch",
        arguments=[int(config.USER_ADDRESS, 16), 10, *uint(1), *uint(2), *uint(3), *uint(4), *uint(5), *uint(6), *uint(7), *uint(8), *uint(9), *uint(10), 10, *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500)
        ],
    )

@click.command()
@click.argument("module_name", nargs=1)
@click.option("--network", default="goerli")
def upgrade_module(module_name, network):
    """
    Upgrades Module
    """

    # REMOVES LINE FROM TXT FILE
    with open("goerli.deployments.txt","r+") as f:
        new_f = f.readlines()
        f.seek(0)
        for line in new_f:
            if module_name + ".json:" + module_name not in line:
                f.write(line)
        f.truncate()

    config = Config(nile_network=network)

    compile(contract_alias="contracts/settling_game/" + module_name + ".cairo")

    deploy(
        network=network,
        alias=module_name
    )

    module, _ = safe_load_deployment(module_name, network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_" + module_name,
        function="upgrade",
        arguments=[strhex_as_strfelt(module)]
    )

    print('Have patience, you might need to wait 30s before invoking this')