// -----------------------------------
//   Module.Combat
//   Logic around Combat system

// ELI5:
//   Combat revolves around Armies fighting Armies.
//   A Realm can have many Armies and Armies can fight any other Army.
//   Army ID 0 is reserved for your defending Army, and it cannot move.
//   Armies accrue points if they enter a battle. Both Armies must exist at the same coordinates in order to battle.
//
//
//

// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_lt
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp, get_caller_address

from openzeppelin.upgrades.library import Proxy
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721

from contracts.settling_game.interfaces.IERC1155 import IERC1155

from contracts.settling_game.library.library_module import Module
from contracts.settling_game.modules.combat.library import Combat
from contracts.settling_game.interfaces.imodules import IModuleController

from contracts.settling_game.utils.general import transform_costs_to_tokens

from contracts.settling_game.modules.goblintown.interface import IGoblinTown
from contracts.settling_game.modules.food.interface import IFood
from contracts.settling_game.modules.relics.interface import IRelics
from contracts.settling_game.modules.travel.interface import ITravel
from contracts.settling_game.modules.resources.interface import IResources
from contracts.settling_game.modules.buildings.interface import IBuildings
from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.interfaces.IRealms import IRealms

from contracts.settling_game.utils.constants import (
    ATTACK_COOLDOWN_PERIOD,
    COMBAT_OUTCOME_ATTACKER_WINS,
    COMBAT_OUTCOME_DEFENDER_WINS,
    GOBLINDOWN_REWARD,
    DEFENDING_ARMY_XP,
    ATTACKING_ARMY_XP,
    TOTAL_BATTALIONS,
)
from contracts.settling_game.utils.game_structs import (
    ModuleIds,
    RealmData,
    RealmBuildings,
    Cost,
    ExternalContractIds,
    Battalion,
    Army,
    ArmyData,
)

// -----------------------------------
// Events
// -----------------------------------

@event
func CombatStart_4(
    attacking_army_id: felt,
    attacking_realm_id: Uint256,
    attacking_army: Army,
    defending_army_id: felt,
    defending_realm_id: Uint256,
    defending_army: Army,
) {
}

@event
func CombatEnd_4(
    combat_outcome: felt,
    attacking_army_id: felt,
    attacking_realm_id: Uint256,
    attacking_army: Army,
    defending_army_id: felt,
    defending_realm_id: Uint256,
    defending_army: Army,
) {
}

@event
func ArmyMetadata(army_id: felt, realm_id: Uint256, army_data: ArmyData) {
}

@event
func BuildArmy(
    army_id: felt,
    realm_id: Uint256,
    army: Army,
    battalion_ids_len: felt,
    battalion_ids: felt*,
    battalion_quantity_len: felt,
    battalion_quantity: felt*,
) {
}

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func xoroshiro_address() -> (address: felt) {
}

@storage_var
func battalion_cost(troop_id: felt) -> (cost: Cost) {
}

@storage_var
func army_data_by_id(army_id: felt, realm_id: Uint256) -> (army_data: ArmyData) {
}

// -----------------------------------
// Initialize & upgrade
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
// External
// -----------------------------------

