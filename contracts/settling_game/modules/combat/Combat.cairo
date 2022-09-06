# ____MODULE_L06___COMBAT_LOGIC
#   Logic for combat between characters, troops, etc.
#
# MIT License

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
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.modules.calculator.interface import ICalculator
from contracts.settling_game.interfaces.imodules import (
    IModuleController,
    IL02_Resources,
    IL03_Buildings,
    IL09_Relics,
    IFood,
    IGoblinTown,
)
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.ixoroshiro import IXoroshiro
from contracts.settling_game.modules.combat.library import Combat

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

from contracts.settling_game.modules.combat.constants import (
    BattalionDefence,
    SHIFT_ARMY,
    Battalion,
    Army,
    ArmyStatistics,
    BattlionIds,
    ArmyData,
)

# -----------------------------------
# Events
# -----------------------------------

# @event
# func CombatStart_4(
#     attacking_realm_id : Uint256,
#     defending_realm_id : Uint256,
#     attacking_army : Army,
#     defending_army : Army,
#     attacking_army_id : felt,
#     defending_army_id : felt,
# ):
# end

@event
func CombatEnd_4(
    attacking_realm_id : Uint256,
    defending_realm_id : Uint256,
    attacking_army : Army,
    defending_army : Army,
    attacking_army_id : felt,
    defending_army_id : felt,
):
end
# @event
# func CombatStart_3(
#     attacking_realm_id : Uint256,
#     defending_realm_id : Uint256,
#     attacking_squad : Squad,
#     defending_squad : Squad,
# ):
# end

# @event
# func CombatOutcome_3(
#     attacking_realm_id : Uint256,
#     defending_realm_id : Uint256,
#     attacking_squad : Squad,
#     defending_squad : Squad,
#     outcome : felt,
# ):
# end

# @event
# func CombatStep_3(
#     attacking_realm_id : Uint256,
#     defending_realm_id : Uint256,
#     attacking_squad : Squad,
#     defending_squad : Squad,
#     hit_points : felt,
# ):
# end

@event
func BuildBattalion(
    army : Army, troop_ids_len : felt, troop_ids : felt*, realm_id : Uint256, army_id : felt
):
end

# -----------------------------------
# Storage
# -----------------------------------

@storage_var
func xoroshiro_address() -> (address : felt):
end

@storage_var
func realm_combat_data(realm_id : Uint256) -> (combat_data : RealmCombatData):
end

@storage_var
func troop_cost(troop_id : felt) -> (cost : Cost):
end

@storage_var
func army_data_by_id(army_id : felt, realm_id : Uint256) -> (army_data : ArmyData):
end

###############
# CONSTRUCTOR #
###############

# @notice Module initializer
# @param address_of_controller: Controller/arbiter address
# @param xoroshiro_addr: Address of a PRNG contract conforming to IXoroshiro
# @proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt, xoroshiro_addr : felt, proxy_admin : felt
):
    Module.initializer(address_of_controller)
    xoroshiro_address.write(xoroshiro_addr)
    Proxy.initializer(proxy_admin)
    return ()
end

# @notice Set new proxy implementation
# @dev Can only be set by the arbiter
# @param new_implementation: New implementation contract address
@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy.assert_only_admin()
    Proxy._set_implementation_hash(new_implementation)
    return ()
end

############
# EXTERNAL #
############

