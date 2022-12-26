%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.settling_game.utils.constants import MAX_GOBLIN_TOWN_STRENGTH
from contracts.settling_game.utils.game_structs import RealmData, ResourceIds
from contracts.settling_game.modules.labor.library import Labor

const DAY = 86400;

const NOW = 1671510617;

const CURRENT_BALANCE = NOW + (DAY * 2);  // 2 days

const LAST_HARVEST = 1671510617 - DAY;

const VAULT_BALANCE = 86400 * 8;

@external
func test_labor_units_generated{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (
        labor_units_generated, part_labor_units, is_labor_complete, vault_amount
    ) = Labor.labor_units_generated(CURRENT_BALANCE, LAST_HARVEST, NOW);

    %{ print('labor_units_generated:', ids.labor_units_generated) %}
    %{ print('part_labor_units:', ids.part_labor_units) %}
    %{ print('is_labor_complete:', ids.is_labor_complete) %}
    %{ print('vault_amount:', ids.vault_amount) %}
    return ();
}

@external
func test_vault_units{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (vault_units_generated, part_vault_units_generated) = Labor.vault_units(VAULT_BALANCE);

    assert vault_units_generated = VAULT_BALANCE;

    return ();
}
