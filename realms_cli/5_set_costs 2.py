from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config, strhex_as_strfelt

from tests.settling_game.game_structs import BUILDING_COSTS, RESOURCE_UPGRADE_COST


def run(nre):

    config = Config(nre.network)

    for building_id, building_cost in BUILDING_COSTS.items():
        print(building_id)
        wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="S03_Buildings",
            function="set_building_cost",
            arguments=[
                building_id.value, building_cost.resource_count, building_cost.bits, building_cost.packed_ids, building_cost.packed_amounts
            ]
        )

    for resource_id, resource_cost in RESOURCE_UPGRADE_COST.items():
        print(resource_id)
        wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="S03_Buildings",
            function="set_building_cost",
            arguments=[
                resource_id.value, resource_cost.resource_count, resource_cost.bits, resource_cost.packed_ids, resource_cost.packed_amounts
            ]
        )
