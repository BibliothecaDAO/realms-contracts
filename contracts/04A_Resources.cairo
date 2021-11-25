%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.pow import pow

from contracts.utils.interfaces import IModuleController

##### Module XX #####
#
# This module ...
#
#
####################

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

