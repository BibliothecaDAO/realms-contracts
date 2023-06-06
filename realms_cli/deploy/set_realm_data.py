from realms_cli.caller_invoker import wrapped_send
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt
import time
import json
from realms_cli.binary_converter import map_realm
from realms_cli.utils import uint
from realms_cli.utils import str_to_felt

per_set = 50
total = 8000
total_sets = 160


async def run(nre):

    config = Config(nre.network)

    realms = json.load(open("data/realms.json", "r"))
    resources = json.load(open("data/resources.json", "r"))
    orders = json.load(open("data/orders.json", "r"))
    wonders = json.load(open("data/wonders.json", ))

    for set, i in enumerate(range(total_sets)):

        myList = list(range(((4+i) * per_set), (per_set * ((4+i) + 1))))

        calldata = [
            [id + 1, 0, str_to_felt(realms[str(id + 1)]['name']), map_realm(realms[str(id + 1)],
                                                                            resources, wonders, orders)]
            for id in myList
        ]
        print(calldata)

        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias=config.Realms_ERC721_Mintable_alias,
            function="set_realm_data",
            arguments=calldata,
        )
