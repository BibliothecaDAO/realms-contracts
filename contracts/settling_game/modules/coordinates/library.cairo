# -----------------------------------
#   COORDINATES
#   Logic around calculating distance between two points in Euclidean space.
#
#
#
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, sqrt
from starkware.cairo.common.math_cmp import is_nn_le, is_nn, is_le
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.pow import pow
from contracts.settling_game.utils.game_structs import Point

const SECONDS_PER_KM = 120
const PRECISION = 10000

namespace Coordinates:
    func calculate_distance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        Point_1 : Point, Point_2 : Point
    ) -> (distance : felt):
        alloc_locals
        # d = √((x2-x1)2 + (y2-y1)2)

        let (x) = pow(Point_2.x - Point_1.x, 2)
        let (y) = pow(Point_2.y - Point_1.y, 2)

        let (distance) = sqrt(x + y)

        # we store coords in x * 10000 to get precise distance

        let (d, _) = unsigned_div_rem(distance, PRECISION)

        return (d)
    end

    func calculate_time{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        distance : felt
    ) -> (time : felt):
        alloc_locals

        return (distance * SECONDS_PER_KM)
    end
end
