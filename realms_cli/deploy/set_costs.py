from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config, strhex_as_strfelt

from realms_cli.game_structs import BUILDING_COSTS, TROOP_COSTS


def run(nre):

    config = Config(nre.network)

    # --------- BUILDING COSTS ------- #

    for building_id, building_cost in BUILDING_COSTS.items():
        print(building_id.value, building_cost.resource_count, building_cost.bits,
              building_cost.packed_ids, building_cost.packed_amounts)
        wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_L03_Buildings",
            function="set_building_cost",
            arguments=[
                building_id.value, building_cost.resource_count, building_cost.bits, building_cost.packed_ids, building_cost.packed_amounts, building_cost.lords, 0
            ]
        )

    # --------- TROOP COSTS ------- #

    for troop_id, troop_cost in TROOP_COSTS.items():
        print(troop_id)
        wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_L06_Combat",
            function="set_troop_cost",
            arguments=[
                troop_id.value, troop_cost.resource_count, troop_cost.bits, troop_cost.packed_ids, troop_cost.packed_amounts
            ]
        )
