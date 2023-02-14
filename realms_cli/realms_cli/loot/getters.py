import asyncclick as click
from realms_cli.caller_invoker import wrapped_send, wrapped_proxy_call
from realms_cli.config import Config
from realms_cli.utils import print_over_colums, uint, felt_to_str
from realms_cli.loot.constants import BEASTS



async def _get_beast(beast_token_id, network):
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
    _print_beast(out.split(" "))

    return out


def _print_beast(out):
    config = Config(nile_network='goerli')
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


async def _get_adventurer(network, adventurer_token_id):
    config = Config(nile_network=network)
    out = await wrapped_proxy_call(network=config.nile_network,
                                   contract_alias="proxy_Adventurer",
                                   abi='artifacts/abis/Adventurer.json',
                                   function="get_adventurer_by_id",
                                   arguments=[*uint(adventurer_token_id)])

    out = out.split(" ")
    print_adventurer(out)
    return out


def print_adventurer(out):
    config = Config(nile_network='goerli')
    pretty_out = []
    for i, key in enumerate(config.ADVENTURER):

        # Output names for item name prefix1, prefix2, and suffix
        if i in [25]:
            pretty_out.append(f"{key} : {felt_to_str(int(out[i]))}")
        else:
            pretty_out.append(f"{key} : {int(out[i])}")
    print("_____________________________________________________")
    print("_____________________*+ " + felt_to_str(int(out[3])) +
          " +*______________________")
    print("_____________________________________________________")
    print_over_colums(pretty_out)