%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.starknet.common.syscalls import get_caller_address

from contracts.utils.general import list_to_hash

from contracts.utils.interfaces import (IModuleController)

##### Module 05 #####
#
#
#################


@storage_var
func controller_address() -> (address : felt):
end


# Called on deployment only.
@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        address_of_controller : felt
    ):
    # Store the address of the only fixed contract in the system.
    controller_address.write(address_of_controller)
    return ()
end
