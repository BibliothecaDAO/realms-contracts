// -----------------------------------
// ____Module.Combat (ORIGINAL)
//   Logic around original Combat system

// ELI5:
// This module is currently not in use.
//
//
//
// MIT License

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    get_tx_info,
    get_contract_address,
)

from openzeppelin.upgrades.library import Proxy
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721

from contracts.settling_game.interfaces.IERC1155 import IERC1155

from contracts.settling_game.interfaces.imodules import IModuleController
from contracts.settling_game.modules.calculator.interface import ICalculator
from contracts.settling_game.modules.goblintown.interface import IGoblinTown
from contracts.settling_game.modules.food.interface import IFood
from contracts.settling_game.modules.relics.interface import IRelics
from contracts.settling_game.modules.resources.interface import IResources
from contracts.settling_game.modules.buildings.interface import IBuildings
from contracts.settling_game.interfaces.IRealms import IRealms
from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.library.library_combat import Combat

from contracts.settling_game.utils.constants import (
    ATTACK_COOLDOWN_PERIOD,
    COMBAT_OUTCOME_ATTACKER_WINS,
    COMBAT_OUTCOME_DEFENDER_WINS,
    ATTACKING_SQUAD_SLOT,
    POPULATION_PER_HIT_POINT,
    MAX_WALL_DEFENSE_HIT_POINTS,
    GOBLINDOWN_REWARD,
    DEFENDING_SQUAD_SLOT,
)
from contracts.settling_game.utils.game_structs import (
    ModuleIds,
    RealmData,
    RealmCombatData,
    RealmBuildings,
    Troop,
    Squad,
    SquadStats,
    Cost,
    ExternalContractIds,
)
from contracts.settling_game.utils.general import unpack_data, transform_costs_to_tokens
from contracts.settling_game.library.library_module import Module

from contracts.settling_game.utils.constants import DAY

from contracts.settling_game.modules.travel.interface import ITravel

// -----------------------------------
// Events
// -----------------------------------

@event
func CombatStart_3(
    attacking_realm_id: Uint256,
    defending_realm_id: Uint256,
    attacking_squad: Squad,
    defending_squad: Squad,
) {
}

@event
func CombatOutcome_3(
    attacking_realm_id: Uint256,
    defending_realm_id: Uint256,
    attacking_squad: Squad,
    defending_squad: Squad,
    outcome: felt,
) {
}

@event
func CombatStep_3(
    attacking_realm_id: Uint256,
    defending_realm_id: Uint256,
    attacking_squad: Squad,
    defending_squad: Squad,
    hit_points: felt,
) {
}

@event
func BuildTroops_3(
    squad: Squad, troop_ids_len: felt, troop_ids: felt*, realm_id: Uint256, slot: felt
) {
}

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func xoroshiro_address() -> (address: felt) {
}

@storage_var
func realm_combat_data(realm_id: Uint256) -> (combat_data: RealmCombatData) {
}

@storage_var
func troop_cost(troop_id: felt) -> (cost: Cost) {
}

