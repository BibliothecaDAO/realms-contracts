// -----------------------------------
//   Module.RESOURCES
//   Logic to create and issue resources for a given Realm
//
// MIT License
// -----------------------------------
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_lt
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.utils.game_structs import (
    RealmData,
    ModuleIds,
    ExternalContractIds,
    Cost,
    RealmBuildings,
)

from contracts.settling_game.utils.constants import (
    VAULT_LENGTH,
    DAY,
    BASE_RESOURCES_PER_DAY,
    BASE_LORDS_PER_DAY,
    PILLAGE_AMOUNT,
    MAX_DAYS_ACCURED,
    WONDER_RATE,
)

from contracts.settling_game.library.library_module import Module
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.modules.settling.interface import ISettling
from contracts.settling_game.modules.buildings.interface import IBuildings
from contracts.settling_game.modules.goblintown.interface import IGoblinTown
from contracts.settling_game.modules.calculator.interface import ICalculator
from contracts.settling_game.interfaces.IRealms import IRealms
from contracts.settling_game.library.library_resources import Resources

// -----------------------------------
// Events
// -----------------------------------

@event
func ResourceUpgraded(token_id: Uint256, building_id: felt, level: felt) {
}

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func resource_levels(token_id: Uint256, resource_id: felt) -> (level: felt) {
}

@storage_var
func resource_upgrade_cost(resource_id: felt) -> (cost: Cost) {
}

// -----------------------------------
// INITIALIZER & UPGRADE
// -----------------------------------

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address_of_controller: felt, proxy_admin: felt
) {
    Module.initializer(address_of_controller);
    Proxy.initializer(proxy_admin);
    return ();
}

// @notice Set new proxy implementation
// @dev Can only be set by the arbiter
// @param new_implementation: New implementation contract address
@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

// -----------------------------------
// EXTERNAL
// -----------------------------------

// @notice Claim available resources
// @token_id: Staked realm token id
@external
func claim_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) {
    alloc_locals;
    let (caller) = get_caller_address();

    // CONTRACT ADDRESSES
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms);
    let (s_realms_address) = Module.get_external_contract_address(ExternalContractIds.S_Realms);
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources);

    // modules
    let (settling_logic_address) = Module.get_module_address(ModuleIds.Settling);
    let (goblin_town_address) = Module.get_module_address(ModuleIds.GoblinTown);

    // check if there's no goblin town on realm
    with_attr error_message("RESOURCES: Goblin Town present") {
        let (_, spawn_ts) = IGoblinTown.get_strength_and_timestamp(goblin_town_address, token_id);
        let (now) = get_block_timestamp();
        assert_le(spawn_ts, now);
    }

    // FETCH OWNER
    let (owner) = IERC721.ownerOf(s_realms_address, token_id);

    // ALLOW RESOURCE LOGIC ADDRESS TO CLAIM, BUT STILL RESTRICT
    if (caller != settling_logic_address) {
        Module.ERC721_owner_check(token_id, ExternalContractIds.S_Realms);
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }

    // FETCH REALM DATA
    let (realms_data: RealmData) = IRealms.fetch_realm_data(realms_address, token_id);

    // CALC DAYS
    let (total_days, remainder) = days_accrued(token_id);

    // CALC VAULT DAYS
    let (total_vault_days, vault_remainder) = get_available_vault_days(token_id);

    // CHECK DAYS + VAULT > 1
    let days = total_days + total_vault_days;

    with_attr error_message("RESOURCES: Nothing Claimable.") {
        assert_not_zero(days);
    }

    // set vault time only if actually claiming vault
    if (total_vault_days != 0) {
        // TODO: why is this here? same is called below, outside the if
        ISettling.set_time_vault_staked(settling_logic_address, token_id, vault_remainder);
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }

    ISettling.set_time_staked(settling_logic_address, token_id, remainder);
    ISettling.set_time_vault_staked(settling_logic_address, token_id, vault_remainder);

    // get current buildings on realm
    let (buildings_address) = Module.get_module_address(ModuleIds.Buildings);
    let (current_buildings: RealmBuildings) = IBuildings.get_effective_buildings(
        buildings_address, token_id
    );

    // resources ids
    let (resource_ids) = Resources._calculate_realm_resource_ids(realms_data);

    let (resource_mint) = Resources._calculate_total_mintable_resources(
        current_buildings.House, 100, realms_data, days, 100
    );

    // FETCH OWNER
    let (owner) = IERC721.ownerOf(s_realms_address, token_id);

    let (local data: felt*) = alloc();
    assert data[0] = 0;

    // MINT USERS RESOURCES
    IERC1155.mintBatch(
        resources_address,
        owner,
        realms_data.resource_number,
        resource_ids,
        realms_data.resource_number,
        resource_mint,
        1,
        data,
    );

    let check_wonder = is_le(0, realms_data.wonder);
    if (check_wonder == 1) {
        let (wonder_resources_claim_ids: Uint256*) = alloc();
        let (wonder_resources_claim_amounts: Uint256*) = alloc();
        loop_wonder_resources_claim(
            0, 22, total_days, wonder_resources_claim_ids, wonder_resources_claim_amounts
        );

        let (local data: felt*) = alloc();
        assert data[0] = 0;

        // MINT WONDER RESOURCES TO HOLDER
        IERC1155.mintBatch(
            resources_address,
            owner,
            22,
            wonder_resources_claim_ids,
            22,
            wonder_resources_claim_amounts,
            1,
            data,
        );
        return ();
    }

    return ();
}

