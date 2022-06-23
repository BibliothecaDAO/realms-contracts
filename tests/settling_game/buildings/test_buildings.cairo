%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div
from contracts.settling_game.utils.game_structs import (
    BuildingsFood,
    BuildingsPopulation,
    BuildingsCulture,
)
from contracts.settling_game.library.library_buildings import BUILDINGS
from starkware.cairo.common.pow import pow

const time_balance = 500
const decay_slope = 400
const building_id = 1

# @external
# func test_get_decay_rate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     alloc_locals

# let (decay_rate) = BUILDINGS.get_decay_rate(6, 400)

# %{ print(ids.decay_rate) %}
#     return ()
# end

# @external
# func test_get_effective_building_time{
#     syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
# }():
#     alloc_locals

# let (effective_buildings) = BUILDINGS.get_effective_building_time(2000, decay_rate)

# %{ print(ids.effective_buildings) %}
#     return ()
# end

@external
func test_get_building_left{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    # now - timestamp = param
    let (base_building_number) = BUILDINGS.get_base_building_left(time_balance)

    let (decay_slope) = BUILDINGS.get_decay_slope(1)

    # pass slope determined by building
    let (decay_rate) = BUILDINGS.get_decay_rate(base_building_number, decay_slope)

    # pass actual time balance + decay rate
    let (effective_building_time) = BUILDINGS.get_effective_building_time(time_balance, decay_rate)

    let (buildings_left) = BUILDINGS.get_effective_building_left(effective_building_time)

    %{ print(ids.base_building_number) %}
    %{ print(ids.decay_rate) %}
    %{ print(ids.effective_building_time) %}
    %{ print(ids.buildings_left) %}
    return ()
end