# @notice Create a new attacking or defending Squad from Troops in Realm
# @param troop_ids: array of TroopId values of the troops to be built/bought
# @param realm_id: Staked Realm ID (S_Realm)
# @param slot: one of ATTACKING_SQUAD_SLOT or DEFENDING_SQUAD_SLOT values, designating
#              where the Squad should be assigned to in the Realm
@external
func build_army_from_battalions{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(troop_ids_len : felt, troop_ids : felt*, realm_id : Uint256, army_id : felt):
    alloc_locals

    # TODO: assert can build army -> # max regions
    # TODO: can only add to the army if you are at homebase or friendly Realm
    # Combat.assert_slot(army_id)

    Module.ERC721_owner_check(realm_id, ExternalContractIds.S_Realms)

    # check if Realm has the buildings to build the requested troops
    let (buildings_module) = Module.get_module_address(ModuleIds.L03_Buildings)
    let (realm_buildings : RealmBuildings) = IL03_Buildings.get_effective_buildings(
        buildings_module, realm_id
    )
    # Combat.assert_can_build_troops(troop_ids_len, troop_ids, realm_buildings)

    # get the Cost for every Troop to build
    let (troop_costs : Cost*) = alloc()
    load_troop_costs(troop_ids_len, troop_ids, troop_costs)

    # transform costs into tokens
    let (
        token_len : felt, token_ids : Uint256*, token_values : Uint256*
    ) = transform_costs_to_tokens(troop_ids_len, troop_costs, 1)

    # pay for the squad
    let (caller) = get_caller_address()
    let (controller) = Module.controller_address()
    let (resource_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    )
    IERC1155.burnBatch(resource_address, caller, token_len, token_ids, token_len, token_values)

    # fetch packed army
    let (army_packed) = army_data_by_id.read(army_id, realm_id)

    let (army_unpacked : Army) = Combat.unpack_army(army_packed.ArmyPacked)

    # TODO: add battalions to army and return and

    # let (squad) = Combat.add_troops_to_squad(current_squad, troop_ids_len, troop_ids)

    # update_squad_in_realm(squad, realm_id, slot)

    # BuildBattalion.emit(squad, troop_ids_len, troop_ids, realm_id, slot)

    return ()
end

# @notice Commence the raid
# @param attacking_realm_id: Staked Realm id (S_Realm)
# @param defending_realm_id: Staked Realm id (S_Realm)
# @return: combat_outcome: Which side won - either the attacker (COMBAT_OUTCOME_ATTACKER_WINS)
#                          or the defender (COMBAT_OUTCOME_DEFENDER_WINS)
@external
func initiate_combat{
    range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*
}(
    attacking_army_id : felt,
    attacking_realm_id : Uint256,
    defending_army_id : felt,
    defending_realm_id : Uint256,
) -> (combat_outcome : felt):
    alloc_locals

    with_attr error_message("Combat: Cannot initiate combat"):
        Module.ERC721_owner_check(attacking_realm_id, ExternalContractIds.S_Realms)
        let (can_attack) = Realm_can_be_attacked(
            attacking_army_id, attacking_realm_id, defending_army_id, defending_realm_id
        )
        assert can_attack = TRUE
    end

    # Check Army is at actual Realm
    let (travel_module) = Module.get_module_address(ModuleIds.Travel)
    ITravel.assert_traveller_is_at_location(
        travel_module,
        ExternalContractIds.S_Realms,
        attacking_realm_id,
        ExternalContractIds.S_Realms,
        defending_realm_id,
    )

    let (attacking_realm_data : ArmyData) = get_realm_army_combat_data(
        attacking_army_id, attacking_realm_id
    )
    let (defending_realm_data : ArmyData) = get_realm_army_combat_data(
        defending_army_id, defending_realm_id
    )

    let (attacker : Army) = Combat.unpack_army(attacking_realm_data.ArmyPacked)
    let (defender : Army) = Combat.unpack_army(defending_realm_data.ArmyPacked)

    # check if the fighting realms have enough food, otherwise
    # decrease whole squad vitality by 50%

    # TODO: Food penalty with new module @NEW

    # let (food_module) = Module.get_module_address(ModuleIds.L10_Food)
    # let (attacker_food_store) = IFood.available_food_in_store(food_module, attacking_realm_id)
    # let (defender_food_store) = IFood.available_food_in_store(food_module, defending_realm_id)

    # if attacker_food_store == 0:
    #     let (attacker) = Combat.apply_hunger_penalty(attacker)
    #     tempvar range_check_ptr = range_check_ptr
    # else:
    #     tempvar attacker = attacker
    #     tempvar range_check_ptr = range_check_ptr
    # end
    # tempvar attacker = attacker

    # if defender_food_store == 0:
    #     let (defender) = Combat.apply_hunger_penalty(defender)
    #     tempvar range_check_ptr = range_check_ptr
    # else:
    #     tempvar defender = defender
    #     tempvar range_check_ptr = range_check_ptr
    # end
    # tempvar defender = defender

    # TODO: Add in random number generator between 75-125 as the 'luck' - set at 75 below  @NEW @MILAN
    let (combat_outcome, attacking_army, defending_army) = Combat.calculate_winner(
        75, attacking_realm_data.ArmyPacked, defending_realm_data.ArmyPacked
    )

    # EMIT FIRST
    # CombatStart_3.emit(attacking_realm_id, defending_realm_id, attacker, defender)

    # let (attacker_breached_wall : Squad) = inflict_wall_defense(attacker, defending_realm_id)

    # let (attacker_end, defender_end, combat_outcome) = run_combat_loop(
    #     attacking_realm_id, defending_realm_id, attacker_breached_wall, defender
    # )

    # let (new_attacker : felt) = Combat.pack_squad(attacker_end)
    # let (new_defender : felt) = Combat.pack_squad(defender_end)

    # let new_attacking_realm_data = RealmCombatData(
    #     attacking_squad=new_attacker,
    #     defending_squad=attacking_realm_data.defending_squad,
    #     last_attacked_at=attacking_realm_data.last_attacked_at,
    # )
    # set_realm_combat_data(attacking_realm_id, new_attacking_realm_data)

    # let (now) = get_block_timestamp()

    # let new_defending_realm_data = RealmCombatData(
    #     attacking_squad=defending_realm_data.attacking_squad,
    #     defending_squad=new_defender,
    #     last_attacked_at=now,
    # )
    # set_realm_combat_data(defending_realm_id, new_defending_realm_data)

    # # pillaging only if attacker wins
    if combat_outcome == COMBAT_OUTCOME_ATTACKER_WINS:
        let (controller) = Module.controller_address()
        let (resources_logic_address) = IModuleController.get_module_address(
            controller, ModuleIds.L02_Resources
        )
        let (relic_address) = IModuleController.get_module_address(controller, ModuleIds.L09_Relics)
        let (caller) = get_caller_address()
        IL02_Resources.pillage_resources(resources_logic_address, defending_realm_id, caller)
        IL09_Relics.set_relic_holder(relic_address, attacking_realm_id, defending_realm_id)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    # CombatOutcome_3.emit(
    #     attacking_realm_id, defending_realm_id, attacker_end, defender_end, combat_outcome
    # )

    return (combat_outcome)
end

############
# INTERNAL #
############

# @notice Populate an array of Cost structs with the proper values
# @param troop_ids: An array of troops for which we need to load the costs
# @param costs: A pointer to a Cost memory segment that gets populated
func load_troop_costs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    troop_ids_len : felt, troop_ids : felt*, costs : Cost*
):
    alloc_locals

    if troop_ids_len == 0:
        return ()
    end

    let (cost : Cost) = get_troop_cost([troop_ids])
    assert [costs] = cost

    return load_troop_costs(troop_ids_len - 1, troop_ids + 1, costs + Cost.SIZE)
