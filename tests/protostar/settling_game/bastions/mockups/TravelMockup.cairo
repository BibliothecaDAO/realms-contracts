%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.alloc import alloc
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.utils.game_structs import (
    ModuleIds,
    RealmData,
    ExternalContractIds,
    Point,
)

//
// @notice Fake Travel contract to mock travelling
//

// @param traveller_contract_id: ContractId
// @param traveller_token_id: TokenID
// @param traveller_nested_id: NestedID
@storage_var
func cannot_travel(
    traveller_contract_id: felt, traveller_token_id: Uint256, traveller_nested_id: felt
) -> (cannot_travel: felt) {
}

// @notice Forbid an asset from travelling (army, adventurer)
// @dev By default all assets can travel
// @param traveller_contract_id: ContractId
// @param traveller_token_id: TokenID
// @param traveller_nested_id: NestedID
@external
func forbid_travel{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    traveller_contract_id: felt, traveller_token_id: Uint256, traveller_nested_id: felt
) -> () {
    cannot_travel.write(traveller_contract_id, traveller_token_id, traveller_nested_id, TRUE);
    return ();
}

// @notice Allow an asset to travel (army, adventurer)
// @dev By default all assets can travel
// @param traveller_contract_id: ContractId
// @param traveller_token_id: TokenID
// @param traveller_nested_id: NestedID
@external
func allow_travel{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    traveller_contract_id: felt, traveller_token_id: Uint256, traveller_nested_id: felt
) -> () {
    cannot_travel.write(traveller_contract_id, traveller_token_id, traveller_nested_id, FALSE);
    return ();
}
