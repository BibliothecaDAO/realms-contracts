# First, import click dependency
import click

from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.shared import uint, expanded_uint_list
from realms_cli.deployer import logged_deploy


@click.command()
@click.option("--network", default="goerli")
def set_l1_bridge_contract_address(network):
    """
    Set L1 Bridge Contract Address
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Bridge",
        function="set_l1_bridge_contract_address",
        arguments=[strhex_as_strfelt('0x86A65f65172DE02276A044BFC7bDF5B11d7e9eb1')], # TODO use variable from hardhat deployment config.L1_BRIDGE_CONTRACT_ADDRESS_ALIAS
    )
