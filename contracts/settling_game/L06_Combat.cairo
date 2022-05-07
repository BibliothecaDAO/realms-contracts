# ____MODULE_L06___COMBAT_LOGIC
#   Logic for combat between characters, troops, etc.
#
# MIT License

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le, is_nn, is_nn_le
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp, get_caller_address

from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.imodules import (
    IModuleController,
    IL02_Resources,
    IS06_Combat,
)
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.library_combat import (
    build_squad_from_troops,
    compute_squad_stats,
    pack_squad,
    unpack_squad,
)
from contracts.settling_game.utils.game_structs import (
    ModuleIds,
    RealmData,
    RealmCombatData,
    Troop,
    Squad,
    SquadStats,
    PackedSquad,
    Cost,
    ExternalContractIds,
)
from contracts.settling_game.utils.general import unpack_data, transform_costs_to_token_ids_values
from contracts.settling_game.utils.library import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
)

from contracts.settling_game.utils.constants import (
    DAY
)

from openzeppelin.upgrades.library import (
    Proxy_initializer,
    Proxy_only_admin,
    Proxy_set_implementation,
    Proxy_get_implementation,
    Proxy_set_admin,
    Proxy_get_admin,
)

#
# events
#

@event
func Combat_outcome(attacking_realm_id : Uint256, defending_realm_id : Uint256, outcome : felt):
end

@event
func Combat_step(
    attacking_squad : Squad, defending_squad : Squad, attack_type : felt, hit_points : felt
):
end

@event
func Build_toops(troop_ids_len : felt, troop_ids : felt*, realm_id : Uint256, slot : felt):
end

#
# storage
#

@storage_var
func xoroshiro_address() -> (address : felt):
end

# a min delay between attacks on a Realm; it can't
# be attacked again during cooldown
const ATTACK_COOLDOWN_PERIOD = DAY  # 1 day unit

# sets the attack type when initiating combat
const COMBAT_TYPE_ATTACK_VS_DEFENSE = 1
const COMBAT_TYPE_WISDOM_VS_AGILITY = 2

# used to signal which side won the battle
const COMBAT_OUTCOME_ATTACKER_WINS = 1
const COMBAT_OUTCOME_DEFENDER_WINS = 2

# @constructor
# func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#     controller_addr : felt, xoroshiro_addr : felt
# ):
#     MODULE_initializer(controller_addr)
#     xoroshiro_address.write(xoroshiro_addr)
#     return ()
# end

@external
func initializer{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        address_of_controller : felt,
        xoroshiro_addr : felt,
        proxy_admin : felt
    ):
    MODULE_initializer(address_of_controller)
    xoroshiro_address.write(xoroshiro_addr)
    Proxy_initializer(proxy_admin)
    return ()
end

@external
func upgrade{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(new_implementation: felt):
    Proxy_only_admin()
    Proxy_set_implementation(new_implementation)
    return ()
end


# TODO: add owner checks

# TODO: write documentation

# TODO: emit events on each turn so we can display hits in UI

# TODO: take a Realm's wall into consideration when attacking a Realm

@view
func Realm_can_be_attacked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    attacking_realm_id : Uint256, defending_realm_id : Uint256
) -> (yesno : felt):
    # TODO: write tests for this

    alloc_locals

    let (controller) = MODULE_controller_address()
    let (combat_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S06_Combat
    )
    let (realm_combat_data : RealmCombatData) = IS06_Combat.get_realm_combat_data(
        combat_state_address, defending_realm_id
    )

    let (now) = get_block_timestamp()
    let diff = now - realm_combat_data.last_attacked_at
    let (was_attacked_recently) = is_le(diff, ATTACK_COOLDOWN_PERIOD)

    if was_attacked_recently == 1:
        return (FALSE)
    end

    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    )

    let (attacking_realm_data : RealmData) = realms_IERC721.fetch_realm_data(
        contract_address=realms_address, token_id=attacking_realm_id
    )
    let (defending_realm_data : RealmData) = realms_IERC721.fetch_realm_data(
        contract_address=realms_address, token_id=defending_realm_id
    )

    if attacking_realm_data.order == defending_realm_data.order:
        # intra-order attacks are not allowed
        return (FALSE)
    end

    return (TRUE)
end

