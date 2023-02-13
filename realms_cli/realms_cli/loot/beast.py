import anyio
import asyncclick as click
from realms_cli.caller_invoker import wrapped_call, wrapped_send, wrapped_proxy_call
from realms_cli.config import Config
from realms_cli.utils import print_over_colums, uint, felt_to_str, str_to_felt
from realms_cli.loot.constants import BEASTS


@click.command()
@click.argument("beast_token_id", nargs=1)
@click.option("--network", default="goerli")
async def get_beast(beast_token_id, network):
    """
    Get Beast metadata
    """
    config = Config(nile_network=network)

    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Beast",
        abi='artifacts/abis/Beast.json',
        function="get_beast_by_id",
        arguments=[*uint(beast_token_id)],
    )
    out = out.split(" ")

    pretty_out = []
    for i, key in enumerate(config.BEAST):

        # Output names for beast name prefix1, prefix2, and suffix
        if i in [11]:
            pretty_out.append(
                f"{key} : {felt_to_str(int(out[i]))}")
        else:
            pretty_out.append(
                f"{key} : {int(out[i])}")
    print("_____________________________________________________")
    print("_____________________*+ " +
          BEASTS[str(int(out[0]))] + " +*______________________")
    print("_____________________________________________________")
    print_over_colums(pretty_out)


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
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Beast",
        function="attack",
        arguments=[*uint(beast)]
    )

    print('🧌 Attacked beast ✅')

    beast_out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Beast",
        abi='artifacts/abis/Beast.json',
        function="get_beast_by_id",
        arguments=[*uint(beast)]
    )
    beast_out = beast_out.split(" ")

    adventurer_out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Adventurer",
        abi='artifacts/abis/Adventurer.json',
        function="get_adventurer_by_id",
        arguments=[*uint(beast_out[7])],
    )
    adventurer_out = adventurer_out.split(" ")

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

    beast_out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Beast",
        abi='artifacts/abis/Beast.json',
        function="get_beast_by_id",
        arguments=[*uint(beast)]
    )
    beast_out = beast_out.split(" ")

    adventurer_out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Adventurer",
        abi='artifacts/abis/Adventurer.json',
        function="get_adventurer_by_id",
        arguments=[*uint(beast_out[7])],
    )
    adventurer_out = adventurer_out.split(" ")

    if adventurer_out[23] == '0':
        print(f"🏃‍♂️ You successfully fled from beast ✅")
    if adventurer_out[23] == '1':
        print(
            f"😫 You have been ambushed! Your health is now {adventurer_out[4]}")