//##############
// CONSTRUCTOR #
//##############

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @param xoroshiro_addr: Address of a PRNG contract conforming to IXoroshiro
// @proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address_of_controller: felt, xoroshiro_addr: felt, proxy_admin: felt
) {
    Module.initializer(address_of_controller);
    xoroshiro_address.write(xoroshiro_addr);
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

//###########
// EXTERNAL #
//###########

// @notice Create a new attacking or defending Squad from Troops in Realm
// @param troop_ids: array of TroopId values of the troops to be built/bought
// @param realm_id: Staked Realm ID (S_Realm)
// @param slot: one of ATTACKING_SQUAD_SLOT or DEFENDING_SQUAD_SLOT values, designating
//              where the Squad should be assigned to in the Realm
@external
func build_squad_from_troops_in_realm{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(troop_ids_len: felt, troop_ids: felt*, realm_id: Uint256, slot: felt) {
    alloc_locals;

    Combat.assert_slot(slot);

    Module.ERC721_owner_check(realm_id, ExternalContractIds.S_Realms);

    // check if Realm has the buildings to build the requested troops
    let (buildings_module) = Module.get_module_address(ModuleIds.Buildings);
    let (realm_buildings: RealmBuildings) = IBuildings.get_effective_buildings(
        buildings_module, realm_id
    );
    Combat.assert_can_build_troops(troop_ids_len, troop_ids, realm_buildings);

    // get the Cost for every Troop to build
    let (troop_costs: Cost*) = alloc();
    load_troop_costs(troop_ids_len, troop_ids, troop_costs);

    // transform costs into tokens
    let (token_len: felt, token_ids: Uint256*, token_values: Uint256*) = transform_costs_to_tokens(
        troop_ids_len, troop_costs, 1
    );

    // pay for the squad
    let (caller) = get_caller_address();
    let (controller) = Module.controller_address();
    let (resource_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    );
    IERC1155.burnBatch(resource_address, caller, token_len, token_ids, token_len, token_values);

    // assemble the squad, store it in a Realm
    let (realm_combat_data: RealmCombatData) = get_realm_combat_data(realm_id);
    if (slot == ATTACKING_SQUAD_SLOT) {
        let current_squad: Squad = Combat.unpack_squad(realm_combat_data.attacking_squad);
    } else {
        let current_squad: Squad = Combat.unpack_squad(realm_combat_data.defending_squad);
    }
    let (squad) = Combat.add_troops_to_squad(current_squad, troop_ids_len, troop_ids);
    update_squad_in_realm(squad, realm_id, slot);

    BuildTroops_3.emit(squad, troop_ids_len, troop_ids, realm_id, slot);

    return ();
}

// @notice Commence the raid
// @param attacking_realm_id: Staked Realm id (S_Realm)
// @param defending_realm_id: Staked Realm id (S_Realm)
// @return: combat_outcome: Which side won - either the attacker (COMBAT_OUTCOME_ATTACKER_WINS)
//                          or the defender (COMBAT_OUTCOME_DEFENDER_WINS)
@external
func initiate_combat{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    attacking_realm_id: Uint256, defending_realm_id: Uint256
) -> (combat_outcome: felt) {
    alloc_locals;

    with_attr error_message("Combat: Cannot initiate combat") {
        Module.ERC721_owner_check(attacking_realm_id, ExternalContractIds.S_Realms);
        let (can_attack) = Realm_can_be_attacked(attacking_realm_id, defending_realm_id);
        assert can_attack = TRUE;
    }

    // Check Army is at actual Realm
    // let (travel_module) = Module.get_module_address(ModuleIds.Travel);
    // ITravel.assert_traveller_is_at_location(
    //     travel_module,
    //     ExternalContractIds.S_Realms,
    //     attacking_realm_id,
    //     attacking_army_id,
    //     ExternalContractIds.S_Realms,
    //     defending_realm_id,
    //     defending_army_id,
    // );

    let (attacking_realm_data: RealmCombatData) = get_realm_combat_data(attacking_realm_id);
    let (defending_realm_data: RealmCombatData) = get_realm_combat_data(defending_realm_id);

    let (attacker: Squad) = Combat.unpack_squad(attacking_realm_data.attacking_squad);
    let (defender: Squad) = Combat.unpack_squad(defending_realm_data.defending_squad);

    // check if the fighting realms have enough food, otherwise
    // decrease whole squad vitality by 50%
    let (food_module) = Module.get_module_address(ModuleIds.L10_Food);
    let (attacker_food_store) = IFood.available_food_in_store(food_module, attacking_realm_id);
    let (defender_food_store) = IFood.available_food_in_store(food_module, defending_realm_id);

    if (attacker_food_store == 0) {
        let (attacker) = Combat.apply_hunger_penalty(attacker);
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar attacker = attacker;
        tempvar range_check_ptr = range_check_ptr;
    }
    tempvar attacker = attacker;

    if (defender_food_store == 0) {
        let (defender) = Combat.apply_hunger_penalty(defender);
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar defender = defender;
        tempvar range_check_ptr = range_check_ptr;
    }
    tempvar defender = defender;

    // EMIT FIRST
    CombatStart_3.emit(attacking_realm_id, defending_realm_id, attacker, defender);

    let (attacker_breached_wall: Squad) = inflict_wall_defense(attacker, defending_realm_id);

    let (attacker_end, defender_end, combat_outcome) = run_combat_loop(
        attacking_realm_id, defending_realm_id, attacker_breached_wall, defender
    );

    let (new_attacker: felt) = Combat.pack_squad(attacker_end);
    let (new_defender: felt) = Combat.pack_squad(defender_end);

    let new_attacking_realm_data = RealmCombatData(
        attacking_squad=new_attacker,
        defending_squad=attacking_realm_data.defending_squad,
        last_attacked_at=attacking_realm_data.last_attacked_at,
    );
    set_realm_combat_data(attacking_realm_id, new_attacking_realm_data);

    let (now) = get_block_timestamp();
    let new_defending_realm_data = RealmCombatData(
        attacking_squad=defending_realm_data.attacking_squad,
        defending_squad=new_defender,
        last_attacked_at=now,
    );
    set_realm_combat_data(defending_realm_id, new_defending_realm_data);

    // # pillaging only if attacker wins
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
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }

    CombatOutcome_3.emit(
        attacking_realm_id, defending_realm_id, attacker_end, defender_end, combat_outcome
    );

    return (combat_outcome,);
}

// @notice Remove one or more troops from a particular Squad
// @param troop_idxs: Array of indexes of Troops to be removed form a Squad (0-based indexing)
// @param realm_id: Staked Realm id (S_Realm)
// @param slot: one of ATTACKING_SQUAD_SLOT or DEFENDING_SQUAD_SLOT values, designating
//              which Squad to remove the troops from
@external
func remove_troops_from_squad_in_realm{
    range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*
}(troop_idxs_len: felt, troop_idxs: felt*, realm_id: Uint256, slot: felt) {
    alloc_locals;

    Combat.assert_slot(slot);

    Module.ERC721_owner_check(realm_id, ExternalContractIds.S_Realms);

    let (realm_combat_data: RealmCombatData) = get_realm_combat_data(realm_id);

    if (slot == ATTACKING_SQUAD_SLOT) {
        let (squad) = Combat.unpack_squad(realm_combat_data.attacking_squad);
    } else {
        let (squad) = Combat.unpack_squad(realm_combat_data.defending_squad);
    }

    let (updated_squad) = Combat.remove_troops_from_squad(squad, troop_idxs_len, troop_idxs);
    update_squad_in_realm(updated_squad, realm_id, slot);

    return ();
}

@external
func attack_goblin_town{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    realm_id: Uint256
) -> (outcome: felt) {
    alloc_locals;

    Module.ERC721_owner_check(realm_id, ExternalContractIds.S_Realms);

    let (goblin_town_address) = Module.get_module_address(ModuleIds.GoblinTown);
    let (strength, spawn_ts) = IGoblinTown.get_strength_and_timestamp(
        goblin_town_address, realm_id
    );

    // check if there are goblins and if not, silently succeed
    let (now) = get_block_timestamp();
    let has_goblins = is_le(spawn_ts, now);
    if (has_goblins == FALSE) {
        return (TRUE,);
    }

    // get goblin squad
    let (goblins: Squad) = Combat.build_goblin_squad(strength);

    // get attacking squad
    let (realm_data: RealmCombatData) = get_realm_combat_data(realm_id);
    let (attacker: Squad) = Combat.unpack_squad(realm_data.attacking_squad);

    // apply hunger penalty if there's not enough food
    let (food_module) = Module.get_module_address(ModuleIds.L10_Food);
    let (food_store) = IFood.available_food_in_store(food_module, realm_id);
    if (food_store == 0) {
        with_attr error_message("GOBLINTOWN: You can't attack without food!!") {
            assert 1 = 0;
        }
    }

    // using 0 for the defending realm ID; it's only being used to emit events in the combat loop
    let zero_id = Uint256(0, 0);
    // fight
    CombatStart_3.emit(realm_id, zero_id, attacker, goblins);
    let (attacker_end, goblins_end, outcome) = run_combat_loop(
        realm_id, zero_id, attacker, goblins
    );

    let (new_attacker: felt) = Combat.pack_squad(attacker_end);
    let new_realm_data = RealmCombatData(
        attacking_squad=new_attacker,
        defending_squad=realm_data.defending_squad,
        last_attacked_at=realm_data.last_attacked_at,
    );
    set_realm_combat_data(realm_id, new_realm_data);

    // if successful, earn $lords

    if (outcome == COMBAT_OUTCOME_ATTACKER_WINS) {
        // attack was successful, goblin town defeated
        let (this) = get_contract_address();
        // Lord earns $LORDS
        let (caller) = get_caller_address();
        let (lords_address) = Module.get_external_contract_address(ExternalContractIds.Lords);
        IERC20.approve(lords_address, caller, Uint256(GOBLINDOWN_REWARD * 10 ** 18, 0));
        IERC20.transfer(lords_address, caller, Uint256(GOBLINDOWN_REWARD * 10 ** 18, 0));

        // new goblin town is spawned
        let (goblin_town_address) = Module.get_module_address(ModuleIds.GoblinTown);
        IGoblinTown.spawn_next(goblin_town_address, realm_id);

        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    CombatOutcome_3.emit(realm_id, zero_id, attacker_end, goblins_end, outcome);

    return (outcome,);
}

//###########
// INTERNAL #
//###########

func set_realm_combat_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    realm_id: Uint256, combat_data: RealmCombatData
) {
    realm_combat_data.write(realm_id, combat_data);
    return ();
}

// @notice Function simulating an attacking Squad breaching a Realm's wall and
//         catching some damage as a result
// @param attacker: The attacking Squad
// @param defending_realm_id: Staked Realm ID of the defending Realm
// @return damaged: Attacking squad after breaching the wall
func inflict_wall_defense{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    attacker: Squad, defending_realm_id: Uint256
) -> (damaged: Squad) {
    alloc_locals;

    let (controller: felt) = Module.controller_address();
    let (calculator_addr: felt) = IModuleController.get_module_address(
        controller, ModuleIds.Calculator
    );
    // let (defending_population : felt) = ICalculator.calculate_population(
    //     calculator_addr, defending_realm_id
    // )

    let (q, _) = unsigned_div_rem(5, POPULATION_PER_HIT_POINT);
    let is_in_range = is_le(q, MAX_WALL_DEFENSE_HIT_POINTS);
    if (is_in_range == TRUE) {
        tempvar hit_points = q;
    } else {
        tempvar hit_points = MAX_WALL_DEFENSE_HIT_POINTS;
    }

    let (_, idx) = Combat.get_first_vital_troop(attacker);
    let (damaged: Squad) = Combat.hit_troop_in_squad(attacker, idx, hit_points);
    return (damaged,);
}

// @notice The core combat logic. Alternates attacks between two squads until
//         one of them is at 0 total vitality.
// @param attacking_realm_id: Staked Realm ID of the attacking Realm
// @param defending_realm_id: Staked Realm ID of the defending Realm
// @param attacker: Attacking squad entering the combat
// @param defender: Defending squad entering the combat
// @return attacker: Attacking squad after the combat has finished
// @return defender: Defending squad after the combat has finished
// @return outcome: One of COMBAT_OUTCOME_ATTACKER_WINS, COMBAT_OUTCOME_DEFENDER_WINS consts
//                  specifying which side won
func run_combat_loop{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    attacking_realm_id: Uint256, defending_realm_id: Uint256, attacker: Squad, defender: Squad
) -> (attacker: Squad, defender: Squad, outcome: felt) {
    alloc_locals;

    let (step_defender) = attack(attacking_realm_id, defending_realm_id, attacker, defender);

    let (defender_vitality) = Combat.compute_squad_vitality(step_defender);
    if (defender_vitality == 0) {
        // defender is defeated
        return (attacker, step_defender, COMBAT_OUTCOME_ATTACKER_WINS);
    }

    let (step_attacker) = attack(attacking_realm_id, defending_realm_id, step_defender, attacker);
    let (attacker_vitality) = Combat.compute_squad_vitality(step_attacker);
    if (attacker_vitality == 0) {
        // attacker is defeated
        return (step_attacker, step_defender, COMBAT_OUTCOME_DEFENDER_WINS);
    }

    return run_combat_loop(attacking_realm_id, defending_realm_id, step_attacker, step_defender);
}

// @notice Function performing a single step of the combat, a one-sided attack
// @param attacking_realm_id: Staked Realm ID of the attacking Realm
// @param defending_realm_id: Staked Realm ID of the defending Realm
// @param a: Attacking squad entering the attack step
// @param d: Defending squad entering the attack step
// @return d_after_attack: Defending squad after the attack step
func attack{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    attacking_realm_id: Uint256, defending_realm_id: Uint256, a: Squad, d: Squad
) -> (d_after_attack: Squad) {
    alloc_locals;

    let (attacker: Troop, _) = Combat.get_first_vital_troop(a);
    let (defender: Troop, d_index) = Combat.get_first_vital_troop(d);

    let (dice_roll) = roll_dice();
    let (hit_points) = Combat.calculate_hit_points(attacker, defender, dice_roll);

    let (d_after_attack: Squad) = Combat.hit_troop_in_squad(d, d_index, hit_points);
    CombatStep_3.emit(attacking_realm_id, defending_realm_id, a, d_after_attack, hit_points);
    return (d_after_attack,);
}

// @notice Perform a 12 sided dice roll
// @return Dice roll value, from 1 to 12 (inclusive)
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
    let (_, r) = unsigned_div_rem(rnd, 12);
    return (r + 1,);  // values from 1 to 12 inclusive
}

