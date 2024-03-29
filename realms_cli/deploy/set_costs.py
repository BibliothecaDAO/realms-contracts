from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config
from realms_cli.game_structs import BUILDING_COSTS, TROOP_COSTS, LABOR_COST
from realms_cli.utils import uint


async def run(nre):

    config = Config(nre.network)

    # --------- BUILDING COSTS ------- #
    building_calldata = [
        [building_id.value, building_cost.resource_count, building_cost.bits,
         building_cost.packed_ids, building_cost.packed_amounts, building_cost.lords, "0"]
        for building_id, building_cost in BUILDING_COSTS.items()
    ]
    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Buildings",
        function="set_building_cost",
        arguments=building_calldata
    )

    # --------- TROOP COSTS ------- #
    troop_calldata = [
        [troop_id.value, troop_cost.resource_count, troop_cost.bits,
            troop_cost.packed_ids, troop_cost.packed_amounts]
        for troop_id, troop_cost in TROOP_COSTS.items()
    ]
    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Combat",
        function="set_troop_cost",
        arguments=troop_calldata
    )

    # # --------- TROOP COSTS ------- #
    # resources = [
    #     [*uint(resource_id.value), resource_cost.resource_count, resource_cost.bits,
    #         resource_cost.packed_ids, resource_cost.packed_amounts]
    #     for resource_id, resource_cost in LABOR_COST.items()
    # ]

    # print(resources)
    # await wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Labor",
    #     function="set_labor_cost",
    #     arguments=resources
    # )