@external
func build_squad_from_troops_in_realm{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(troop_ids_len : felt, troop_ids : felt*, realm_id : Uint256, slot : felt):
    alloc_locals

    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()
    let (combat_state_address) = IModuleController.get_module_address(
        controller, ModuleIds.S06_Combat
    )

    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms
    )

    let (owner) = realms_IERC721.ownerOf(s_realms_address, realm_id)

    with_attr error_message("COMBAT: Not your realm ser"):
        assert caller = owner
    end

    # get the Cost for every Troop to build
    let (troop_costs : Cost*) = alloc()
    load_troop_costs(combat_state_address, troop_ids_len, troop_ids, 0, troop_costs)

    # transform costs into tokens
    let (token_ids : Uint256*) = alloc()
    let (token_values : Uint256*) = alloc()
    let (token_len : felt) = transform_costs_to_token_ids_values(
        troop_ids_len, troop_costs, token_ids, token_values
    )

    # pay for the squad
    let (resource_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    )
    IERC1155.burnBatch(resource_address, caller, token_len, token_ids, token_len, token_values)

    # assemble the squad, store it in a Realm
    let (squad) = build_squad_from_troops(troop_ids_len, troop_ids)
    IS06_Combat.update_squad_in_realm(combat_state_address, squad, realm_id, slot)

    Build_toops.emit(troop_ids_len, troop_ids, realm_id, slot)

    return ()
end

@view
func view_troops{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    realm_id : Uint256
) -> (attacking_troops : Squad, defending_troops : Squad):
    alloc_locals
    let (controller) = MODULE_controller_address()
    let (combat_state_address) = IModuleController.get_module_address(
        controller, module_id=ModuleIds.S06_Combat
    )
    let (realm_data : RealmCombatData) = IS06_Combat.get_realm_combat_data(
        combat_state_address, realm_id
    )

    let (attacking_squad : Squad) = unpack_squad(realm_data.attacking_squad)
    let (defending_squad : Squad) = unpack_squad(realm_data.defending_squad)

    return(attacking_squad, defending_squad)
end

@external
func initiate_combat{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    attacking_realm_id : Uint256, defending_realm_id : Uint256, attack_type : felt
) -> (combat_outcome : felt):
    alloc_locals

    let (controller) = MODULE_controller_address()
    let (caller) = get_caller_address()

    with_attr error_message("COMBAT: Cannot initiate combat"):
        let (can_attack) = Realm_can_be_attacked(attacking_realm_id, defending_realm_id)
        let (s_realms_address) = IModuleController.get_external_contract_address(
            controller, ExternalContractIds.S_Realms
        )
        let (owner) = realms_IERC721.ownerOf(s_realms_address, attacking_realm_id)
        assert caller = owner
        assert can_attack = TRUE
    end

    let (combat_state_address) = IModuleController.get_module_address(
        controller, module_id=ModuleIds.S06_Combat
    )
    let (attacking_realm_data : RealmCombatData) = IS06_Combat.get_realm_combat_data(
        combat_state_address, attacking_realm_id
    )
    let (defending_realm_data : RealmCombatData) = IS06_Combat.get_realm_combat_data(
        combat_state_address, defending_realm_id
    )

    let (attacker : Squad) = unpack_squad(attacking_realm_data.attacking_squad)
    let (defender : Squad) = unpack_squad(defending_realm_data.defending_squad)

    let (attacker_end, defender_end, combat_outcome) = run_combat_loop(
        attacker, defender, attack_type
    )

    let (new_attacker : PackedSquad) = pack_squad(attacker_end)
    let (new_defender : PackedSquad) = pack_squad(defender_end) 

    let new_attacking_realm_data = RealmCombatData(
        attacking_squad=new_attacker,
        defending_squad=attacking_realm_data.defending_squad,
        last_attacked_at=attacking_realm_data.last_attacked_at,
    )
    IS06_Combat.set_realm_combat_data(combat_state_address, attacking_realm_id, new_attacking_realm_data)

    let (now) = get_block_timestamp()
    let new_defending_realm_data = RealmCombatData(
        attacking_squad=defending_realm_data.attacking_squad,
        defending_squad=new_defender,
        last_attacked_at=now,
    )
    IS06_Combat.set_realm_combat_data(combat_state_address, defending_realm_id, new_defending_realm_data)

    # pillaging only if attacker wins
    if combat_outcome == COMBAT_OUTCOME_ATTACKER_WINS:
        let (resources_logic_address) = IModuleController.get_module_address(
            controller, ModuleIds.L02_Resources
        )
        let (caller) = get_caller_address()
        IL02_Resources.pillage_resources(resources_logic_address, defending_realm_id, caller)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    Combat_outcome.emit(attacking_realm_id, defending_realm_id, combat_outcome)

    return (combat_outcome)
