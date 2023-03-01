//
// TITLE:
//      Labour
//
// LOGIC:
//      Allows players to generate resources on their Realm.
//      Resources start generating after you have setup the
//      "tools and labour" on a specific resource.
//      You can choose not to generate a resource if you wish.
//      The gross cost to produce resources is ~42% of its relative rarity.
//
// AUTHOR:
//       <ponderingdemocritus@protonmail.com>
//
// MIT LICENSE

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_not_zero, assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE

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
    MAX_DAYS_ACCURED,
    WONDER_RATE,
    BASE_LABOR_UNITS,
    BASE_RESOURCES_PER_CYCLE,
    BASE_FOOD_PRODUCTION,
)

from contracts.settling_game.library.library_module import Module
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.modules.buildings.interface import IBuildings
from contracts.settling_game.interfaces.IRealms import IRealms
from contracts.settling_game.modules.resources.library import Resources
from contracts.settling_game.utils.general import transform_costs_to_tokens

from contracts.settling_game.modules.labor.library import Labor

// TODO:
// - pack balances into a single felt

// -----------------------------------
// EVENTS & CALLBACKS
// -----------------------------------

// @notice Event emitted when a resource is harvested
// @param token_id: Realm token id
// @param resource_id: Resource id
// @param balance: Balance of resource
@event
func UpdateLabor(
    token_id: Uint256, resource_id: Uint256, last_update: felt, balance: felt, vault_balance: felt
) {
}

@event
func FoodBuildingsBuilt(token_id: Uint256, resource_id: Uint256, qty_built: felt) {
}

// -----------------------------------
// STORAGE VARS
// -----------------------------------

// @notice Balance of resources
// @param token_id: Realm token id
// @param resource_id: Resource id
// @return balance: Balance of resource
@storage_var
func balance(token_id: Uint256, resource_id: Uint256) -> (balance: felt) {
}

// @notice Last time a resource was harvested
// @param token_id: Realm token id
// @param resource_id: Resource id
// @return balance: Balance of resource
@storage_var
func last_harvest(token_id: Uint256, resource_id: Uint256) -> (last_harvest: felt) {
}

// @notice Last time a resource was harvested
// @param token_id: Realm token id
// @param resource_id: Resource id
// @return balance: Balance of resource
@storage_var
func vault_balance(token_id: Uint256, resource_id: Uint256) -> (balance: felt) {
}

// labour cost to generate 1 unit
@storage_var
func labor_cost(resource_id: Uint256) -> (cost: Cost) {
}

// buildings
@storage_var
func food_buildings_produced(token_id: Uint256, resource_id: Uint256) -> (quantity: felt) {
}

// -----------------------------------
// INITIALIZER & UPGRADE FUNCTIONS
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
// EXTERNAL FUNCTIONS
// -----------------------------------

// @notice Create labor on a resource
// @dev Can only be called by the owner of the Realm
// @param token_id: Realm token id
// @param resource_id: Resource id
// @param labor_units: Amount of labor units to create - these are 2hr increments
@external
func create{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(token_id: Uint256, resource_id: Uint256, labor_units: felt) {
    alloc_locals;

    Module.__callback__(token_id);

    let (owner) = get_caller_address();

    // check owner is calling
    Module.ERC721_owner_check(token_id, ExternalContractIds.S_Realms);

    // addresses
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms);
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources);

    // Get Realm Data
    let (realms_data: RealmData) = IRealms.fetch_realm_data(realms_address, token_id);

    // check resource exists on realm - otherwise revert
    Resources.assert_resources_exist(realms_data, resource_id);

    // burn costs of labor
    let (cost) = get_labor_cost(resource_id);
    Module.burn_resources(cost, labor_units, owner);

    let (ts) = get_block_timestamp();

    // get current balance
    let (current_balance) = balance.read(token_id, resource_id);

    // labor units calculation - BASE_LABOR_UNITS = minimum amount purchaseable
    let labor = labor_units * BASE_LABOR_UNITS;

    // check uninitalised - if not then set as now timestamp
    let (last_harvest_time) = last_harvest.read(token_id, resource_id);
    if (last_harvest_time == 0) {
        tempvar harvest_time = ts;
    } else {
        tempvar harvest_time = last_harvest_time;
    }

    // check if balance exists
    if (current_balance == 0) {
        tempvar new_balance = ts + labor;
    } else {
        tempvar new_balance = current_balance + labor;
    }

    // write balance
    balance.write(token_id, resource_id, new_balance);

    last_harvest.write(token_id, resource_id, harvest_time);

    // get vault balance
    let (current_vault_balance) = vault_balance.read(token_id, resource_id);

    // emit
    UpdateLabor.emit(token_id, resource_id, harvest_time, new_balance, current_vault_balance);

    return ();
}