// @notice Pillage resources after a succesful raid
// @param token_id: Staked realm id
// @param claimer: Resource receiver address
@external
func pillage_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, claimer: felt
) {
    alloc_locals;
    let (caller) = get_caller_address();
    let (block_timestamp) = get_block_timestamp();
    // ONLY COMBAT CAN CALL
    // TODO: Fix this to allow only combat to call.
    // let (combat_address) = Module.get_module_address(ModuleIds.L06_Combat)

    // with_attr error_message("RESOURCES: ONLY COMBAT MODULE CAN CALL"):
    //     assert caller = combat_address
    // end

    // EXTERNAL CONTRACTS
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms);
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources);
    let (settling_logic_address) = Module.get_module_address(ModuleIds.Settling);

    // Get all vault raidable
    let (_, resource_mint, total_vault_days, _) = get_all_vault_raidable(token_id);

    // CHECK IS RAIDABLE
    with_attr error_message("RESOURCES: NOTHING TO RAID!") {
        assert_not_zero(total_vault_days);
    }

    let (last_update) = ISettling.get_time_vault_staked(settling_logic_address, token_id);

    // Get 25% of the time and return it
    // We only mint 25% of the resources, so we should only take 25% of the time
    // TODO: could this overflow?
    let (time_over) = Resources._calculate_vault_time_remaining(block_timestamp - last_update);

    // SET VAULT TIME = REMAINDER - CURRENT_TIME
    ISettling.set_time_vault_staked(settling_logic_address, token_id, time_over);

    // resources ids
    let (realms_data: RealmData) = IRealms.fetch_realm_data(realms_address, token_id);
    let (resource_ids: Uint256*) = Resources._calculate_realm_resource_ids(realms_data);

    let (local data: felt*) = alloc();
    assert data[0] = 0;

    // MINT PILLAGED RESOURCES TO VICTOR
    IERC1155.mintBatch(
        resources_address,
        claimer,
        realms_data.resource_number,
        resource_ids,
        realms_data.resource_number,
        resource_mint,
        1,
        data,
    );

    return ();
}

// -----------------------------------
// GETTERS
// -----------------------------------

