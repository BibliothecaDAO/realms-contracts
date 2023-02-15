%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.math import assert_not_zero, assert_le, assert_not_equal, split_felt
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_number,
)
from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.utils.game_structs import (
    TravelInformation,
    ExternalContractIds,
    Point,
    ModuleIds,
)
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.utils.constants import CCombat
from contracts.settling_game.modules.combat.library import Combat
from contracts.settling_game.interfaces.IRealms import IRealms
from contracts.settling_game.modules.travel.interface import ITravel
from contracts.settling_game.modules.travel.library import Travel
from contracts.desiege.game_utils.grid_position import pack_position

from contracts.settling_game.modules.combat.interface import ICombat

// -----------------------------------
// Structs
// -----------------------------------

struct Bastion {
    bonus_type: felt,
    cooloff_block: felt,
    defending_order: felt,
}

// -----------------------------------
// Events
// -----------------------------------

@event
func BastionDefended(
    point: Point, defending_realm_id: Uint256, defending_army_id: felt, defending_line: felt
) {
}

@event
func BastionChangedOrder(point: Point, order: felt) {
}

// -----------------------------------
// Storage
// -----------------------------------

// Bastion cooloff in number of blocks
@storage_var
func bastion_cooloff() -> (cooloff_period: felt) {
}

// Bastions can be identified by point since you cannot have
// more than one bastion on one coordinate
@storage_var
func bastions(point: Point) -> (bastion: Bastion) {
}

// number of defenders on each defense line
@storage_var
func bastion_defender_count(point: Point, defense_line: felt) -> (count: felt) {
}

// defense line of an Army,
// 0 = not on any defense line
// can be on defense line 1 or 2
@storage_var
func bastion_defenders(point: Point, defending_realm_id: Uint256, defending_army_id: felt) -> (
    defense_line: felt
) {
}

// -----------------------------------
// Initialize & upgrade
// -----------------------------------

// @notice Module initializer
// @param address_of_controller: Controller/arbiter address
// @return proxy_admin: Proxy admin address
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

// @notice Creates bastions on given coordinates
// @param: points_len
// @param: points: Array of coordinates for each bastion
// @param: bonus_types_len
// @param: bonus_types: Array of bonus_types for each bastion
// @param: grid_dimension
@external
func spawn_bastions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    points_len: felt,
    points: Point*,
    bonus_types_len: felt,
    bonus_types: felt*,
    grid_dimension: felt,
) -> () {
    Proxy.assert_only_admin();
    assert points_len = bonus_types_len;
    loop_bastions(points_len, points, bonus_types_len, bonus_types, grid_dimension, 0);

    return ();
}

