# STAKING LIBRARY
#   Helper functions for staking.
#
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import Uint256

@storage_var
func time_staked(token_id : Uint256) -> (time : felt):
end

namespace STAKING:
    func set_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, time_left : felt
    ):
        let (block_timestamp) = get_block_timestamp()
        time_staked.write(token_id, block_timestamp - time_left)
        return ()
    end

    func get_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256
    ) -> (time : felt):
        let (time) = time_staked.read(token_id)

        return (time=time)
    end
end