// @notice Gets the number of accrued days
// @param token_id: Staked realm token id
// @return days_accrued: Number of days accrued
// @return remainder: Time remainder after division in seconds
@view
func days_accrued{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (days_accrued: felt, remainder: felt) {
    alloc_locals;

    let (block_timestamp) = get_block_timestamp();
    let (settling_logic_address) = Module.get_module_address(ModuleIds.Settling);

    // GET DAYS ACCRUED
    let (last_update) = ISettling.get_time_staked(settling_logic_address, token_id);
    let (days_accrued, seconds_left_over) = unsigned_div_rem(block_timestamp - last_update, DAY);

    let is_less_than_max = is_le(days_accrued, MAX_DAYS_ACCURED + 1);

    if (is_less_than_max == TRUE) {
        return (days_accrued, seconds_left_over);
    }

    return (MAX_DAYS_ACCURED, seconds_left_over);
}

// @notice Gets the number of accrued days for the vault
// @param token_id: Staked realm token id
// @return days_accrued: Number of days accrued for the vault
// @return remainder: Time remainder after division in seconds
@view
func vault_days_accrued{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (days_accrued: felt, remainder: felt) {
    alloc_locals;

    let (block_timestamp) = get_block_timestamp();
    let (settling_logic_address) = Module.get_module_address(ModuleIds.Settling);

    // GET DAYS ACCRUED
    let (last_update) = ISettling.get_time_vault_staked(settling_logic_address, token_id);
    let (days_accrued, seconds_left_over) = unsigned_div_rem(block_timestamp - last_update, DAY);

    return (days_accrued, seconds_left_over);
}

// @notice Fetches vault days available for realm owner only
// @dev Only returns value if days are over epoch length - set to 7 day cycles
// @param token_id: Staked realm token id
// @return days_accrued: Number of days accrued
// @return remainder: Remaining seconds
@view
func get_available_vault_days{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (days_accrued: felt, remainder: felt) {
    alloc_locals;

    // CALC REMAINING DAYS
    let (days_accrued, seconds_left_over) = vault_days_accrued(token_id);

    // returns true if days <= vault_length -1 (we minus 1 so the user can claim when they have 7 days)
    let less_than = is_le(days_accrued, VAULT_LENGTH - 1);

    // return no days and no remainder
    if (less_than == TRUE) {
        return (0, 0);
    }

    // else return days and remainder
    return (days_accrued, seconds_left_over);
}

// @notice check if resources are claimable
// @param token_id: Staked realm token id
// @return can_claim: Return if resources can be claimed
@view
func check_if_claimable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (can_claim: felt) {
    alloc_locals;

    // FETCH AVAILABLE
    let (days, _) = days_accrued(token_id);
    let (epochs, _) = get_available_vault_days(token_id);

    // ADD 1 TO ALLOW USERS TO CLAIM FULL EPOCH
    let less_than = is_le(days + epochs + 1, 1);

    if (less_than == TRUE) {
        return (FALSE,);
    }

    return (TRUE,);
}

// @notice Calculate all claimable resources
// @param token_id: Staked realms token id
// @return user_mint_len: Lenght of user_mint
// @return user_mint: List of users to mint to
// @return lords_available: Available lord tokens
@view
func get_all_resource_claimable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (user_mint_len: felt, user_mint: Uint256*) {
    alloc_locals;

    // CONTRACT ADDRESSES
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms);
    let (calculator_address) = Module.get_module_address(ModuleIds.Calculator);

    // FETCH REALM DATA
    let (realms_data: RealmData) = IRealms.fetch_realm_data(realms_address, token_id);

    // CALC DAYS
    let (total_days, remainder) = days_accrued(token_id);

    // CALC VAULT DAYS
    let (total_vault_days, vault_remainder) = get_available_vault_days(token_id);

    // CHECK DAYS + VAULT > 1
    let days = total_days + total_vault_days;

    // SET MINT
    let user_mint_rel_perc = 100;

    let (happiness) = ICalculator.calculate_happiness(calculator_address, token_id);

    // get current buildings on realm
    let (buildings_address) = Module.get_module_address(ModuleIds.Buildings);
    let (current_buildings: RealmBuildings) = IBuildings.get_effective_buildings(
        buildings_address, token_id
    );

    let (resource_mint: Uint256*) = Resources._calculate_total_mintable_resources(
        current_buildings.House, happiness, realms_data, days, user_mint_rel_perc
    );

    return (realms_data.resource_number, resource_mint);
}

@view
func get_all_vault_raidable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256
) -> (
    vault_mint_len: felt,
    vault_mint: Uint256*,
    total_vault_days: felt,
    total_vault_days_remaining: felt,
) {
    alloc_locals;

    // CONTRACT ADDRESSES
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms);

    // FETCH REALM DATA
    let (realms_data: RealmData) = IRealms.fetch_realm_data(realms_address, token_id);

    // CALC VAULT DAYS
    let (total_vault_days, total_vault_days_remaining) = vault_days_accrued(token_id);

    let (buildings_address) = Module.get_module_address(ModuleIds.Buildings);
    let (current_buildings: RealmBuildings) = IBuildings.get_effective_buildings(
        buildings_address, token_id
    );

    // pass 100 for base happiness
    let (vault_resource_mint: Uint256*) = Resources._calculate_total_mintable_resources(
        current_buildings.House, 100, realms_data, total_vault_days, PILLAGE_AMOUNT
    );

    return (
        realms_data.resource_number,
        vault_resource_mint,
        total_vault_days,
        total_vault_days_remaining,
    );
}

// -----------------------------------
// INTERNALS
// -----------------------------------

func loop_wonder_resources_claim{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    resources_index,
    resources_len,
    days,
    wonder_resources_claim_ids: felt*,
    wonder_resources_claim_amounts: Uint256*,
) {
    if (resources_index == resources_len) {
        return ();
    }

    assert wonder_resources_claim_ids[resources_index] = resources_index + 1;
    assert wonder_resources_claim_amounts[resources_index] = Uint256(WONDER_RATE * days, 0);

    loop_wonder_resources_claim(
        resources_index + 1,
        resources_len,
        days,
        wonder_resources_claim_ids,
        wonder_resources_claim_amounts,
    );
    return ();
}
