
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt
from realms_cli.caller_invoker import wrapped_send
import time
def run(nre):

    config = Config(nre.network)

    logged_deploy(
        nre,
        "Lords_ERC20_Mintable",
        alias="lords",
        arguments=[],
    )

    logged_deploy(
        nre,
        "Realms_ERC721_Mintable",
        alias="realms",
        arguments=[],
    )

    logged_deploy(
        nre,
        "S_Realms_ERC721_Mintable",
        alias="s_realms",
        arguments=[],
    )

    logged_deploy(
        nre,
        "Resources_ERC1155_Mintable_Burnable",
        alias="resources",
        arguments=[],
    )

    logged_deploy(
        nre,
        "PROXY_Logic",
        alias="proxy_lords",
        arguments=[strhex_as_strfelt(config.LORDS_ADDRESS)],
    )

    logged_deploy(
        nre,
        "PROXY_Logic",
        alias="proxy_realms",
        arguments=[strhex_as_strfelt(config.REALMS_ADDRESS)],
    )

    logged_deploy(
        nre,
        "PROXY_Logic",
        alias="proxy_s_realms",
        arguments=[strhex_as_strfelt(config.S_REALMS_ADDRESS)],
    )

    logged_deploy(
        nre,
        "PROXY_Logic",
        alias="proxy_resources",
        arguments=[strhex_as_strfelt(config.RESOURCES_ADDRESS)],
    )

    print('🕒 Waiting for deploy before invoking')
    time.sleep(240)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_lords",
        function="initializer",
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

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_realms",
        function="initializer",
        arguments=[
            "1234",  # name
            "1234",  # ticker
            strhex_as_strfelt(config.ADMIN_ADDRESS), # contract_owner
        ],
    )
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_s_realms",
        function="initializer",
        arguments=[
            "12345",  # name
            "12345",  # ticker
            strhex_as_strfelt(config.ADMIN_ADDRESS), # contract_owner
        ],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_resources",
        function="initializer",
        arguments=[
            "1234",
            strhex_as_strfelt(config.ADMIN_ADDRESS), # contract_owner
        ],
    )