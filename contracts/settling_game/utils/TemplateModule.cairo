%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from contracts.settling_game.interfaces.imodules import IModuleController

from contracts.settling_game.utils.library import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
)

# ____MODULE_XXX___BUILDING_STATE
#
# This module [module functional description]
#
# It predominantly is used by modules [] and uses modules [].
#

# Steps - Copy and modify this template contract for new modules.
# 1. Assign the new module the next available number in the contracts/ folder.
# 2. Ensure state variables and application logic are in different modules. L & S
# 3. Expose any modifiable state variables with helper functions 'var_x_write()'.
# 4. Import any module dependencies from interfaces.imodules (above).
# 5. Document which modules this module will interact with (above).
# 6. Add deployment line to scripts/compile scripts/deploy.
# 7. Document which modules this module requires write access to.
# 8. Write tests in testing/XX_test.py and add to scripts/test.
# 9. +/- Add useful interfaces for this module to interfaces/imodules.cairo.
# 10. Delete this set of instructions.

###############
# CONSTRUCTOR #
###############

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt
):
    # Store the address of the only fixed contract in the system.
    MODULE_initializer(address_of_controller)
    return ()
end

############
# EXTERNAL #
############

# Called by another module to update a global variable.
@external
func update_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    # TODO Customise.
    MODULE_only_approved()
    return ()
end

###########
# GETTERS #
###########

###########
# SETTERS #
###########
