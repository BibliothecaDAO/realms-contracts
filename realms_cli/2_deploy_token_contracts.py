
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt

def run(nre):

    config = Config(nre.network)

    logged_deploy(
        nre,
        "Lords_ERC20_Mintable",
        alias="lords",
        arguments=[
            "123",
            "1234",
            "18",
            str(config.INITIAL_LORDS_SUPPLY),
            "0",
            strhex_as_strfelt(config.ADMIN_ADDRESS),
            strhex_as_strfelt(config.ADMIN_ADDRESS),
        ],
    )

    logged_deploy(
        nre,
        "Realms_ERC721_Mintable",
        alias="realms",
        arguments=[
            "1234",  # name
            "1234",  # ticker
            strhex_as_strfelt(config.ADMIN_ADDRESS), # contract_owner
        ],
    )

    logged_deploy(
        nre,
        "S_Realms_ERC721_Mintable",
        alias="s_realms",
        arguments=[
            "12345",  # name
            "12345",  # ticker
            strhex_as_strfelt(config.ADMIN_ADDRESS), # contract_owner
        ],
    )

    logged_deploy(
        nre,
        "Resources_ERC1155_Mintable_Burnable",
        alias="resources",
        arguments=[
            "1234",
            strhex_as_strfelt(config.ADMIN_ADDRESS), # contract_owner
        ],
    )
