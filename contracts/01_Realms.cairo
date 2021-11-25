%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.math import (assert_nn_le,
    unsigned_div_rem, assert_not_zero)
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import (hash_init,
    hash_update, HashState)
from starkware.cairo.common.alloc import alloc

from contracts.utils.general import scale
from contracts.utils.interfaces import (IModuleController)


##### Module XX #####
#
####################



############ Game state ############

# Stores the address of the ModuleController.
@storage_var
func controller_address() -> (address : felt):
end

############ Admin Functions for Testing ############
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
