from collections import namedtuple

from nile.core.declare import declare

from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt
from realms_cli.shared import str_to_felt
from realms_cli.caller_invoker import wrapped_send, wrapped_call
import time

Contracts = namedtuple('Contracts', 'alias contract_name')

guild_contract_proxy = Contracts("proxy_GuildContract", "proxy_GuildContract")
guild_contract = Contracts("GuildContract", "GuildContract")
guild_manager = Contracts("GuildManager", "GuildManager")
guild_certificate = Contracts("GuildCertificate", "GuildCertificate")


def run(nre):

    config = Config(nre.network)

    declare(guild_contract.contract_name, nre.network, guild_contract.alias)
    declare(guild_contract_proxy.contract_name,
            nre.network, guild_contract_proxy.alias)

    predeclared_guild_class = nre.get_declaration(guild_contract.alias)
    predeclared_proxy_class = nre.get_declaration(guild_contract_proxy.alias)

    (guild_manager_address, _) = logged_deploy(
        nre,
        guild_manager.contract_name,
        alias=guild_manager.alias,
        arguments=[strhex_as_strfelt(
            predeclared_proxy_class), strhex_as_strfelt(predeclared_guild_class)]
    )

    (guild_certificate_address, _) = logged_deploy(
        nre,
        guild_certificate.contract_name,
        alias=guild_certificate.alias,
        arguments=[
            str(str_to_felt("Guild certificate")),
            str(str_to_felt("GC")),
            guild_manager_address]
    )

    # Currently need to deploy and manually copy guild to deployments

    print('🕒 Waiting for deploy before invoking')
    time.sleep(120)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="GuildManager",
        function="deploy_guild_proxy_contract",
        arguments=[
            str_to_felt("Test Guild"),
            int(guild_certificate_address, 16)
        ]
    )

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="GuildManager",
        function="get_guild_contracts",
        arguments=[]
    )

    print(out)