// @notice Harvest labor units on a Realms resource.
// @dev The smallest you can harvest is one BASE_LABOR_UNITS (2hrs)
// @param token_id: Realm ID
// @param resource_id: Resource ID
@external
func harvest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, resource_id: Uint256
) {
    alloc_locals;

    Module.__callback__(token_id);

    Module.ERC721_owner_check(token_id, ExternalContractIds.S_Realms);

    // calculate labor units available to harvest
    let (
        generated, part_labor_units, is_labor_complete, vault_generated_amount
    ) = labor_units_generated(token_id, resource_id);

    // calculate vault balance
    // we add vault_generated_amount here so they can immediatley harvest the vault if there is a remainder
    let (current_vault_balance) = vault_balance.read(token_id, resource_id);
    let (vault_units_generated, part_vault_units_generated) = Labor.vault_units(
        current_vault_balance + vault_generated_amount
    );

    // check at least 1 available
    let units = vault_units_generated + generated;

    with_attr error_message("LABOUR: Nothing Generated") {
        assert_not_zero(units);
    }

    // Set vault balance to increase or reset it to 0 if claiming
    if (vault_units_generated == FALSE) {
        tempvar new_vault_balance = current_vault_balance + vault_generated_amount;
    } else {
        tempvar new_vault_balance = 0;
    }
    vault_balance.write(token_id, resource_id, new_vault_balance);

    // calculate balance - so we can emit
    let (current_balance) = balance.read(token_id, resource_id);

    let (ts) = get_block_timestamp();

    if (is_labor_complete == TRUE) {
        // set balance to current ts - since we have harvested everything
        // if there is labour still available, we don't have to adjust the balance
        balance.write(token_id, resource_id, ts);

        // emit
        UpdateLabor.emit(token_id, resource_id, ts, ts, new_vault_balance);

        last_harvest.write(token_id, resource_id, ts);

        tempvar syscall_ptr = syscall_ptr;
    } else {
        // emit
        UpdateLabor.emit(
            token_id, resource_id, ts - part_labor_units, current_balance, new_vault_balance
        );

        // add leftover time back so you don't loose part labour units
        last_harvest.write(token_id, resource_id, ts - part_labor_units);
        tempvar syscall_ptr = syscall_ptr;
    }

    // minting
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources);
    let (s_realms_address) = Module.get_external_contract_address(ExternalContractIds.S_Realms);

    let (owner) = IERC721.ownerOf(s_realms_address, token_id);

    let (local data: felt*) = alloc();
    assert data[0] = 0;

    let resource_amount = Uint256(units * BASE_RESOURCES_PER_CYCLE * 10 ** 18, 0);

    // mint resources
    IERC1155.mint(resources_address, owner, resource_id, resource_amount, 1, data);

    return ();
}

// @notice
// @dev
// @param token_id
@external
func pillage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, claimer: felt
) {
    alloc_locals;

    // only combat can call
    Module.only_approved();

    // external contracts
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms);
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources);

    // resources ids
    let (realms_data: RealmData) = IRealms.fetch_realm_data(realms_address, token_id);
    let (resource_ids: Uint256*) = Resources._calculate_realm_resource_ids(realms_data);

    let (resource_values: Uint256*) = alloc();
    get_all_raidable(
        token_id,
        realms_data.resource_number,
        resource_ids,
        realms_data.resource_number,
        resource_values,
    );

    let (data: felt*) = alloc();
    assert data[0] = 0;

    // pillage resources and send to player that won the battle
    IERC1155.mintBatch(
        resources_address,
        claimer,
        realms_data.resource_number,
        resource_ids,
        realms_data.resource_number,
        resource_values,
        1,
        data,
    );

    return ();
}

