# Module Interfaces
#   These are interfaces that can be imported by other contracts for convenience.
#   All of the functions in an interface must be @view or @external.
#
# MIT License

%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.utils.game_structs import (
    RealmBuildings,
    RealmCombatData,
    TroopCost,
    Squad,
)

# Interface for the ModuleController.
@contract_interface
namespace IModuleController:
    func get_module_address(module_id : felt) -> (address : felt):
    end

    func get_external_contract_address(external_contract_id : felt) -> (address : felt):
    end

    func get_genesis() -> (genesis_time : felt):
    end

    func get_arbiter() -> (arbiter : felt):
    end

    func has_write_access(address_attempting_to_write : felt) -> (success : felt):
    end

    func appoint_new_arbiter(new_arbiter : felt):
    end

    func set_address_for_module_id(module_id : felt, module_address : felt):
    end

    func set_address_for_external_contract(external_contract_id : felt, address : felt):
    end

    func set_write_access(module_id_doing_writing : felt, module_id_being_written_to : felt):
    end

    func set_initial_module_addresses(
        module_01_addr : felt,
        module_02_addr : felt,
        module_03_addr : felt,
        module_04_addr : felt,
        module_05_addr : felt,
        module_06_addr : felt,
        module_07_addr : felt,
        module_08_addr : felt,
        module_09_addr : felt,
    ):
    end
end

@contract_interface
namespace IS01_Settling:
    func set_time_staked(token_id : Uint256, time_left : felt):
    end
    func set_time_vault_staked(token_id : Uint256, time_left : felt):
    end
    func set_total_realms_settled(amount : felt):
    end
    func get_time_staked(token_id : Uint256) -> (time : felt):
    end
    func get_time_vault_staked(token_id : Uint256) -> (time : felt):
    end
    func get_total_realms_settled() -> (amount : felt):
    end
    func return_approved():
    end
end

@contract_interface
namespace IS02_Resources:
    func get_resource_level(token_id : Uint256, resource : felt) -> (level : felt):
    end
    func get_resource_upgrade_value(resource : felt) -> (level : felt):
    end
    func set_resource_level(token_id : Uint256, resource_id : felt, level : felt) -> ():
    end
end

@contract_interface
namespace IL02_Resources:
    func check_if_claimable(token_id : Uint256) -> (can_claim : felt):
    end
    func claim_resources(token_id : Uint256):
    end
    func pillage_resources(token_id : Uint256, claimer : felt):
    end
end

@contract_interface
namespace IS03_Buildings:
    func get_building_cost_ids(building_id : felt) -> (cost : felt):
    end

    func get_building_cost_values(building_id : felt) -> (cost : felt):
    end

    func get_realm_buildings(token_id : Uint256) -> (buildings : felt):
    end

    func get_realm_building_by_id(token_id : Uint256, building_id : felt) -> (building : felt):
    end

    func set_realm_buildings(token_id : Uint256, buildings_value : felt) -> ():
    end
end

@contract_interface
namespace IL03_Buildings:
    func fetch_buildings_by_type(token_id : Uint256) -> (realm_buildings : RealmBuildings):
    end
end

@contract_interface
namespace IL04_Calculator:
    func calculate_epoch() -> (epoch : felt):
    end
    func calculate_wonder_tax() -> (tax_percentage : felt):
    end
end

@contract_interface
namespace IL05_Wonders:
    func update_wonder_settlement(token_id : Uint256):
    end
end

@contract_interface
namespace IS05_Wonders:
    func set_total_wonders_staked(epoch : felt, amount : felt):
    end

    func set_last_updated_epoch(epoch : felt):
    end

    func set_wonder_id_staked(token_id : Uint256, epoch : felt):
    end

    func set_wonder_epoch_upkeep(epoch : felt, token_id : Uint256, upkept : felt):
    end

    func set_tax_pool(epoch : felt, resource_id : felt, supply : felt):
    end

    func batch_set_tax_pool(
        epoch : felt,
        resource_ids_len : felt,
        resource_ids : Uint256*,
        amounts_len : felt,
        amounts : felt*,
    ):
    end

    func get_total_wonders_staked(epoch : felt) -> (amount : felt):
    end

    func get_last_updated_epoch() -> (epoch : felt):
    end

    func get_wonder_id_staked(token_id : Uint256) -> (epoch : felt):
    end

    func get_wonder_epoch_upkeep(epoch : felt, token_id : Uint256) -> (upkept : felt):
    end

    func get_tax_pool(epoch : felt, resource_id : felt) -> (supply : felt):
    end
end

@contract_interface
namespace IS07_Crypts:
    func set_time_staked(token_id : Uint256, time_left : felt):
    end
    func set_total_crypts_unlocked(amount : felt):
    end
    func get_time_staked(token_id : Uint256) -> (time : felt):
    end
    func get_total_crypts_unlocked() -> (amount : felt):
    end
    func return_approved():
    end
end

namespace IS06_Combat:
    func get_realm_combat_data(realm_id : Uint256) -> (combat_data : RealmCombatData):
    end

    func set_realm_combat_data(realm_id : Uint256, combat_data : RealmCombatData):
    end

    func get_troop_cost(troop_id : felt) -> (cost : TroopCost):
    end

    func update_squad_in_realm(s : Squad, realm_id : Uint256, slot : felt):
    end
end
