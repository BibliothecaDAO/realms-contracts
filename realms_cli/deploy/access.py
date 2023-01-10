from realms_cli.caller_invoker import wrapped_send
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt
import time
from enum import IntEnum


class ModuleId(IntEnum):
    Settling = 1
    Resources = 2
    Buildings = 3
    Calculator = 4
    Combat = 6
    L07_Crypts = 7
    L08_Crypts_Resources = 8
    Relics = 12
    Food = 13
    GoblinTown = 14
    Travel = 15
    Crypts_Token = 1001
    Lords_Token = 1002
    Realms_Token = 1003
    Resources_Token = 1004
    S_Crypts_Token = 1005
    S_Realms_Token = 1006
    Labor = 16

# 1. Appoint new contract as Module
# 2. Give write access to specific modules


async def run(nre):

    config = Config(nre.network)

    write_list = [
        [ModuleId.Combat.value, ModuleId.Labor.value],
        [ModuleId.Combat.value, ModuleId.Relics.value],
        [ModuleId.Labor.value, ModuleId.Relics.value]
    ]

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Arbiter",
        function="approve_module_to_module_write_access",
        arguments=write_list
    )
