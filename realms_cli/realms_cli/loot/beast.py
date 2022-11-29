import click
from realms_cli.caller_invoker import wrapped_call, wrapped_send, wrapped_proxy_call
from realms_cli.config import Config
from realms_cli.utils import print_over_colums, uint, felt_to_str, str_to_felt

@click.command()
@click.argument("beast_token_id", nargs=1)
@click.option("--network", default="goerli")
def get_beast(beast_token_id, network):
    """
    Get Beast metadata
    """
    config = Config(nile_network=network)

    out = wrapped_proxy_call(
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
          str(int(out[0])) + " +*______________________")
    print("_____________________________________________________")
    print_over_colums(pretty_out)


@click.command()
@click.option('--beast', is_flag=False,
              metavar='<columns>', type=click.STRING, help='beast id', prompt=True)
@click.option("--network", default="goerli")
def attack_beast(beast, network):
    """
    Attack beast
    """
    config = Config(nile_network=network)

    print('🧌 Attacking beast ...')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Beast",
        function="attack",
        arguments=[*uint(beast)]
    )

    print('🧌 Attacked beast ✅')

    beast_out = wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Beast",
        abi='artifacts/abis/Beast.json',
        function="get_beast_by_id",
        arguments=[*uint(beast)]
    )


    adventurer_out = wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Adventurer",
        abi='artifacts/abis/Adventurer.json',
        function="get_adventurer_by_id",
        arguments=[*uint(beast_out[7])],
    )

    if adventurer_out[4] == '0':
        print("🪦 You have been killed")
    else:
        print(f"🤕 You are hurt, you have {adventurer_out[4]} health remaining")

    if beast_out[6] == '0':
        print("💀 You have killed the beast 🎉")
    else:
        print(f"👹 You hurt the beast, health is now {beast_out[6]}")


@click.command()
@click.option('--beast', is_flag=False,
              metavar='<columns>', type=click.STRING, help='beast id', prompt=True)
@click.option("--network", default="goerli")
def flee_from_beast(beast_token_id, network):
    """
    Flee from beast
    """
    config = Config(nile_network=network)

    print('🏃‍♂️ Fleeing from beast ...')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Beast",
        function="flee",
        arguments=[*uint(beast_token_id)]
    )

    print('🏃‍♂️ Fled from beast ✅')