from realms_cli.caller_invoker import wrapped_proxy_call
from realms_cli.config import Config
from realms_cli.utils import print_over_colums, uint, felt_to_str, convert_unix_time
from realms_cli.loot.constants import BEASTS
from rich.console import Console
from rich.table import Table

console = Console()

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

    return out.split(" ")


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


    print_adventurer([out])
    return out.split(" ")


def print_adventurer(out_list):

    config = Config(nile_network='goerli')
    table = Table(show_header=True, header_style="bold magenta")

    for i, key in enumerate(config.ADVENTURER):
        table.add_column(key)
    
    for out in out_list:
        out = out.split(" ")
        item = out[:27]
        item = format_array(3, item, felt_to_str(int(out[3])))
        table.add_row(*item)

    console.print(table)


    # config = Config(nile_network='goerli')
    # pretty_out = []
    # for i, key in enumerate(config.ADVENTURER):

    #     # Output names for item name prefix1, prefix2, and suffix
    #     if i in [25]:
    #         pretty_out.append(f"{key} : {felt_to_str(int(out[i]))}")
    #     else:
    #         pretty_out.append(f"{key} : {int(out[i])}")
    # print("_____________________________________________________")
    # print("_____________________*+ " + felt_to_str(int(out[3])) +
    #       " +*______________________")
    # print("_____________________________________________________")
    # print_over_colums(pretty_out)


async def _get_loot(loot_token_id, network):
    
    config = Config(nile_network=network)
    
    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_LootMarketArcade",
        abi='artifacts/abis/LootMarketArcade.json',
        function="get_item_by_token_id",
        arguments=[*uint(loot_token_id)],
    )
    out = out.split(" ")
    print_loot(out)
    return out



def print_loot(out_list):
    config = Config(nile_network='goerli')
    table = Table(show_header=True, header_style="bold magenta")

    for i, key in enumerate(config.LOOT):
        table.add_column(key)
    
    for out in out_list:
        out = out.split(" ")
        item = out[:13]
        item = format_array(0, item, config.LOOT_ITEMS[int(out[0]) - 1])
        table.add_row(*item)

    console.print(table)


def print_loot_bid(out):
    config = Config(nile_network='goerli')
    pretty_bid_out = []
    for i, key in enumerate(config.BID):
        if key == 'Expiry':
            pretty_bid_out.append(
                f"{key} : {convert_unix_time(int(out[i + 13]))}")
        else:
            pretty_bid_out.append(
                f"{key} : {int(out[i + 13])}")

    print_over_colums(pretty_bid_out)    


def print_loot_and_bid(out):
    config = Config(nile_network='goerli')

    item = out[:13]
    bid = out[13:17]

    item = format_array(0, item, config.LOOT_ITEMS[int(out[0]) -1])
    bid = format_array(1, bid, convert_unix_time(int(bid[1])))

    table = Table(show_header=True, header_style="bold magenta")

    for i, key in enumerate(config.LOOT):
        table.add_column(key)

    for i, key in enumerate(config.BID):
        table.add_column(key)        

    table.add_row(*item, *bid)

    console.print(table)


def format_array(index, array, value):
        array[index] = value
        return array