from collections import namedtuple
from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy,  wrapped_declare
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config
import time

token_path = 'settling_game/tokens/'


Contracts = namedtuple('Contracts', 'alias contract_name address')

# STEPS
# 0. Set new names in array accordingly to the tuple structure
# 1. Deploy implementation
# 2. Deploy proxy
# 3. Initialise
# 4. Set module id in controller via Arbiter
# 5. Set write access if needed
# 6. Set token contract approval if needed - Resources etc

NEW_MODULES = [
    # Contracts("ModuleController", "ModuleController",
    #           "settling_game/ModuleController", ),
    # Contracts("Buildings", "Buildings",
    #           "settling_game/modules/buildings/Buildings", ),
    # Contracts("Calculator", "Calculator",
    #           "settling_game/modules/calculator/Calculator", ),
    # Contracts("Combat", "Combat",
    #           "settling_game/modules/combat/Combat", ),
    # Contracts("Food", "Food",
    #           "settling_game/modules/food/Food", ),
    Contracts("Resources", "Resources",
              "settling_game/modules/resources/Resources", ),
    # Contracts("Travel", "Travel",
    #           "settling_game/modules/travel/Travel", ),
    # Contracts("S_Realms_ERC721_Mintable", "S_Realms_ERC721_Mintable", token_path +
    #           "S_Realms_ERC721_Mintable", ),
    # Contracts("Resources_ERC1155_Mintable_Burnable", "Resources_ERC1155_Mintable_Burnable", token_path +
    #           "Realms_ERC721_Mintable"),
]


def run(nre):

    config = Config(nre.network)

    #---------------- SET MODULES  ----------------#

    for contract in NEW_MODULES:
        with open("goerli.deployments.txt", "r+") as f:
            new_f = f.readlines()
            f.seek(0)
            for line in new_f:
                if contract.contract_name + ".json:" + contract.alias not in line:
                    f.write(line)
            f.truncate()

        with open("goerli.declarations.txt", "r+") as f:
            new_f = f.readlines()
            f.seek(0)
            for line in new_f:
                if contract.alias not in line:
                    f.write(line)
            f.truncate()

        compile(contract_alias='contracts/' + contract.address + '.cairo')

        logged_deploy(
            nre,
            contract.contract_name,
            alias=contract.alias,
            arguments=[],
        )

        class_hash = wrapped_declare(
            config.ADMIN_ALIAS, contract.address, nre.network, contract.alias)

        time.sleep(400)

        wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_" + contract.alias,
            function="upgrade",
            arguments=[class_hash],
        )
