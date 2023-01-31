import time
import os

from collections import namedtuple
from realms_cli.caller_invoker import wrapped_send, compile,  wrapped_declare
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config
from realms_cli.utils import strhex_as_felt, delete_existing_deployment, delete_existing_declaration


Contracts = namedtuple('Contracts', 'name')

# STEPS
# 0. Set new names in array accordingly to the tuple structure
# 1. Deploy implementation
# 2. Deploy proxy
# 3. Initialise
# 4. Set module id in controller via Arbiter
# 5. Set write access if needed
# 6. Set token contract approval if needed - Resources etc

NEW_MODULES = [
    # Contracts("ModuleController"),
    # Contracts("Buildings"),
    # Contracts("Calculator"),
    Contracts("Labor"),
    # Contracts("Combat"),
    # Contracts("Settling"),
    # Contracts("Food"),
    # Contracts("Resources"),
    # Contracts("Travel"),
    # Contracts("S_Realms_ERC721_Mintable"),
    # Contracts("Resources_ERC1155_Mintable_Burnable"),
    # Contracts("Exchange_ERC20_1155"),
]


def find_file(root_dir, file_name):
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for f in filenames:
            if f == file_name:
                return os.path.relpath(os.path.join(dirpath, f), root_dir)
    return None


async def run(nre):

    config = Config(nre.network)

    #---------------- SET MODULES  ----------------#

    for contract in NEW_MODULES:

        delete_existing_deployment(contract.name)

        delete_existing_declaration(contract.name)

        compile(contract.name)

        await logged_deploy(
            nre,
            config.ADMIN_ALIAS,
            contract.name,
            alias=contract.name,
            calldata=[],
        )

        class_hash = await wrapped_declare(
            config.ADMIN_ALIAS, contract.name, nre.network, contract.name)

        time.sleep(60)

        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_" + contract.name,
            function="upgrade",
            arguments=[strhex_as_felt(class_hash)],
        )
