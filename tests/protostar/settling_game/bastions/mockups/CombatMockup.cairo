%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.alloc import alloc
from contracts.settling_game.utils.game_structs import (
    ModuleIds,
    RealmData,
    RealmBuildings,
    Cost,
    ExternalContractIds,
    Battalion,
    Army,
)
from contracts.settling_game.modules.combat.library import Combat

//
// @notice Fake Combat contract to mock the combat outcome
// @dev Returns the combat outcome
//

struct ArmyData {
    packed: felt,
    last_attacked: felt,
    XP: felt,
    level: felt,
    call_sign: felt,
}

@storage_var
func combat_outcome() -> (outcome: felt) {
}

@storage_var
func army_health() -> (health: felt) {
}

@storage_var
func army_data_by_id(army_id: felt, realm_id: Uint256) -> (army_data: ArmyData) {
}

@external
func initiate_combat_approved_module{
    range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}(
    attacking_army_id: felt,
    attacking_realm_id: Uint256,
    defending_army_id: felt,
    defending_realm_id: Uint256,
) -> (combat_outcome: felt) {
    alloc_locals;

    let (outcome) = combat_outcome.read();

    return (combat_outcome=outcome);
}

// @notice Get Army Data
@view
func get_realm_army_combat_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    army_id: felt, realm_id: Uint256
) -> (army_data: ArmyData) {
    return army_data_by_id.read(army_id, realm_id);
}

func build_army_with_health() -> (a: Army) {
    tempvar values = new (1, 100, 1, 100, 1, 100, 1, 100, 1, 100, 1, 100, 1, 100, 1, 100);
    let a = cast(values, Army*);
    return ([a],);
}

func build_army_without_health() -> (a: Army) {
    tempvar values = new (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    let a = cast(values, Army*);
    return ([a],);
}

func build_army_without_health_packed{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> (packed_army: felt) {
    let (army_without_health_unpacked) = build_army_without_health();
    let (army_without_health_packed) = Combat.pack_army(army_without_health_unpacked);
    return (army_without_health_packed,);
}

func build_army_with_health_packed{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() -> (packed_army: felt) {
    let (army_with_health_unpacked) = build_army_with_health();
    let (army_with_health_packed) = Combat.pack_army(army_with_health_unpacked);
    return (army_with_health_packed,);
}
