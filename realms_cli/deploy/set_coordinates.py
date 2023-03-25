from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config
from realms_cli.utils import uint
from realms_cli.coordinates import coordinates_by_id

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


def run(nre):

    config = Config(nre.network)

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
