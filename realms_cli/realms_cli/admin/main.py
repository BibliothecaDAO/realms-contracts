import click
from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy, wrapped_declare
from realms_cli.config import Config
from realms_cli.utils import uint
import time

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

    name = "settling_game/modules/" + module_name.lower() + "/" + \
        module_name

    compile(contract_alias="contracts/" + name + ".cairo")

    deploy(
        network=network,
        alias=module_name
    )

    time.sleep(120)

    class_hash = wrapped_declare(
        config.ADMIN_ALIAS, name, network, module_name)

    time.sleep(120)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_" + module_name,
        function="upgrade",
        arguments=[class_hash]
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
        contract_alias="proxy_Combat",
        function="set_xoroshiro",
        arguments=[int(config.XOROSHIRO_ADDRESS, 16)],
    )

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_GoblinTown",
    #     function="set_xoroshiro",
    #     arguments=[int(config.XOROSHIRO_ADDRESS, 16)],
    # )


@click.command()
@click.argument("token_id", nargs=1)
@click.option("--network", default="goerli")
def zero_dead_squads(network, token_id):
    """
    Zeros dead squads
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Combat",
        function="zero_dead_squads",
        arguments=[token_id, 0],
    )


@click.command()
@click.argument("token_id", nargs=1)
@click.option("--network", default="goerli")
def check_module(network, token_id):
    """
    Checks module address
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias=config.Module_Controller_alias,
        function="get_module_address",
        arguments=[
            token_id,  # uint 1
        ],
    )
    print(out)


@click.command()
@click.argument("address", nargs=1)
@click.option("--network", default="goerli")
def check_address_module(network, address):
    """
    Checks module address
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias=config.Module_Controller_alias,
        function="get_module_id_of_address",
        arguments=[
            address,  # uint 1
        ],
    )
    print(out)


@click.command()
@click.argument("address_from", nargs=1)
@click.argument("address_to", nargs=1)
@click.option("--network", default="goerli")
def get_write_access(network, address_from, address_to):
    """
    Checks module address
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias=config.Module_Controller_alias,
        function="get_write_access",
        arguments=[
            address_from,  # uint 1
            address_to
        ],
    )
    print(out)