// @notice Populate an array of Cost structs with the proper values
// @param troop_ids: An array of troops for which we need to load the costs
// @param costs: A pointer to a Cost memory segment that gets populated
func load_troop_costs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    troop_ids_len: felt, troop_ids: felt*, costs: Cost*
) {
    alloc_locals;

    if (troop_ids_len == 0) {
        return ();
    }

    let (cost: Cost) = get_troop_cost([troop_ids]);
    assert [costs] = cost;

    return load_troop_costs(troop_ids_len - 1, troop_ids + 1, costs + Cost.SIZE);
}

// @notice Modify (overwrite) a Squad in a Realm
// @param s: New squad
// @param realm_id: Staked Realm ID in which to modify the squad
// @param slot: Which squad to modify. One of ATTACKING_SQUAD_SLOT or DEFENDING_SQUAD_SLOT
func update_squad_in_realm{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    s: Squad, realm_id: Uint256, slot: felt
) {
    alloc_locals;

    Module.ERC721_owner_check(realm_id, ExternalContractIds.S_Realms);

    let (realm_combat_data: RealmCombatData) = get_realm_combat_data(realm_id);
    let (packed_squad: felt) = Combat.pack_squad(s);

    if (slot == ATTACKING_SQUAD_SLOT) {
        let new_realm_combat_data = RealmCombatData(
            attacking_squad=packed_squad,
            defending_squad=realm_combat_data.defending_squad,
            last_attacked_at=realm_combat_data.last_attacked_at,
        );
        set_realm_combat_data(realm_id, new_realm_combat_data);
        return ();
    } else {
        let new_realm_combat_data = RealmCombatData(
            attacking_squad=realm_combat_data.attacking_squad,
            defending_squad=packed_squad,
            last_attacked_at=realm_combat_data.last_attacked_at,
        );
        set_realm_combat_data(realm_id, new_realm_combat_data);
        return ();
    }
}

