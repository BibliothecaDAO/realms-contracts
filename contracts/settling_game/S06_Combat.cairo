# ____MODULE_S06___COMBAT_STATE
#   State for combat between characters, troops, etc.
#
# MIT License

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le, split_int, unsigned_div_rem
from starkware.cairo.common.pow import pow
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.utils.game_structs import (
    Troop,
    Squad,
    PackedSquad,
    RealmCombatData,
    Cost,
)
from contracts.settling_game.library_combat import pack_squad, get_troop_internal

# used when adding or removing squads to Realms
const ATTACKING_SQUAD_SLOT = 1
const DEFENDING_SQUAD_SLOT = 2

from contracts.settling_game.utils.library import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
)
#
# storage
#

@storage_var
func realm_combat_data(realm_id : Uint256) -> (combat_data : RealmCombatData):
end

@storage_var
func troop_cost(troop_id : felt) -> (cost : Cost):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    controller_addr : felt):
    MODULE_initializer(controller_addr)
    return ()
end

#
# public
#

@view
func get_realm_combat_data{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    realm_id : Uint256
) -> (combat_data : RealmCombatData):
    let (combat_data) = realm_combat_data.read(realm_id)
    return (combat_data)
end

@external
func set_realm_combat_data{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    realm_id : Uint256, combat_data : RealmCombatData
):
    # TODO: auth checks! but how? this gets called from L06 after a combat
    realm_combat_data.write(realm_id, combat_data)
    return ()
end

@view
func get_troop_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    troop_id : felt
) -> (cost : Cost):
    let (cost) = troop_cost.read(troop_id)
    return (cost)
end

@external
func set_troop_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    troop_id : felt, cost : Cost
):
    # TODO: auth + range checks on the cost struct
    troop_cost.write(troop_id, cost)
    return ()
end

# can be used to add, overwrite or remove a Squad from a Realm
@external
func update_squad_in_realm{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    s : Squad, realm_id : Uint256, slot : felt
):
    alloc_locals
    # TODO: owner checks
    let (realm_combat_data : RealmCombatData) = get_realm_combat_data(realm_id)
    let (packed_squad : PackedSquad) = pack_squad(s)

    if slot == ATTACKING_SQUAD_SLOT:
        let new_realm_combat_data = RealmCombatData(
            attacking_squad=packed_squad,
            defending_squad=realm_combat_data.defending_squad,
            last_attacked_at=realm_combat_data.last_attacked_at,
        )
        set_realm_combat_data(realm_id, new_realm_combat_data)
        return ()
    else:
        let new_realm_combat_data = RealmCombatData(
            attacking_squad=realm_combat_data.attacking_squad,
            defending_squad=packed_squad,
            last_attacked_at=realm_combat_data.last_attacked_at,
        )
        set_realm_combat_data(realm_id, new_realm_combat_data)
        return ()
    end
end

@view
func get_troop{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(troop_id : felt) -> (t : Troop):
    let (t : Troop) = get_troop_internal(troop_id)
    return (t)
end
