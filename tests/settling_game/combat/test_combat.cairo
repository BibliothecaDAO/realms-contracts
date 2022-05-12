%lang starknet
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div
from contracts.settling_game.utils.game_structs import BuildingsFood, BuildingsPopulation, BuildingsCulture
from contracts.settling_game.interfaces.imodules import IArbiter, IL06_Combat
from contracts.settling_game.utils.game_structs import RealmBuildings, RealmCombatData, Cost, Squad

const ids = 1
const length = 1

@external
func test_combat{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    let (local troop_ids : felt*) = alloc()

    let (local troop_ids_2 : felt*) = alloc()

    assert troop_ids[0] = 1

    assert troop_ids_2[0] = 1
    assert troop_ids_2[1] = 2

    local L06_Combat : felt
    local L06_Proxy_Combat : felt

    %{ ids.L06_Combat = deploy_contract("./contracts/settling_game/L06_Combat.cairo", []).contract_address %}
    %{ ids.L06_Proxy_Combat = deploy_contract("./contracts/settling_game/proxy/PROXY_Logic.cairo", [ids.L06_Combat]).contract_address %}

    IL06_Combat.set_troop_cost(L06_Proxy_Combat, 1, Cost(3, 8, 262657, 328450))
    IL06_Combat.set_troop_cost(L06_Proxy_Combat, 2, Cost(3, 8, 262657, 656900))
    
    IL06_Combat.build_squad_from_troops_in_realm(L06_Proxy_Combat, 1, troop_ids, Uint256(1, 0), 1)
    IL06_Combat.build_squad_from_troops_in_realm(L06_Proxy_Combat, 2, troop_ids_2, Uint256(1, 0), 1)

    %{ mock_call(ids.L06_Proxy_Combat, "view_troops", [1, 0]) %}
    let (attacking_s: Squad, defending_s: Squad) = IL06_Combat.view_troops(L06_Proxy_Combat, Uint256(1, 0))

    %{ print(ids.attacking_s) %}
    return ()
end