end

func run_combat_loop{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    attacker : Squad, defender : Squad, attack_type : felt
) -> (attacker : Squad, defender : Squad, outcome : felt):
    alloc_locals

    let (step_defender) = attack(attacker, defender, attack_type)
    # because hits are distributed from tier 1 troops to tier 3, if the only tier 3
    # troop has 0 vitality, we can assume the whole squad has been defeated
    if step_defender.t3_1.vitality == 0:
        # defender is defeated
        return (attacker, step_defender, COMBAT_OUTCOME_ATTACKER_WINS)
    end

    let (step_attacker) = attack(step_defender, attacker, attack_type)
    if step_attacker.t3_1.vitality == 0:
        # attacker is defeated
        return (step_attacker, step_defender, COMBAT_OUTCOME_DEFENDER_WINS)
    end

    return run_combat_loop(step_attacker, step_defender, attack_type)
end

func attack{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    a : Squad, d : Squad, attack_type : felt
) -> (d_after_attack : Squad):
    alloc_locals

    let (a_stats) = compute_squad_stats(a)
    let (d_stats) = compute_squad_stats(d)

    if attack_type == COMBAT_TYPE_ATTACK_VS_DEFENSE:
        # attacker attacks with attack against defense,
        # has attack-times dice rolls
        let (min_roll_to_hit) = compute_min_roll_to_hit(a_stats.attack, d_stats.defense)
        let (hit_points) = roll_attack_dice(a_stats.attack, min_roll_to_hit, 0)
        tempvar range_check_ptr = range_check_ptr
        tempvar syscall_ptr : felt* = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        # COMBAT_TYPE_WISDOM_VS_AGILITY
        # attacker attacks with wisdom against agility,
        # has wisdom-times dice rolls
        let (min_roll_to_hit) = compute_min_roll_to_hit(a_stats.wisdom, d_stats.agility)
        let (hit_points) = roll_attack_dice(a_stats.wisdom, min_roll_to_hit, 0)
        tempvar range_check_ptr = range_check_ptr
        tempvar syscall_ptr : felt* = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    tempvar hit_points = hit_points
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr

    let (d_after_attack) = hit_squad(d, hit_points)
    Combat_step.emit(a, d, attack_type, hit_points)
    return (d_after_attack)
end

# min(math.ceil((a / d) * 7), 12)
func compute_min_roll_to_hit{range_check_ptr}(a : felt, d : felt) -> (min_roll : felt):
    alloc_locals

    # in case there's no defence, any attack will succeed
    if d == 0:
        return (0)
    end

    let (q, r) = unsigned_div_rem(a * 7, d)
    local t
    if r == 0:
        t = q
    else:
        t = q + 1
    end

    # 12 sided die => max throw is 12
    let (is_within_range) = is_le(t, 12)
    if is_within_range == 0:
        return (12)
    end

    return (t)
end

func roll_attack_dice{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    dice_count : felt, hit_threshold : felt, successful_hits_acc
) -> (successful_hits : felt):
    # 12 sided dice, 1...12
    # only values >= hit threshold constitute a successful attack
    alloc_locals

    if dice_count == 0:
        return (successful_hits_acc)
    end

    let (xoroshiro_address_) = xoroshiro_address.read()
    let (rnd) = IXoroshiro.next(contract_address=xoroshiro_address_)
    let (_, r) = unsigned_div_rem(rnd, 12)
    let (is_successful_hit) = is_le(hit_threshold, r)
    return roll_attack_dice(dice_count - 1, hit_threshold, successful_hits_acc + is_successful_hit)
end

