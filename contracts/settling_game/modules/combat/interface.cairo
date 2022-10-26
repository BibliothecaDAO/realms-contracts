// Module Interfaces
// MIT License

%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.utils.game_structs import RealmCombatData, Cost, ArmyData

@contract_interface
namespace ICombat {
    func set_troop_cost(troop_id: felt, cost: Cost) {
    }
    func get_realm_army_combat_data(army_id: felt, realm_id: Uint256) -> (army_data: ArmyData) {
    }
    func get_population_of_armies(realm_id: Uint256) -> (population: felt) {
    }
}