end

@view
func get_troop_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    troop_id : felt
) -> (cost : Cost):
    let (cost) = troop_cost.read(troop_id)
    return (cost)
end

@view
func Realm_can_be_attacked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    attacking_army_id : felt,
    attacking_realm_id : Uint256,
    defending_army_id : felt,
    defending_realm_id : Uint256,
) -> (yesno : felt):
    alloc_locals

    let (controller) = Module.controller_address()

    # TODO: Only allow attacking of realm ids 0 ??
    let (realm_combat_data : ArmyData) = get_realm_army_combat_data(
        defending_army_id, defending_realm_id
    )

    let (now) = get_block_timestamp()
    let diff = now - realm_combat_data.LastAttacked
    let (was_attacked_recently) = is_le(diff, ATTACK_COOLDOWN_PERIOD)

    if was_attacked_recently == 1:
        return (FALSE)
    end

    # GET COMBAT DATA
    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    )
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms
    )
    let (attacking_realm_data : RealmData) = realms_IERC721.fetch_realm_data(
        realms_address, attacking_realm_id
    )
    let (defending_realm_data : RealmData) = realms_IERC721.fetch_realm_data(
        realms_address, defending_realm_id
    )

    if attacking_realm_data.order == defending_realm_data.order:
        # intra-order attacks are not allowed
        return (FALSE)
    end

    # CANNOT ATTACK YOUR OWN
    let (attacking_realm_owner) = realms_IERC721.ownerOf(s_realms_address, attacking_realm_id)
    let (defending_realm_owner) = realms_IERC721.ownerOf(s_realms_address, defending_realm_id)

    if attacking_realm_owner == defending_realm_owner:
        return (FALSE)
    end

    return (TRUE)
end

@view
func get_realm_army_combat_data{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    army_id : felt, realm_id : Uint256
) -> (army_data : ArmyData):
    return army_data_by_id.read(army_id, realm_id)
end
