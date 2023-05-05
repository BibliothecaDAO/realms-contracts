from collections import namedtuple
from nile.common import get_class_hash
from realms_cli.caller_invoker import wrapped_send, compile, wrapped_declare
from realms_cli.config import Config
from realms_cli.utils import delete_existing_deployment, delete_existing_declaration
import argparse
import asyncio

Contracts = namedtuple("Contracts", "name")

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
    # Contracts("Combat"),
    # Contracts("Settling"),
    # Contracts("Food"),
    # Contracts("Resources"),
    # Contracts("Travel"),
    # Contracts("S_Realms_ERC721_Mintable"),
    # Contracts("Resources_ERC1155_Mintable_Burnable"),
    # Contracts("Exchange_ERC20_1155"),
    # Contracts("Lords_ERC20_Mintable"),
    # Contracts("Bastions"),
    # Contracts("Adventurer"),
    Contracts("LootMarketArcade"),
    # Contracts("Beast"),
]


async def run():
    parser = argparse.ArgumentParser(
        description="Gui accepts a network param to switch between"
    )
    parser.add_argument("network", help="Network of Starknet to interact the gui with.")
    args = parser.parse_args()
    network = args.network
    config = Config(network)

    # ---------------- SET MODULES  ----------------#

    for contract in NEW_MODULES:
        delete_existing_deployment(contract.name)

        delete_existing_declaration(contract.name)

        await wrapped_declare(config.ADMIN_ALIAS, contract.name, network, contract.name)

        class_hash = get_class_hash(contract.name)

        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_" + contract.name,
            function="upgrade",
            arguments=[class_hash],
        )


if __name__ == "__main__":
    asyncio.run(run())