%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.settling_game.utils.game_structs import (
    TravelInformation,
    ExternalContractIds,
    Point,
    ModuleIds,
)

@contract_interface
namespace IBastions {
    // -----------------------------------
    // External
    // -----------------------------------
    func initializer(address_of_controller: felt, proxy_admin: felt) {
    }

    func spawn_bastions(
        points_len: felt,
        points: Point*,
        bonus_types_len: felt,
        bonus_types: felt*,
        grid_dimension: felt,
    ) -> () {
    }

    func bastion_take_location(point: Point, location: felt, realm_id: Uint256, army_id: felt) {
    }

    func bastion_attack(
        point: Point,
        attacking_realm_id: Uint256,
        attacking_army_id: felt,
        defending_realm_id: Uint256,
        defending_army_id: felt,
    ) -> () {
    }

    func bastion_move(point: Point, next_location: felt, realm_id: Uint256, army_id: felt) {
    }

    // -----------------------------------
    // Setters
    // -----------------------------------

    func set_bastion_location_cooldown(bastion_cooldown_: felt, location: felt) -> () {
    }

    func set_bastion_bonus_type(point: Point, bonus_type: felt) -> () {
    }

    func set_bastion_moving_times(move_type: felt, block_time: felt) -> () {
    }

    // -----------------------------------
    // Getters
    // -----------------------------------

    func get_bastion_location_defending_order(point: Point, location: felt) -> (
        defending_order: felt
    ) {
    }

    func get_bastion_location_cooldown_end(point: Point, location: felt) -> (cooldown_end: felt) {
    }

    func get_bastion_bonus_type(point: Point) -> (bonus_type: felt) {
    }
}
