from collections import namedtuple
from realms_cli.caller_invoker import wrapped_send, declare
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.utils import str_to_felt

Contracts = namedtuple('Contracts', 'alias contract_name id')

# STEPS
# 0. Set new names in array accordingly to the tuple structure
# 1. Deploy implementation
# 2. Deploy proxy
# 3. Initialise

NEW_MODULES = [
    Contracts("Adventurer", "Adventurer", "14"),
]

# Realms
LOOT = str_to_felt("LOOT")
LOOT_SYMBOL = str_to_felt("LOOT")

ADVENTURER = str_to_felt("ADVENTURER")
ADVENTURER_SYMBOL = str_to_felt("ADVENTURER")


def run(nre):

    config = Config(nre.network)

    #---------------- SET MODULES  ----------------#

    for contract in NEW_MODULES:

        logged_deploy(
            nre,
            contract.contract_name,
            alias=contract.alias,
            arguments=[],
        )

        declare(contract.contract_name, contract.alias)

        predeclared_class = nre.get_declaration(contract.alias)

        logged_deploy(
            nre,
            'PROXY_Logic',
            alias='proxy_' + contract.alias,
            arguments=[strhex_as_strfelt(predeclared_class)],
        )

    #---------------- INIT MODULES  ----------------#

    for contract in NEW_MODULES:

        wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_" + contract.contract_name,
            function="initializer",
            arguments=[ADVENTURER, ADVENTURER_SYMBOL, strhex_as_strfelt(
                config.ADMIN_ADDRESS), strhex_as_strfelt(config.XOROSHIRO_ADDRESS), strhex_as_strfelt(config.LOOT_PROXY_ADDRESS), strhex_as_strfelt(config.XOROSHIRO_ADDRESS), strhex_as_strfelt(config.LORDS_PROXY_ADDRESS)],
        )
