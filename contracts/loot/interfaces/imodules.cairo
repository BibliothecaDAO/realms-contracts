// Module Interfaces
//   These are interfaces that can be imported by other contracts for convenience.
//   All of the functions in an interface must be @view or @external.
//
// MIT License

%lang starknet

from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.utils.game_structs import RealmBuildings, RealmCombatData, Cost, Squad

@contract_interface
namespace IArbiter {
    func batch_set_controller_addresses(
        module_01_addr: felt,
        module_02_addr: felt,
        module_03_addr: felt,
        module_04_addr: felt,
        module_06_addr: felt,
        module_07_addr: felt,
        module_08_addr: felt,
    ) {
    }
}

// Interface for the ModuleController.
@contract_interface
namespace IModuleController {
    func get_module_address(module_id: felt) -> (address: felt) {
    }

    func get_external_contract_address(external_contract_id: felt) -> (address: felt) {
    }

    func get_genesis() -> (genesis_time: felt) {
    }

    func get_arbiter() -> (arbiter: felt) {
    }

    func has_write_access(address_attempting_to_write: felt) -> (success: felt) {
    }

    func appoint_new_arbiter(new_arbiter: felt) {
    }

    func set_address_for_module_id(module_id: felt, module_address: felt) {
    }

    func set_address_for_external_contract(external_contract_id: felt, address: felt) {
    }

    func set_write_access(module_id_doing_writing: felt, module_id_being_written_to: felt) {
    }

    func set_xoroshiro(xoroshiro: felt) {
    }

    func set_initial_module_addresses(
        module_01_addr: felt,
        module_02_addr: felt,
        module_03_addr: felt,
        module_04_addr: felt,
        module_06_addr: felt,
    ) {
    }
    func get_xoroshiro() -> (address: felt) {
    }
}