// @notice Creates a new Army on Realm. Armies are comprised of Battalions.
// @param realm_id: Staked Realm ID (S_Realm)
// @param army_id: Army ID being added too.
// @param battalion_ids_len: Battlion IDs length
// @param battalion_ids: Battlion IDs
// @param battalions_len: Battalions lengh
// @param battalions: Battalions to add
@external
func build_army_from_battalions{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    realm_id: Uint256,
    army_id: felt,
    battalion_ids_len: felt,
    battalion_ids: felt*,
    battalion_quantity_len: felt,
    battalion_quantity: felt*,
) {
    alloc_locals;

    // TODO: assert can build army -> # max regions
    // TODO: can only add to the army if you are at homebase or friendly Realm

    Module.ERC721_owner_check(realm_id, ExternalContractIds.S_Realms);

    // check if Realm has the buildings to build the requested troops
    let (buildings_module) = Module.get_module_address(ModuleIds.Buildings);
    let (realm_buildings: RealmBuildings) = IBuildings.get_effective_buildings(
        buildings_module, realm_id
    );

    Combat.assert_can_build_battalions(battalion_ids_len, battalion_ids, realm_buildings);

    // get the Cost for every Troop to build
    // TODO: add in QUANTITY of battalions being built -> this is only getting 1 cost value
    let (battalion_costs: Cost*) = alloc();
    load_battalion_costs(battalion_ids_len, battalion_ids, battalion_costs);

    // transform costs into tokens
    let (token_len: felt, token_ids: Uint256*, token_values: Uint256*) = transform_costs_to_tokens(
        battalion_ids_len, battalion_costs, 1
    );

    // pay for the battalions
    let (caller) = get_caller_address();
    let (controller) = Module.controller_address();
    let (resource_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    );
    IERC1155.burnBatch(resource_address, caller, token_len, token_ids, token_len, token_values);

    // fetch packed army
    let (army_packed) = army_data_by_id.read(army_id, realm_id);
    let (army_unpacked: Army) = Combat.unpack_army(army_packed.ArmyPacked);

    // add battalions to Army and return new Army
    let (new_army: Army) = Combat.add_battalions_to_army(
        army_unpacked, battalion_ids_len, battalion_ids, battalion_quantity_len, battalion_quantity
    );

    // check battalions less than TOTAL_BATTALIONS
    let (total_battalions) = Combat.calculate_total_battalions(new_army);
    with_attr error_message("Combat: Too many battalions") {
        assert_lt(total_battalions, TOTAL_BATTALIONS + 1);
    }

    // update army on realm
    update_army_in_realm(army_id, new_army, realm_id);

    // emit new Army built
    BuildArmy.emit(
        army_id,
        realm_id,
        new_army,
        battalion_ids_len,
        battalion_ids,
        battalion_quantity_len,
        battalion_quantity,
    );

    return ();
}

