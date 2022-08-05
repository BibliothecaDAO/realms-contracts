# -----------------------------------
# GoblinTown Library
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.math import unsigned_div_rem

from contracts.settling_game.utils.constants import SHIFT_8_9
from contracts.settling_game.utils.game_structs import RealmData


namespace GoblinTown:
    func pack{range_check_ptr}(strength : felt, spawn_ts : felt) -> (packed : felt):
        let packed = strength + spawn_ts * SHIFT_8_9
        return (packed)
    end

    func unpack{range_check_ptr}(packed : felt) -> (strength : felt, spawn_ts : felt):
        let (spawn_ts, strength) = unsigned_div_rem(packed, SHIFT_8_9)
        return (strength, spawn_ts)
    end

    func calculate_strength{range_check_ptr}(realm_data : RealmData, rnd : felt) -> (strength : felt):
        return (20) # TODO: base it on RealmData & resources
    end
end
