# First, import click dependency

import click
import datetime
from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.utils import print_over_colums
from realms_cli.coordinates import coordinates_by_id
from realms_cli.shared import uint
from realms_cli.utils import parse_multi_input

per_set = 50
total = 8000
total_sets = 160

# contract IDS
Lords = 1
Realms = 2
S_Realms = 3
Resources = 4
Treasury = 5
Storage = 6
Crypts = 7
S_Crypts = 8


@click.command()
@click.option("--network", default="goerli")
def set_coordinates(network):
    """
    Set realm data
    """
    config = Config(nile_network=network)

    # realm_token_ids = parse_multi_input(realm_token_id)

    # TODO: set upto 4301

    for set, i in enumerate(range(total_sets)):

        myList = list(range((i * per_set), (per_set * (i + 1))))

        calldata = [
            [S_Realms, *uint(id + 1), 0, *coordinates_by_id(int(id + 1))]
            for id in myList
        ]
        print(calldata)

        wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_Travel",
            function="set_coordinates",
            arguments=calldata,
        )


@click.command()
@click.argument("travelling_token_id", nargs=1)
@click.argument("destination_token_id", nargs=1)
@click.option("--network", default="goerli")
def travel(travelling_token_id, destination_token_id, network):
    """
    Travel to Realm
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Travel",
        function="travel",
        arguments=[S_Realms, *uint(travelling_token_id), 1, S_Realms, *
                   uint(destination_token_id), 0],
    )


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def get_travel(realm_token_id, network):
    """
    Gets travel information
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Travel",
        function="get_travel_information",
        arguments=[
            S_Realms,
            realm_token_id,                 # uint 1
            0,
            1
        ],
    )
    out = out.split(" ")
    print('Destination Realm: ' + str(out[1]))
    print('Arrival Time: ' + str(datetime.datetime.fromtimestamp(int(out[4]))))


@click.command()
@click.argument("traveller", nargs=1)
@click.argument("destination", nargs=1)
@click.option("--network", default="goerli")
def travel_time(traveller, destination, network):
    """
    Gets travel information
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Travel",
        function="get_travel_time",
        arguments=[
            *coordinates_by_id(int(traveller)),
            *coordinates_by_id(int(destination)),
        ],
    )
    out = out.split(" ")
    print(str(out))
