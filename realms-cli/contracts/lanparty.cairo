# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

# Define a storage variable.
@storage_var
func score(player: felt) -> (res : felt):
end

# Increases the balance by the given amount.
@external
func increase_score{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(amount : felt):
    # Obtain the address of the account contract.
    let (player) = get_caller_address()

    # Read and update its balance.
    let (res) = score.read(player=player)
    score.write(player, res + amount)
    return ()
end

# Returns the current balance.
@view
func get_score{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(player: felt) -> (res : felt):
    let (res) = score.read(player=player)
    return (res)
end