// @notice Commence the attack
// @param attacking_realm_id: Staked Realm id (S_Realm)
// @param defending_realm_id: Staked Realm id (S_Realm)
// @return: combat_outcome: Which side won - either the attacker (COMBAT_OUTCOME_ATTACKER_WINS)
//                          or the defender (COMBAT_OUTCOME_DEFENDER_WINS)
@external
func initiate_combat{
    range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}(
    attacking_army_id: felt,
    attacking_realm_id: Uint256,
    defending_army_id: felt,
    defending_realm_id: Uint256,
) -> (combat_outcome: felt) {
    alloc_locals;

    with_attr error_message("Combat: Cannot initiate combat") {
        Module.ERC721_owner_check(attacking_realm_id, ExternalContractIds.S_Realms);
        let (can_attack) = Realm_can_be_attacked(
            attacking_army_id, attacking_realm_id, defending_army_id, defending_realm_id
        );
        assert can_attack = TRUE;
    }

    // Check Army is at actual Realm
    let (travel_module) = Module.get_module_address(ModuleIds.Travel);
    ITravel.assert_traveller_is_at_location(
        travel_module,
        ExternalContractIds.S_Realms,
        attacking_realm_id,
        attacking_army_id,
        ExternalContractIds.S_Realms,
        defending_realm_id,
        defending_army_id,
    );

    // check if the fighting realms have enough food, otherwise
    // decrease whole squad vitality by 50%

    // TODO: Food penalty with new module @NEW

    // let (food_module) = Module.get_module_address(ModuleIds.L10_Food)
    // let (attacker_food_store) = IFood.available_food_in_store(food_module, attacking_realm_id)
    // let (defender_food_store) = IFood.available_food_in_store(food_module, defending_realm_id)

    // if attacker_food_store == 0:
    //     let (attacker) = Combat.apply_hunger_penalty(attacker)
    //     tempvar range_check_ptr = range_check_ptr
    // else:
    //     tempvar attacker = attacker
    //     tempvar range_check_ptr = range_check_ptr
    // end
    // tempvar attacker = attacker

    // if defender_food_store == 0:
    //     let (defender) = Combat.apply_hunger_penalty(defender)
    //     tempvar range_check_ptr = range_check_ptr
    // else:
    //     tempvar defender = defender
    //     tempvar range_check_ptr = range_check_ptr
    // end
    // tempvar defender = defender

    // fetch combat data
    let (attacking_realm_data: ArmyData) = get_realm_army_combat_data(
        attacking_army_id, attacking_realm_id
    );
    let (defending_realm_data: ArmyData) = get_realm_army_combat_data(
        defending_army_id, defending_realm_id
    );

    // unpack armies
    let (starting_attack_army: Army) = Combat.unpack_army(attacking_realm_data.ArmyPacked);
    let (starting_defend_army: Army) = Combat.unpack_army(defending_realm_data.ArmyPacked);

    // emit starting
    CombatStart_4.emit(
        attacking_army_id,
        attacking_realm_id,
        starting_attack_army,
        defending_army_id,
        defending_realm_id,
        starting_defend_army,
    );

    // luck role and then outcome
    let (luck) = roll_dice();
    let (
        combat_outcome, ending_attacking_army_packed, ending_defending_army_packed
    ) = Combat.calculate_winner(
        luck, attacking_realm_data.ArmyPacked, defending_realm_data.ArmyPacked
    );

    // unpack
    let (ending_attacking_army: Army) = Combat.unpack_army(ending_attacking_army_packed);
    let (ending_defending_army: Army) = Combat.unpack_army(ending_defending_army_packed);

    // pillaging only if attacker wins
    let (now) = get_block_timestamp();
    if (combat_outcome == COMBAT_OUTCOME_ATTACKER_WINS) {
        let (controller) = Module.controller_address();
        let (resources_logic_address) = IModuleController.get_module_address(
            controller, ModuleIds.Resources
        );
        let (relic_address) = IModuleController.get_module_address(
            controller, ModuleIds.L09_Relics
        );
        let (caller) = get_caller_address();
        IResources.pillage_resources(resources_logic_address, defending_realm_id, caller);
        IRelics.set_relic_holder(relic_address, attacking_realm_id, defending_realm_id);

        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;

        tempvar attacking_xp = ATTACKING_ARMY_XP;
        tempvar defending_xp = DEFENDING_ARMY_XP;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;

        tempvar attacking_xp = DEFENDING_ARMY_XP;
        tempvar defending_xp = ATTACKING_ARMY_XP;
    }

    tempvar attacking_xp = attacking_xp;
    tempvar defending_xp = defending_xp;

    // store new values with added XP
    set_army_data_and_emit(
        attacking_army_id,
        attacking_realm_id,
        ArmyData(ending_attacking_army_packed, now, attacking_realm_data.XP + attacking_xp, attacking_realm_data.Level, attacking_realm_data.CallSign),
    );

    set_army_data_and_emit(
        defending_army_id,
        defending_realm_id,
        ArmyData(ending_defending_army_packed, now, defending_realm_data.XP + defending_xp, defending_realm_data.Level, defending_realm_data.CallSign),
    );

    // emit end
    CombatEnd_4.emit(
        combat_outcome,
        attacking_army_id,
        attacking_realm_id,
        ending_attacking_army,
        defending_army_id,
        defending_realm_id,
        ending_defending_army,
    );

    return (combat_outcome,);
}

// -----------------------------------
// Internal
// -----------------------------------

// @notice Update army in Realm
// @param army_id: Army ID
// @param army: Army to update
// @param realm_id: Realm ID
func update_army_in_realm{
    range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*
}(army_id: felt, army: Army, realm_id: Uint256) {
    alloc_locals;

    Module.ERC721_owner_check(realm_id, ExternalContractIds.S_Realms);

    // pack army
    let (new_packed_army) = Combat.pack_army(army);

    // retrieve stored data
    let (current_packed_army: ArmyData) = army_data_by_id.read(army_id, realm_id);

    set_army_data_and_emit(
        army_id,
        realm_id,
        ArmyData(new_packed_army, current_packed_army.LastAttacked, current_packed_army.XP, current_packed_army.Level, current_packed_army.CallSign),
    );

    return ();
}