// -----------------------------------
// GETTERS
// -----------------------------------

@view
func labor_units_generated{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, resource_id: Uint256
) -> (
    labor_units_generated: felt, part_labor_units: felt, is_labor_complete: felt, vault_amount: felt
) {
    let (ts) = get_block_timestamp();
    let (current_balance) = balance.read(token_id, resource_id);
    let (last_harvest_time) = last_harvest.read(token_id, resource_id);

    return Labor.labor_units_generated(current_balance, last_harvest_time, ts);
}

@view
func get_vault_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, resource_id: Uint256
) -> (balance: felt) {
    return vault_balance.read(token_id, resource_id);
}

// @notice
// @param resource_id
// @return
@view
func get_labor_cost{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    resource_id: Uint256
) -> (cost: Cost) {
    let (cost) = labor_cost.read(resource_id);
    return (cost,);
}

@view
func get_raidable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, resource_id: Uint256
) -> (vault_units_generated: felt, part_vault_units_generated: felt) {
    let (balance) = vault_balance.read(token_id, resource_id);

    return Labor.raidable_labor_units(balance);
}

func get_all_raidable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256,
    resource_ids_len: felt,
    resource_ids: Uint256*,
    resource_values_len: felt,
    resource_values: Uint256*,
) {
    if (resource_ids_len == 0) {
        return ();
    }

    // get balance
    let (vault_units_generated, _) = get_raidable(token_id, [resource_ids]);

    assert [resource_values] = Uint256(
        vault_units_generated * BASE_RESOURCES_PER_CYCLE * 10 ** 18, 0
    );

    // set vault back
    update_vault_balance(token_id, [resource_ids], vault_units_generated * BASE_LABOR_UNITS);

    return get_all_raidable(
        token_id,
        resource_ids_len - 1,
        resource_ids + Uint256.SIZE,
        resource_values_len - 1,
        resource_values + Uint256.SIZE,
    );
}

func update_vault_balance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, resource_id: Uint256, update_value: felt
) {
    let (_balance) = get_vault_balance(token_id, resource_id);
    vault_balance.write(token_id, resource_id, _balance - update_value);

    let (current_balance) = balance.read(token_id, resource_id);
    let (last_harvest_balance) = last_harvest.read(token_id, resource_id);

    UpdateLabor.emit(
        token_id, resource_id, last_harvest_balance, current_balance, _balance - update_value
    );

    return ();
}

// -----------------------------------
// ADMIN
// -----------------------------------

// @notice
// @param resource_id
// @param
@external
func set_labor_cost{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    resource_id: Uint256, cost: Cost
) {
    Proxy.assert_only_admin();
    labor_cost.write(resource_id, cost);
    return ();
}

