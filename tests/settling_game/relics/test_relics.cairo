%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from starkware.cairo.common.bool import TRUE, FALSE
from lib.cairo_math_64x61.contracts.Math64x61 import Math64x61_div
from contracts.settling_game.utils.game_structs import (
    BuildingsFood,
    BuildingsPopulation,
    BuildingsCulture,
    RealmBuildings,
    BuildingsTroopIndustry,
)
from contracts.settling_game.library.library_relic import Relics

from tests.settling_game.utils.test_structs import TEST_REALM_BUILDINGS

const TROOP_POPULATION = 10

@external
func test_current_relic_holder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let holder_id = Uint256(0, 0)
    let relic_id = Uint256(1, 0)

    let (holder) = Relics._current_relic_holder(relic_id, holder_id)

    let (is_equal) = uint256_eq(relic_id, holder)

    assert is_equal = TRUE

    return ()
end

@external
func test_current_relic_holder_stolen{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    let holder_id = Uint256(3, 0)
    let relic_id = Uint256(1, 0)

    let (holder) = Relics._current_relic_holder(relic_id, holder_id)

    let (is_equal) = uint256_eq(holder_id, holder)

    assert is_equal = TRUE

    return ()
end
