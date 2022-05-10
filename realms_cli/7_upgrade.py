from realms_cli.caller_invoker import wrapped_send
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt

def run(nre):

    config = Config(nre.network)

    # logged_deploy(
    #     nre,
    #     "S06_Combat",
    #     alias="S06_Combat",
    #     arguments=[
    #         strhex_as_strfelt(config.CONTROLLER_ADDRESS),
    #     ],
    # )

    # set module access within realms access
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_L02_Resources",
        function="upgrade",
        arguments=[strhex_as_strfelt(config.L02_RESOURCES_ADDRESS)]
    )