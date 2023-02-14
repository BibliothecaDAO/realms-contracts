import asyncclick as click
from realms_cli.caller_invoker import wrapped_send, wrapped_proxy_call
from realms_cli.config import Config
from realms_cli.utils import print_over_colums, uint, felt_to_str
from realms_cli.loot.constants import BEASTS

from realms_cli.loot.getters import _get_adventurer, _get_beast


@click.command()
@click.argument("beast_token_id", nargs=1)
@click.option("--network", default="goerli")
async def get_beast(beast_token_id, network):
    """
    Get Beast metadata
    """
    await _get_beast(beast_token_id, network)


@click.command()
@click.option('--beast', is_flag=False,
              metavar='<columns>', type=click.STRING, help='beast id', prompt=True)
@click.option("--network", default="goerli")
async def attack_beast(beast, network):
    """
    Attack beast
    """
    config = Config(nile_network=network)

    print('🧌 Attacking beast ...')

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Beast",
        function="attack",
        arguments=[*uint(beast)]
    )

    print('🧌 Attacked beast ✅')

    beast_out = await _get_beast(beast, network)

    adventurer_out = await _get_adventurer(network, beast_out[7])

    if adventurer_out[4] == '0':
        print(f"🪦 You have been killed")
    else:
        print(
            f"🤕 You didn't kill and were counterattacked, you have {adventurer_out[4]} health remaining")

    if beast_out[6] == '0':
        print(f"💀 You have killed the {BEASTS[str(int(beast_out[0]))]} 🎉")
    else:
        print(
            f"👹 You hurt the {BEASTS[str(int(beast_out[0]))]}, health is now {beast_out[6]}")


@click.command()
@click.option('--beast', is_flag=False,
              metavar='<columns>', type=click.STRING, help='beast id', prompt=True)
@click.option("--network", default="goerli")
async def flee_from_beast(beast, network):
    """
    Flee from beast
    """
    config = Config(nile_network=network)

    print('🏃‍♂️ Fleeing from beast ...')

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Beast",
        function="flee",
        arguments=[*uint(beast)]
    )


    beast_out = await _get_beast(beast, network)

    adventurer_out = await _get_adventurer(network, beast_out[7])

    if adventurer_out[23] == '0':
        print(f"🏃‍♂️ You successfully fled from beast ✅")
    if adventurer_out[23] == '1':
        print(
            f"😫 You have been ambushed! Your health is now {adventurer_out[4]}")