// @notice Attacks a bastion
// @param point: coordinates of bastion
// @param attacking_army_id
// @param attacking_realm_id
// @param defending_realm_id
// @param defending_army_id
@external
func attack_bastion{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    point: Point,
    attacking_army_id: felt,
    attacking_realm_id: Uint256,
    defending_realm_id: Uint256,
    defending_army_id: felt,
) -> () {
    alloc_locals;
    // before battle
    // verify that there is a bastion there
    let (bastion) = bastions.read(point);
    assert_not_zero(bastion.bonus_type);

    let (defense_line) = bastion_defenders.read(point, defending_realm_id, defending_army_id);
    // verify that there are defending armies on the bastion and that the defending_army_id is one of them
    with_attr error_message("Bastion: Defending army not present on the bastion defenses") {
        assert_not_zero(defense_line);
    }

    let (defense_line_1_count) = bastion_defender_count.read(point, 1);
    let (defense_line_2_count) = bastion_defender_count.read(point, 2);
    // if target defender is on line 2, all defenders on line 1 need to be defeated
    if (defense_line == 2) {
        with_attr error_message("Bastion: cannot attack defense line 2 when defenders on line 1") {
            assert defense_line_1_count = 0;
        }
    }

    // verify that the cooloff period was passed
    let (block_number) = get_block_number();
    with_attr error_message("Bastion: the cooloff period has not passed yet") {
        assert_le(bastion.cooloff_block, block_number);
    }

    // Does not verify that the owner is right and order is not the same because already done in combat module
    let (combat_address) = Module.get_module_address(ModuleIds.L06_Combat);
    let (combat_outcome) = ICombat.initiate_combat_approved_module(
        combat_address, attacking_army_id, attacking_realm_id, defending_army_id, defending_realm_id
    );

    local new_defense_line_1_count;
    local new_defense_line_2_count;
    // if beaten but still alive, puts the defender in second line of defense
    // if victory:
    if (combat_outcome == CCombat.COMBAT_OUTCOME_ATTACKER_WINS) {
        let (defending_army_data) = ICombat.get_realm_army_combat_data(
            combat_address, defending_army_id, defending_realm_id
        );
        let defending_army_population = Combat.population_of_army(defending_army_data.packed);

        // if no more army pop, decrease count and remove from current defense line
        if (defending_army_population == 0) {
            if (defense_line == 1) {
                new_defense_line_1_count = defense_line_1_count - 1;
                new_defense_line_2_count = defense_line_2_count;
            } else {
                new_defense_line_1_count = defense_line_1_count;
                new_defense_line_2_count = defense_line_2_count - 1;
            }

            bastion_defenders.write(point, defending_realm_id, defending_army_id, 0);
            BastionDefended.emit(
                point=point,
                defending_realm_id=defending_realm_id,
                defending_army_id=defending_army_id,
                defending_line=0,
            );
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            if (defense_line == 1) {
                // decrease the defender count of its defense line
                new_defense_line_1_count = defense_line_1_count - 1;
                new_defense_line_2_count = defense_line_2_count + 1;
                // put the defender in line 2
                bastion_defenders.write(point, defending_realm_id, defending_army_id, 2);
                BastionDefended.emit(
                    point=point,
                    defending_realm_id=defending_realm_id,
                    defending_army_id=defending_army_id,
                    defending_line=2,
                );
                tempvar syscall_ptr = syscall_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
                tempvar range_check_ptr = range_check_ptr;
            } else {
                tempvar syscall_ptr = syscall_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
                tempvar range_check_ptr = range_check_ptr;
            }
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
    }
    // update defender count
    bastion_defender_count.write(point, 1, new_defense_line_1_count);
    bastion_defender_count.write(point, 2, new_defense_line_2_count);

    // DISCUSS: can an attacker lose and still defenser has no more health point?
    // DISCUSS: Should defense population be checked even if you lose combat ?
    let total_defenders = new_defense_line_1_count + new_defense_line_2_count;
    // change when no more defenders
    local cooloff_block;
    local defending_order;
    // if no defender left, put attacker in defense and switch defending Order
    if (total_defenders == 0) {
        // change of Order
        // find the attacker order and replace defending order by attacking order
        let (realm_contract_address) = Module.get_external_contract_address(
            ExternalContractIds.Realms
        );
        let (attacker_realms_data) = IRealms.fetch_realm_data(
            realm_contract_address, attacking_realm_id
        );
        defending_order = attacker_realms_data.order;
        // change the cooloff period
        let (block_number) = get_block_number();
        let (cooloff_period) = bastion_cooloff.read();
        cooloff_block = block_number + cooloff_period;

        // Put the attacker as defender
        // DISCUSS: put previous attacker on defense line 2 by default
        bastion_defender_count.write(point, 2, 1);
        bastion_defenders.write(point, attacking_realm_id, attacking_army_id, 2);
        BastionDefended.emit(
            point=point,
            defending_realm_id=attacking_realm_id,
            defending_army_id=attacking_army_id,
            defending_line=2,
        );
        BastionChangedOrder.emit(point=point, order=attacker_realms_data.order);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
    } else {
        cooloff_block = bastion.cooloff_block;
        defending_order = bastion.defending_order;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr: BitwiseBuiltin* = bitwise_ptr;
    }

    bastions.write(
        point,
        Bastion(
            bonus_type=bastion.bonus_type,
            cooloff_block=cooloff_block,
            defending_order=defending_order,
        ),
    );

    return ();
}

// @notice Defend a bastion
// @dev You can also use this function to switch from one defense line to another
// @param point: coordinates of bastion
// @param defense_line: The defense line to be placed on
// @param defending_realm_id
// @param defending_army_id
@external
func join_defense_bastion{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    point: Point, defense_line: felt, defending_realm_id: Uint256, defending_army_id: felt
) -> () {
    alloc_locals;
    Module.ERC721_owner_check(defending_realm_id, ExternalContractIds.S_Realms);

    let (bastion) = bastions.read(point);

    with_attr error_message("Bastions: invalid defense line") {
        // Check that defense line is either 1 or 2
        assert [range_check_ptr] = defense_line - 1;
        assert [range_check_ptr + 1] = 2 - defense_line;
        let range_check_ptr = range_check_ptr + 2;
    }

    // verify that there is a bastion there
    with_attr error_message("Bastions: No bastion as this location") {
        assert_not_zero(bastion.bonus_type);
    }

    // verify that the defending army_id is at bastion location
    let (travel_address) = Module.get_module_address(ModuleIds.Travel);
    let (army_location) = ITravel.get_coordinates(
        travel_address, ExternalContractIds.S_Realms, defending_realm_id, defending_army_id
    );
    Travel.assert_same_points(army_location, point);

    // verify that the defending army is not defending already on that line
    let (current_defense_line) = bastion_defenders.read(
        point, defending_realm_id, defending_army_id
    );
    with_attr error_message("Bastion: army is already defending on this line") {
        assert_not_equal(current_defense_line, defense_line);
    }

    let (realm_contract_address) = Module.get_external_contract_address(ExternalContractIds.Realms);
    let (local defender_realms_data) = IRealms.fetch_realm_data(
        realm_contract_address, defending_realm_id
    );

    // if the order is null, this means that no order has taken control of the bastion yet
    local defending_order;
    if (bastion.defending_order == 0) {
        defending_order = defender_realms_data.order;
        BastionChangedOrder.emit(point=point, order=defender_realms_data.order);
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        defending_order = bastion.defending_order;
        with_attr error_message("Bastion: cannot defend on different order") {
            assert bastion.defending_order = defender_realms_data.order;
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    // update the new defense line and defense line count
    let (new_defense_line_count) = bastion_defender_count.read(point, defense_line);
    bastion_defender_count.write(point, defense_line, new_defense_line_count + 1);
    bastion_defenders.write(point, defending_realm_id, defending_army_id, defense_line);
    BastionDefended.emit(
        point=point,
        defending_realm_id=defending_realm_id,
        defending_army_id=defending_army_id,
        defending_line=defense_line,
    );

    // if defender was already on a defense line, also remove update that defense line count
    let is_already_defender = is_not_zero(current_defense_line);
    if (is_already_defender == TRUE) {
        let (current_defense_line_count) = bastion_defender_count.read(point, current_defense_line);
        bastion_defender_count.write(point, current_defense_line, current_defense_line_count - 1);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        // if was not on a defense line yet constraint travelling
        ITravel.forbid_travel(
            travel_address, ExternalContractIds.S_Realms, defending_realm_id, defending_army_id
        );
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }

    // update the bastion
    bastions.write(
        point,
        Bastion(
            bonus_type=bastion.bonus_type,
            cooloff_block=bastion.cooloff_block,
            defending_order=defending_order,
        ),
    );

    return ();
}

// @notice Leave defense of a bastion
// @dev You need to call this before being able to travel again
// @param point: Coordinates of the bastion
// @param defending_realm_id
// @param defending_army_id
@external
func leave_defense_bastion{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    point: Point, defending_realm_id: Uint256, defending_army_id: felt
) -> () {
    Module.ERC721_owner_check(defending_realm_id, ExternalContractIds.S_Realms);

    let (bastion) = bastions.read(point);

    // verify that the defending army is defending the wall
    let (defense_line) = bastion_defenders.read(point, defending_realm_id, defending_army_id);
    with_attr error_message("Bastion: army is not defending") {
        assert_not_zero(defense_line);
    }

    // update the new defense line count and remove army from defense
    let (new_defense_line_count) = bastion_defender_count.read(point, defense_line);
    bastion_defender_count.write(point, defense_line, new_defense_line_count - 1);
    bastion_defenders.write(point, defending_realm_id, defending_army_id, 0);
    BastionDefended.emit(
        point=point,
        defending_realm_id=defending_realm_id,
        defending_army_id=defending_army_id,
        defending_line=0,
    );

    let (travel_address) = Module.get_module_address(ModuleIds.Travel);
    // allow travel
    ITravel.allow_travel(
        travel_address, ExternalContractIds.S_Realms, defending_realm_id, defending_army_id
    );

    return ();
}

// -----------------------------------
// Internals
// -----------------------------------

// @notice Loops over array and sets bastion in storage
// @param points_len
// @param points: Array of coordinates for each bastion
// @param bonus_types_len
// @param bonus_types: Array of bonus_types for each bastion
// @param grid_dimension
// @param index: index for recursion
func loop_bastions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    points_len: felt,
    points: Point*,
    bonus_types_len: felt,
    bonus_types: felt*,
    grid_dimension: felt,
    index: felt,
) -> () {
    if (index == points_len) {
        return ();
    } else {
        bastions.write(
            points[index],
            Bastion(bonus_type=bonus_types[index], cooloff_block=0, defending_order=0),
        );
    }

    // use the coordinates as ID for the bastion
    // because can only have one bastion per coordinate
    let (bastion_id) = pack_position(grid_dimension, points[index].x, points[index].y);
    let (bastion_id_high, bastion_id_low) = split_felt(bastion_id);

    let (travel_address) = Module.get_module_address(ModuleIds.Travel);
    // set the coordinates with the travel module
    ITravel.set_coordinates(
        contract_address=travel_address,
        contract_id=ModuleIds.Bastions,
        token_id=Uint256(bastion_id_low, bastion_id_high),
        nested_id=0,
        point=points[index],
    );

    loop_bastions(points_len, points, bonus_types_len, bonus_types, grid_dimension, index + 1);

    return ();
}

// -----------------------------------
// Setters
// -----------------------------------

@external
func set_bastion_cooloff{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    bastion_cooloff_: felt
) -> () {
    Proxy.assert_only_admin();
    bastion_cooloff.write(bastion_cooloff_);
    return ();
}
