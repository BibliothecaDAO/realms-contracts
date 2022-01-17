%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

############## Storage ################

# Stores the maximum amount of elements that should be minted
@storage_var
func elements_max() -> (max : felt):
end

# Stores the amount of elements minted for an L1,L2 address pair
@storage_var
func has_minted( l1_address : felt, l2_address : felt ) -> ( has_minted : felt ):
end

# Stores the contract address of the only account able to mint
@storage_var
func authorized_minter() -> ( minter_middleware : felt):
end

############## External Functions ################

@external
func mint_elements{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(

    ):
    only_authorized()

    # TODO 

    return ()

end

############## Internal Functions ################

# Will revert if caller is not the authorized minter
func only_authorized_minter{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():

    alloc_locals
    let (local caller) = get_caller_address()
    let (allowed_minter) = authorized_minter.read()
    assert caller = allowed_minter

    return ()
end