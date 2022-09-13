%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.utils.game_structs import RealmData, RealmBuildings, Cost

@contract_interface
namespace IBuildings:
    func build(token_id : Uint256, building_id : felt, quantity : felt) -> (success : felt):
    end

    func get_workhut_costs(realms_data : RealmData, quantity : felt) -> (
        resource_ids_len : felt,
        resource_ids : Uint256*,
        resource_values_len : felt,
        resource_values : Uint256*,
    ):
    end

    func get_buildings_integrity_unpacked(token_id : Uint256) -> (realm_buildings : RealmBuildings):
    end

    func get_effective_buildings(token_id : Uint256) -> (realm_buildings : RealmBuildings):
    end

    func get_effective_population_buildings(token_id : Uint256) -> (
        realm_buildings : RealmBuildings
    ):
    end

    func get_storage_realm_buildings(token_id : Uint256) -> (buildings : felt):
    end

    func get_building_cost(building_id : felt) -> (cost : Cost, lords : Uint256):
    end

    func set_building_cost(building_id : felt, cost : Cost, lords : Uint256):
    end

    func get_buildings_unpacked(token_id : Uint256) -> (realm_buildings : RealmBuildings):
    end
end