// @notice saves data and emits the changed metadata for cache
// @param army_id: Army ID
// @param realm_id: Realm ID
// @param army_data: Army metadata
func set_army_data_and_emit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    army_id: felt, realm_id: Uint256, army_data: ArmyData
) {
    alloc_locals;

    // update state
    army_data_by_id.write(army_id, realm_id, army_data);

    // emit data
    ArmyMetadata.emit(army_id, realm_id, army_data);

    return ();
}

// @notice Load Battalion costs
func load_battalion_costs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    battlion_ids_len: felt, battlion_ids: felt*, costs: Cost*
) {
    alloc_locals;

    if (battlion_ids_len == 0) {
        return ();
    }

    let (cost: Cost) = get_battalion_cost([battlion_ids]);
    assert [costs] = cost;

    return load_battalion_costs(battlion_ids_len - 1, battlion_ids + 1, costs + Cost.SIZE);
}

// @notice Get number between 75 - 125
// @return Dice roll value, from 75 to 125 (inclusive)
func roll_dice{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}() -> (
    dice_roll: felt
) {
    alloc_locals;
    let (xoroshiro_address_) = xoroshiro_address.read();
    let (rnd) = IXoroshiro.next(xoroshiro_address_);

    // useful for testing:
    // local rnd
    // %{
    //     import random
    //     ids.rnd = random.randint(0, 5000)
    // %}
    let (_, r) = unsigned_div_rem(rnd, 50);
    return (r + 1 + 75,);  // values from 75 to 125 inclusive
}

// -----------------------------------
// Getters
// -----------------------------------

// @notice Get Battalion costs as Cost
@view
func get_battalion_cost{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    battalion_id: felt
) -> (cost: Cost) {
    let (c) = battalion_cost.read(battalion_id);
    return (c,);
}

// @notice Get Army Data
@view
func get_realm_army_combat_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    army_id: felt, realm_id: Uint256
) -> (army_data: ArmyData) {
    return army_data_by_id.read(army_id, realm_id);
}

// @notice Check if Realm an be attacked
@view
func Realm_can_be_attacked{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    attacking_army_id: felt,
    attacking_realm_id: Uint256,
    defending_army_id: felt,
    defending_realm_id: Uint256,
) -> (yesno: felt) {
    alloc_locals;

    let (controller) = Module.controller_address();

    let (defending_army_data: ArmyData) = get_realm_army_combat_data(
        defending_army_id, defending_realm_id
    );

    let (now) = get_block_timestamp();
    let diff = now - defending_army_data.LastAttacked;
    let was_attacked_recently = is_le(diff, ATTACK_COOLDOWN_PERIOD);

    if (was_attacked_recently == 1) {
        return (FALSE,);
    }

    // GET COMBAT DATA
    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    );
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms
    );
    let (attacking_realm_data: RealmData) = IRealms.fetch_realm_data(
        realms_address, attacking_realm_id
    );
    let (defending_realm_data: RealmData) = IRealms.fetch_realm_data(
        realms_address, defending_realm_id
    );

    if (attacking_realm_data.order == defending_realm_data.order) {
        // intra-order attacks are not allowed
        return (FALSE,);
    }

    // CANNOT ATTACK YOUR OWN
    let (attacking_realm_owner) = IERC721.ownerOf(s_realms_address, attacking_realm_id);
    let (defending_realm_owner) = IERC721.ownerOf(s_realms_address, defending_realm_id);

    if (attacking_realm_owner == defending_realm_owner) {
        return (FALSE,);
    }

    return (TRUE,);
}

//########
// ADMIN #
//########

@external
func set_troop_cost{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    troop_id: felt, cost: Cost
) {
    Proxy.assert_only_admin();
    battalion_cost.write(troop_id, cost);
    return ();
}

@external
func set_xoroshiro{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    xoroshiro: felt
) {
    Proxy.assert_only_admin();
    xoroshiro_address.write(xoroshiro);
    return ();
}
