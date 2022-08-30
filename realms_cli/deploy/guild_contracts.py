from collections import namedtuple

from nile.core.declare import declare

from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt
from realms_cli.shared import str_to_felt
from realms_cli.caller_invoker import wrapped_send, wrapped_call
import time

Contracts = namedtuple('Contracts', 'alias contract_name')

proxy = Contracts("proxy", "proxy")
guild_contract = Contracts("guild_contract", "guild_contract")
guild_manager = Contracts("guild_manager", "guild_manager")
guild_certificate = Contracts("guild_certificate", "guild_certificate")


def run(nre):

    config = Config(nre.network)

    declare(guild_contract.contract_name, nre.network, guild_contract.alias)
    declare(proxy.contract_name, nre.network, proxy.alias)

    predeclared_guild_contract_class = nre.get_declaration(
        guild_contract.alias)
    predeclared_guild_manager_class = nre.get_declaration(guild_manager.alias)
    predeclared_guild_certificate_class = nre.get_declaration(
        guild_certificate.alias)
    predeclared_proxy_class = nre.get_declaration(proxy.alias)

    (guild_manager_proxy_address, _) = logged_deploy(
        nre,
        'proxy',
        alias='proxy_' + guild_manager.alias,
        arguments=[strhex_as_strfelt(predeclared_guild_manager_class)],
    )

    (guild_certificate_proxy_address, _) = logged_deploy(
        nre,
        'proxy',
        alias='proxy_' + guild_certificate.alias,
        arguments=[strhex_as_strfelt(predeclared_guild_certificate_class)],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_" + guild_manager.contract_name,
        function="initializer",
        arguments=[
            strhex_as_strfelt(predeclared_proxy_class),
            strhex_as_strfelt(predeclared_guild_contract_class),
            strhex_as_strfelt(config.ADMIN_ADDRESS)
        ],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_" + guild_manager.contract_name,
        function="initializer",
        arguments=[
            str(str_to_felt("Guild certificate")),
            str(str_to_felt("GC")),
            guild_manager_proxy_address,
            strhex_as_strfelt(config.ADMIN_ADDRESS)
        ],
    )

    # Currently need to deploy and manually copy guild to deployments

    print('🕒 Waiting for deploy before invoking')
    time.sleep(120)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_" + guild_manager.contract_name,
        function="deploy_guild_proxy_contract",
        arguments=[
            str_to_felt("Test Guild"),
            int(guild_certificate_proxy_address, 16)
        ]
    )