func hit_squad{range_check_ptr}(s : Squad, hits : felt) -> (squad : Squad):
    alloc_locals

    let (t1_1, remaining_hits) = hit_troop(s.t1_1, hits)
    let (t1_2, remaining_hits) = hit_troop(s.t1_2, remaining_hits)
    let (t1_3, remaining_hits) = hit_troop(s.t1_3, remaining_hits)
    let (t1_4, remaining_hits) = hit_troop(s.t1_4, remaining_hits)
    let (t1_5, remaining_hits) = hit_troop(s.t1_5, remaining_hits)
    let (t1_6, remaining_hits) = hit_troop(s.t1_6, remaining_hits)
    let (t1_7, remaining_hits) = hit_troop(s.t1_7, remaining_hits)
    let (t1_8, remaining_hits) = hit_troop(s.t1_8, remaining_hits)
    let (t1_9, remaining_hits) = hit_troop(s.t1_9, remaining_hits)
    let (t1_10, remaining_hits) = hit_troop(s.t1_10, remaining_hits)
    let (t1_11, remaining_hits) = hit_troop(s.t1_11, remaining_hits)
    let (t1_12, remaining_hits) = hit_troop(s.t1_12, remaining_hits)
    let (t1_13, remaining_hits) = hit_troop(s.t1_13, remaining_hits)
    let (t1_14, remaining_hits) = hit_troop(s.t1_14, remaining_hits)
    let (t1_15, remaining_hits) = hit_troop(s.t1_15, remaining_hits)
    let (t1_16, remaining_hits) = hit_troop(s.t1_16, remaining_hits)

    let (t2_1, remaining_hits) = hit_troop(s.t2_1, remaining_hits)
    let (t2_2, remaining_hits) = hit_troop(s.t2_2, remaining_hits)
    let (t2_3, remaining_hits) = hit_troop(s.t2_3, remaining_hits)
    let (t2_4, remaining_hits) = hit_troop(s.t2_4, remaining_hits)
    let (t2_5, remaining_hits) = hit_troop(s.t2_5, remaining_hits)
    let (t2_6, remaining_hits) = hit_troop(s.t2_6, remaining_hits)
    let (t2_7, remaining_hits) = hit_troop(s.t2_7, remaining_hits)
    let (t2_8, remaining_hits) = hit_troop(s.t2_8, remaining_hits)

    let (t3_1, _) = hit_troop(s.t3_1, remaining_hits)

    let s = Squad(
        t1_1=t1_1,
        t1_2=t1_2,
        t1_3=t1_3,
        t1_4=t1_4,
        t1_5=t1_5,
        t1_6=t1_6,
        t1_7=t1_7,
        t1_8=t1_8,
        t1_9=t1_9,
        t1_10=t1_10,
        t1_11=t1_11,
        t1_12=t1_12,
        t1_13=t1_13,
        t1_14=t1_14,
        t1_15=t1_15,
        t1_16=t1_16,
        t2_1=t2_1,
        t2_2=t2_2,
        t2_3=t2_3,
        t2_4=t2_4,
        t2_5=t2_5,
        t2_6=t2_6,
        t2_7=t2_7,
        t2_8=t2_8,
        t3_1=t3_1,
    )

    return (s)
end

func hit_troop{range_check_ptr}(t : Troop, hits : felt) -> (
    hit_troop : Troop, remaining_hits : felt
):
    if hits == 0:
        return (t, 0)
    end

    let (kills_troop) = is_le(t.vitality, hits)
    if kills_troop == 1:
        # t.vitality <= hits
        let ht = Troop(
            type=t.type,
            tier=t.tier,
            agility=t.agility,
            attack=t.attack,
            defense=t.defense,
            vitality=0,
            wisdom=t.wisdom,
        )
        let rem = hits - t.vitality
        return (ht, rem)
    else:
        # t.vitality > hits
        let ht = Troop(
            type=t.type,
            tier=t.tier,
            agility=t.agility,
            attack=t.attack,
            defense=t.defense,
            vitality=t.vitality - hits,
            wisdom=t.wisdom,
        )
        return (ht, 0)
    end
end

func load_troop_costs{syscall_ptr : felt*, range_check_ptr}(
    state_module_address : felt,
    troop_ids_len : felt,
    troop_ids : felt*,
    costs_idx : felt,
    costs : Cost*,
):
    alloc_locals

    if troop_ids_len == 0:
        return ()
    end

    # TODO: make the function accept and return an array so we don't have to do
    #       cross-contract calls in a loop
    let (cost : Cost) = IS06_Combat.get_troop_cost(state_module_address, [troop_ids])
    assert [costs + costs_idx] = cost

    return load_troop_costs(
        state_module_address, troop_ids_len - 1, troop_ids + 1, costs_idx + 1, costs
    )
end
