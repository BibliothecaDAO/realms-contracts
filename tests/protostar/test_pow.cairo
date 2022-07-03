%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_sub
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from contracts.settling_game.utils.game_structs import (
    BuildingsFood,
    BuildingsPopulation,
    BuildingsCulture,
    RealmBuildings,
    RealmBuildingsIds,
    BuildingsIntegrityLength,
    RealmBuildingsSize,
    BuildingsDecaySlope,
    Cost,
)
from contracts.settling_game.utils.pow2 import pow2

@external
func test_pow{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (p) = pow2(41)

    %{ print('Realm Happiness:', ids.p) %}

    return ()
end
