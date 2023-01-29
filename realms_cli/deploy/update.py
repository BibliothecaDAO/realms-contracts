import time
import os

from collections import namedtuple
from realms_cli.caller_invoker import wrapped_send, compile,  wrapped_declare
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config
from realms_cli.utils import strhex_as_felt


Contracts = namedtuple('Contracts', 'contract_name')

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
    # Contracts("Labor"),
    Contracts("Combat"),
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

        location = find_file(
            '/workspaces/realms-contracts', contract.contract_name + '.cairo')

        with open("goerli.deployments.txt", "r+") as f:
            new_f = f.readlines()
            f.seek(0)
            for line in new_f:
                if contract.contract_name + ".json:" + contract.contract_name not in line:
                    f.write(line)
            f.truncate()

        with open("goerli.declarations.txt", "r+") as f:
            new_f = f.readlines()
            f.seek(0)
            for line in new_f:
                if contract.contract_name not in line:
                    f.write(line)
            f.truncate()

        compile(contract_alias=location)

        await logged_deploy(
            nre,
            config.ADMIN_ALIAS,
            contract.contract_name,
            alias=contract.contract_name,
            calldata=[],
        )

        class_hash = await wrapped_declare(
            config.ADMIN_ALIAS, location, nre.network, contract.contract_name)

        time.sleep(60)

        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_" + contract.contract_name,
            function="upgrade",
            arguments=[strhex_as_felt(class_hash)],
        )
