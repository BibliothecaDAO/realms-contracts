import asyncclick as click
from realms_cli.caller_invoker import wrapped_send, wrapped_proxy_call
from realms_cli.config import Config
from realms_cli.utils import uint, str_to_felt
from realms_cli.loot.getters import _get_adventurer, _get_beast, print_adventurer

@click.command()
@click.option("--network", default="goerli")
@click.option(
    "--item",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer item to start",
    prompt=True,
)
@click.option(
    "--race",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer race",
    prompt=True,
)
@click.option(
    "--home_realm",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer home realm",
    prompt=True,
)
@click.option(
    "--name",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer name",
    prompt=True,
)
@click.option(
    "--order",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer order",
    prompt=True,
)
@click.option(
    "--image_hash_1",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer image hash part 1",
    prompt=True,
)
@click.option(
    "--image_hash_2",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer image hash part 2",
    prompt=True,
)
async def new_adventurer(
    network, item, race, home_realm, name, order, image_hash_1, image_hash_2
):
    """
    Mint a Random Loot Item
    """
    config = Config(nile_network=network)

    print("🪙 Minting lords ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias=config.Lords_ERC20_Mintable_alias,
        function="mint",
        arguments=[config.USER_ADDRESS, 100 * 10**18, 0],  # uint 1  # uint 2
    )

    print("🪙 Minted lords ✅")

    print("👍 Approving lords to be spent ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias=config.Lords_ERC20_Mintable_alias,
        function="approve",
        arguments=[
            config.ADVENTURER_PROXY_ADDRESS,
            100 * 10**18,  # uint 1
            0,  # uint 2
        ],
    )

    print("👍 Approved lords to be spent ✅")

    print("🤴 Minting adventurer ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="mint_with_starting_weapon",
        arguments=[
            config.USER_ADDRESS,
            race,
            home_realm,
            str_to_felt(name),
            order,
            image_hash_1,
            image_hash_2,
            item,
            config.USER_ADDRESS
        ],
    )

    print("🤴 Minted adventurer ✅")


@click.command()
@click.option(
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def get_adventurer(adventurer_token_id, network):
    """
    Get Adventurer metadata
    """

    await _get_adventurer(network, adventurer_token_id)


@click.command()
@click.option("--network", default="goerli")
@click.option(
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id",
    prompt=True,
)
@click.option(
    "--item",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="item id",
    prompt=True,
)
async def equip(network, adventurer_token_id, item):
    """
    Equip loot item
    """
    config = Config(nile_network=network)

    print("🫴 Equiping item ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="equip_item",
        arguments=[*uint(adventurer_token_id), *uint(item)],
    )

    print("🫴 Equiped item ✅")
    await _get_adventurer(network, adventurer_token_id)


@click.command()
@click.option("--network", default="goerli")
@click.option(
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id",
    prompt=True,
)
@click.option(
    "--item",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="item id",
    prompt=True,
)
async def unequip(network, adventurer_token_id, item):
    """
    Unequip loot item
    """
    config = Config(nile_network=network)

    print("🫳 Unequiping item ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="unequip_item",
        arguments=[*uint(adventurer_token_id), *uint(item)],
    )

    print("🫳 Unequiped item ...")
    await _get_adventurer(network, adventurer_token_id)


@click.command()
@click.option("--network", default="goerli")
@click.option(
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id",
    prompt=True,
)
async def explore(network, adventurer_token_id):
    """
    Explore with adventurer
    """
    config = Config(nile_network=network)

    print("👣 Exploring ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="explore",
        arguments=[*uint(adventurer_token_id)],
    )

    print("👣 Explored ✅")

    out = await _get_adventurer(network, adventurer_token_id)

    if out[23] == "1":
        print("🧌 You have discovered a beast")
        await _get_beast(out[26], network)
    else:
        print("🤔 You discovered nothing")



@click.command()
@click.option("--network", default="goerli")
async def all_adventurers(network):
    """
    Get all your Adventurers you own.
    """
    config = Config(nile_network=network)

    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Adventurer",
        abi="artifacts/abis/Adventurer.json",
        function="balance_of",
        arguments=[config.USER_ADDRESS],
    )

    out = out.split(" ")

    all_items = []

    for i in range(0, int(out[0])):
        item = await wrapped_proxy_call(
            network=config.nile_network,
            contract_alias="proxy_Adventurer",
            abi="artifacts/abis/Adventurer.json",
            function="token_of_owner_by_index",
            arguments=[config.USER_ADDRESS, *uint(i)],
        )

        id = item.split(" ")

        out = await wrapped_proxy_call(
            network=config.nile_network,
            contract_alias="proxy_Adventurer",
            abi="artifacts/abis/Adventurer.json",
            function="get_adventurer_by_id",
            arguments=[*uint(id[0])],
        )

        all_items.append(out)

    print_adventurer(all_items)
