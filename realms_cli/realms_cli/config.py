""""
This file hold all high-level config parameters

Use:
from realms_cli.realms_cli.config import Config as C

... = config.STARKNET_NETWORK
"""

import os

class Config:
    # Starknet general
    STARKNET_NETWORK = "goerli"

    # Realms specific
    ADMIN_ALIAS = "STARKNET_PRIVATE_KEY"
    ADMIN_ADDRESS = os.environ["ADMIN_ADDRESS"]
    INITIAL_LORDS_SUPPLY = 500000000 * (10 ** 18)
