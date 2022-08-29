from nile.core.declare import declare

from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.shared import str_to_felt
import time
from realms_cli.shared import uint

LORDS = str_to_felt("LORDS")
STK_LORDS = str_to_felt("stkLORDS")


def run(nre):

    config = Config(nre.network)

    # compile(contract_alias="contracts/staking/SingleSidedStaking.cairo")
    # compile(contract_alias="contracts/staking/Splitter.cairo")

    # logged_deploy(
    #     nre,
    #     "SingleSidedStaking",
    #     alias="SingleSidedStaking",
    #     arguments=[],
    # )
    # module = declare("SingleSidedStaking", nre.network, "SingleSidedStaking")

    # logged_deploy(
    #     nre,
    #     "PROXY_Logic",
    #     alias="proxy_SingleSidedStaking",
    #     arguments=[
    #         strhex_as_strfelt(module),
    #     ]
    # )

    # logged_deploy(
    #     nre,
    #     "Splitter",
    #     alias="Splitter",
    #     arguments=[],
    # )
    # module = declare("Splitter", nre.network, "Splitter")

    # logged_deploy(
    #     nre,
    #     "PROXY_Logic",
    #     alias="proxy_Splitter",
    #     arguments=[
    #         strhex_as_strfelt(module),
    #     ]
    # )

    # print('🕒 Waiting for deploy before invoking... 1 minutes for testnet')
    # time.sleep(60)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_SingleSidedStaking",
        function="initializer",
        arguments=[
            strhex_as_strfelt(config.ADMIN_ADDRESS),
            strhex_as_strfelt(config.LORDS_PROXY_ADDRESS),
            LORDS,
            STK_LORDS
        ],
    )

    module, _ = safe_load_deployment('SingleSidedStaking', 'goerli')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Splitter",
        function="initializer",
        arguments=[
            strhex_as_strfelt(config.ADMIN_ADDRESS),
            strhex_as_strfelt(module),
            strhex_as_strfelt(config.ADMIN_ADDRESS),
            strhex_as_strfelt(config.LORDS_PROXY_ADDRESS)
        ],
    )
