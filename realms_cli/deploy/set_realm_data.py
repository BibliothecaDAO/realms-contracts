from realms_cli.caller_invoker import wrapped_send
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt
import time
import json
from realms_cli.binary_converter import map_realm


def run(nre):

    config = Config(nre.network)

    realms = json.load(open("data/realms.json", "r"))
    resources = json.load(open("data/resources.json", "r"))
    orders = json.load(open("data/orders.json", "r"))
    wonders = json.load(open("data/wonders.json", ))

    a_list = list(range(250, 300))

    calldata = [
        [id, 0, map_realm(realms[str(id)], resources, wonders, orders)]
        for id in a_list
    ]

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_realms",
        function="set_realm_data",
        arguments=calldata,
    )
