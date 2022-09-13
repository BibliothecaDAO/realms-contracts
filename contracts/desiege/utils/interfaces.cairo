%lang starknet

// These are interfaces that can be imported by other contracts for convenience.
// All of the functions in an interface must be @view or @external.

// Interface for the ModuleController.
@contract_interface
namespace IModuleController {
    func get_module_address(module_id: felt) -> (address: felt) {
    }

    func has_write_access(address_attempting_to_write: felt) {
    }

    func appoint_new_arbiter(new_arbiter: felt) {
    }

    func set_address_for_module_id(module_id: felt, module_address: felt) {
    }

    func set_write_access(module_id_doing_writing: felt, module_id_being_written_to: felt) {
    }

    func set_initial_module_addresses(module_01_addr: felt, module_02_addr: felt) {
    }
}

@contract_interface
namespace I02_TowerStorage {
    // Game index
    func get_latest_game_index() -> (game_idx: felt) {
    }
    func set_latest_game_index(game_idx: felt) {
    }

    // Game start marker, used in game logic
    func get_game_start(game_idx: felt) -> (started_at: felt) {
    }
    func set_game_start(game_idx: felt, started_at: felt) {
    }

    // Wall health
    func get_main_health(game_idx: felt) -> (health: felt) {
    }
    func set_main_health(game_idx: felt, health: felt) {
    }

    // Shield value
    func get_shield_value(game_idx: felt, token_id: felt) -> (value: felt) {
    }
    func set_shield_value(game_idx: felt, token_id: felt, value: felt) {
    }

    // token reward pool
    func get_token_reward_pool(game_idx: felt, token_id: felt) -> (value: felt) {
    }
    func set_token_reward_pool(game_idx: felt, token_id: felt, value: felt) {
    }

    // Total reward alloc
    func get_total_reward_alloc(game_idx: felt, side: felt) -> (value: felt) {
    }
    func set_total_reward_alloc(game_idx: felt, side: felt, value: felt) {
    }

    // User reward alloc
    func get_user_reward_alloc(game_idx: felt, user: felt, side: felt) -> (value: felt) {
    }
    func set_user_reward_alloc(game_idx: felt, user: felt, side: felt, value: felt) {
    }

    // Tower Attributes
    func get_tower_attributes(game_idx: felt, tower_idx: felt) -> (attrs_packed: felt) {
    }
    func set_tower_attributes(game_idx: felt, tower_idx: felt, attrs_packed: felt) {
    }

    // Tower count
    func get_tower_count(game_idx: felt) -> (count: felt) {
    }
    func set_tower_count(game_idx: felt, count: felt) {
    }
}

@contract_interface
namespace IDivineEclipseElements {
    func get_has_minted(l1_address: felt, game_idx: felt) -> (has_minted: felt) {
    }
    func set_has_minted(l1_address: felt, game_idx: felt, has_minted: felt) {
    }
    func get_total_minted(token_id: felt) -> (total: felt) {
    }
    func set_total_minted(token_id: felt, total: felt) {
    }
}
