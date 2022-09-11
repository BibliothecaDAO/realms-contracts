# First, import click dependency
from os import environ
from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
import time
from realms_cli.shared import uint

def run(nre):
    """
    Configure Bridge on L2
    """

    config = Config(nile_network=nre.network)

    l1_bridge_address = environ.get('L1_REALMS_BRIDGE_ADDRESS_${nre.network}')

    if l1_bridge_address is None:
        print("Specify env L1_REALMS_BRIDGE_ADDRESS_[network]")
        exit()

    l2_realms_address, _ = safe_load_deployment('proxy_realms', nre.network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Bridge",
        function="set_l1_bridge_contract_address",
        arguments=[strhex_as_strfelt(l1_bridge_address)],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Bridge",
        function="set_l2_realms_contract_address",
        arguments=[strhex_as_strfelt(l2_realms_address)],
    )