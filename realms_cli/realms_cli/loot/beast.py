import asyncclick as click
from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config
from realms_cli.utils import uint
from realms_cli.loot.constants import BEASTS
from realms_cli.loot.getters import _get_adventurer, _get_beast


@click.command()
@click.option(
    "--beast_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="beast id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def get_beast(beast_token_id, network):
    """
    Get Beast metadata
    """
    await _get_beast(beast_token_id, network)


@click.command()
@click.option(
    "--beast_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="beast id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def attack_beast(beast_token_id, network):
    """
    Attack beast
    """
    config = Config(nile_network=network)

    print("🧌 Attacking beast ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Beast",
        function="attack",
        arguments=[*uint(beast_token_id)],
    )

    print("🧌 Attacked beast ✅")

    beast_out = await _get_beast(beast_token_id, network)

    adventurer_out = await _get_adventurer(network, beast_out[7])

    if adventurer_out[4] == "0":
        print(f"🪦 You have been killed")
    else:
        print(
            f"🤕 You didn't kill and were counterattacked, you have {adventurer_out[7]} health remaining"
        )

    if beast_out[6] == "0":
        print(f"💀 You have killed the {BEASTS[str(int(beast_out[0]))]} 🎉")
    else:
        print(
            f"👹 You hurt the {BEASTS[str(int(beast_out[0]))]}, health is now {beast_out[6]}"
        )


@click.command()
@click.option(
    "--beast_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="beast id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def flee_from_beast(beast_token_id, network):
    """
    Flee from beast
    """
    config = Config(nile_network=network)

    print("🏃‍♂️ Fleeing from beast ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Beast",
        function="flee",
        arguments=[*uint(beast_token_id)],
    )

    beast_out = await _get_beast(beast_token_id, network)

    adventurer_out = await _get_adventurer(network, beast_out[7])

    if adventurer_out[23] == "0":
        print(f"🏃‍♂️ You successfully fled from beast ✅")
    if adventurer_out[23] == "1":
        print(f"😫 You have been ambushed! Your health is now {adventurer_out[4]}")