@external
func create_food{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(token_id: Uint256, resource_id: Uint256, labor_units: felt, qty_built: felt) {
    alloc_locals;

    Module.__callback__(token_id);

    let (owner) = get_caller_address();

    // check owner is calling
    Module.ERC721_owner_check(token_id, ExternalContractIds.S_Realms);

    // addresses
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms);

    // Get Realm Data
    let (realms_data: RealmData) = IRealms.fetch_realm_data(realms_address, token_id);

    // check resource exists on realm - otherwise revert
    Labor.assert_resource_ids(resource_id.low);

    // assert enough traits
    Labor.assert_enough_traits(realms_data, resource_id.low, qty_built);

    // can't build 0
    assert_not_zero(qty_built);

    // burn costs of labor
    let (cost) = get_labor_cost(resource_id);
    Module.burn_resources(cost, labor_units * qty_built, owner);

    //
    // buildings_to_claim = if you try to build a different number from what already exists we
    // overwrite the value - but before that the player gets a small boost from what they have
    // already spent
    //

    let (current_buildings) = food_buildings_produced.read(token_id, resource_id);

    if (current_buildings == qty_built) {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        _harvest_unharvested(token_id, resource_id, current_buildings);

        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    // labor units calculation - BASE_LABOR_UNITS = minimum amount purchaseable
    let food_cycle = labor_units * BASE_LABOR_UNITS;

    let (ts) = get_block_timestamp();
    let (current_balance) = balance.read(token_id, resource_id);

    // check uninitalised - if not then set as now timestamp
    let (last_harvest_time) = last_harvest.read(token_id, resource_id);
    if (last_harvest_time == 0) {
        tempvar harvest_time = ts;
    } else {
        tempvar harvest_time = last_harvest_time;
    }

    // check if balance exists
    if (current_balance == 0) {
        tempvar new_balance = ts + food_cycle;
    } else {
        tempvar new_balance = current_balance + food_cycle;
    }

    // write balance
    balance.write(token_id, resource_id, new_balance);

    last_harvest.write(token_id, resource_id, harvest_time);

    // store buildings produced
    food_buildings_produced.write(token_id, resource_id, qty_built);

    // emit qty_built
    FoodBuildingsBuilt.emit(token_id, resource_id, qty_built);

    // update
    let (current_vault_balance) = vault_balance.read(token_id, resource_id);
    UpdateLabor.emit(token_id, resource_id, harvest_time, new_balance, current_vault_balance);

    return ();
}

@external
func harvest_food{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, resource_id: Uint256
) {
    alloc_locals;
    let (ts) = get_block_timestamp();

    // balance
    let (current_balance) = balance.read(token_id, resource_id);

    // harvest time
    let (last_harvest_time) = last_harvest.read(token_id, resource_id);

    // qty of buildings built
    let (qty_built) = food_buildings_produced.read(token_id, resource_id);

    // calculate generated
    let (labor_units_generated, part_labor_units, is_labor_complete) = Labor.food_units_generated(
        current_balance, last_harvest_time, ts
    );

    if (is_labor_complete == TRUE) {
        // set balance to current ts - since we have harvested everything
        // if there is labour still available, we don't have to adjust the balance
        balance.write(token_id, resource_id, ts);

        // emit
        UpdateLabor.emit(token_id, resource_id, ts, ts, 0);

        last_harvest.write(token_id, resource_id, ts);

        tempvar syscall_ptr = syscall_ptr;
    } else {
        // emit
        UpdateLabor.emit(token_id, resource_id, ts - part_labor_units, current_balance, 0);

        // add leftover time back so you don't loose part labour units
        last_harvest.write(token_id, resource_id, ts - part_labor_units);
        tempvar syscall_ptr = syscall_ptr;
    }

    // TODO: only mint if greater than 1
    let (s_realms_address) = Module.get_external_contract_address(ExternalContractIds.S_Realms);
    let (owner) = IERC721.ownerOf(s_realms_address, token_id);
    mint_resource(resource_id, labor_units_generated * qty_built * BASE_FOOD_PRODUCTION, owner);

    return ();
}

// harvests remaining food - used in the create function
func _harvest_unharvested{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, resource_id: Uint256, qty_built: felt
) {
    alloc_locals;

    // calculate labor units available to harvest
    let (current_balance) = balance.read(token_id, resource_id);
    let (ts) = get_block_timestamp();
    let (last_harvest_time) = last_harvest.read(token_id, resource_id);

    // full amount of past produced
    let (labor_units_generated, _, _) = Labor.food_units_generated(
        current_balance, last_harvest_time, ts
    );

    let (remaining_units, _) = unsigned_div_rem(
        current_balance - last_harvest_time, BASE_LABOR_UNITS
    );

    // we divide by to deducte the penalty
    let (deducted, _) = unsigned_div_rem(remaining_units, 4);

    // TODO: only mint if greater than 1
    let (s_realms_address) = Module.get_external_contract_address(ExternalContractIds.S_Realms);
    let (owner) = IERC721.ownerOf(s_realms_address, token_id);
    mint_resource(
        resource_id, (deducted + labor_units_generated) * qty_built * BASE_FOOD_PRODUCTION, owner
    );

    return ();
}

func mint_resource{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    resource_id: Uint256, amount: felt, owner: felt
) {
    alloc_locals;

    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources);
    let (data: felt*) = alloc();
    assert data[0] = 0;
    let resource_amount = Uint256(amount * 10 ** 18, 0);
    IERC1155.mint(resources_address, owner, resource_id, resource_amount, 1, data);
    return ();
}
