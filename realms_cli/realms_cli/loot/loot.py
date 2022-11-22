import click
from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.utils import print_over_colums, uint, felt_to_str


@click.command()
@click.option("--network", default="goerli")
def mint_loot(network):
    """
    Mint a Random Loot Item
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Loot",
        function="mint",
        arguments=[int(config.USER_ADDRESS, 16)]
    )


@click.command()
@click.argument("loot_token_id", nargs=1)
@click.option("--network", default="goerli")
def get_loot(loot_token_id, network):
    """
    Get Loot Item metadata
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Loot",
        function="getItemByTokenId",
        arguments=[*uint(loot_token_id)],
    )
    out = out.split(" ")
    pretty_out = []
    for i, key in enumerate(config.LOOT):

        # Output names for item name prefix1, prefix2, and suffix
        if i in [5, 6, 7]:
            pretty_out.append(
                f"{key} : {felt_to_str(int(out[i]))}")
        else:
            pretty_out.append(
                f"{key} : {int(out[i])}")

    print("_________ LOOT ITEM - " + str(out[0]) + "___________")
    print_over_colums(pretty_out)