//##########
// GETTERS #
//##########

@view
func view_troops{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    realm_id: Uint256
) -> (attacking_troops: Squad, defending_troops: Squad) {
    alloc_locals;

    let (realm_data: RealmCombatData) = get_realm_combat_data(realm_id);

    let (attacking_squad: Squad) = Combat.unpack_squad(realm_data.attacking_squad);
    let (defending_squad: Squad) = Combat.unpack_squad(realm_data.defending_squad);

    return (attacking_squad, defending_squad);
}

@view
func get_xoroshiro{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (x: felt) {
    let (xoroshiro) = xoroshiro_address.read();
    return (xoroshiro,);
}

@view
func get_troop{range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(troop_id: felt) -> (t: Troop) {
    let (t: Troop) = Combat.get_troop_internal(troop_id);
    return (t,);
}

@view
func get_realm_combat_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    realm_id: Uint256
) -> (combat_data: RealmCombatData) {
    let (combat_data) = realm_combat_data.read(realm_id);
    return (combat_data,);
}

@view
func get_troop_cost{range_check_ptr, syscall_ptr: felt*, pedersen_ptr: HashBuiltin*}(
    troop_id: felt
) -> (cost: Cost) {
    let (cost) = troop_cost.read(troop_id);
    return (cost,);
}

@view
func Realm_can_be_attacked{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    attacking_realm_id: Uint256, defending_realm_id: Uint256
) -> (yesno: felt) {
    alloc_locals;

    let (controller) = Module.controller_address();

    let (realm_combat_data: RealmCombatData) = get_realm_combat_data(defending_realm_id);

    let (now) = get_block_timestamp();
    let diff = now - realm_combat_data.last_attacked_at;
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
    troop_cost.write(troop_id, cost);
    return ();
}

@external
func set_xoroshiro{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    xoroshiro: felt
) {
    // TODO:
    // Proxy.assert_only_admin()
    xoroshiro_address.write(xoroshiro);
    return ();
}

@external
func zero_dead_squads{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    realm_id: Uint256
) {
    alloc_locals;
    Proxy.assert_only_admin();
    let (now) = get_block_timestamp();
    let new_realm_combat_data = RealmCombatData(
        attacking_squad=0, defending_squad=0, last_attacked_at=now
    );
    set_realm_combat_data(realm_id, new_realm_combat_data);

    let new_squad: Squad = Combat.unpack_squad(0);

    let (troop: felt*) = alloc();
    assert troop[0] = 1;

    BuildTroops_3.emit(new_squad, 1, troop, realm_id, ATTACKING_SQUAD_SLOT);
    BuildTroops_3.emit(new_squad, 1, troop, realm_id, DEFENDING_SQUAD_SLOT);
    return ();
}
