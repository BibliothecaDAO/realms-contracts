%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from contracts.settling_game.utils.game_structs import ModuleIds

from contracts.settling_game.utils.constants import TRUE, FALSE

# #### Controller #####
#
# A long-lived open-ended lookup table.
#
# Is in control of the addresses game modules use.
# Is controlled by the Arbiter, who can update addresses.
# Maintains a generic mapping that is open ended and which
# can be added to for new modules.

# Modules are organised by numbers: a particular module (storage
# of player health, or a new game module) will have a module_id which
# will be used by other components, even if the underlying contract
# address changes.

#######################
# To be compliant with this system, a new module containint variables
# intended to be open to the ecosystem MUST implement a check
# on any contract.
# 1. Get address attempting to write to the variables in the contract.
# 2. Call 'has_write_access()'

# This way, new modules can be added to update existing systems a
# and create new dynamics.

# #### Storage #####
# Stores the address of the Arbiter contract.
@storage_var
func arbiter() -> (address : felt):
end

# The contract address for a module.
@storage_var
func address_of_module_id(module_id : felt) -> (address : felt):
end

# The module id of a contract address.
@storage_var
func module_id_of_address(address : felt) -> (module_id : felt):
end

# A mapping of which modules have write access to the others. 1=yes.
@storage_var
func can_write_to(doing_writing : felt, being_written_to : felt) -> (bool : felt):
end

# Contract addresses
@storage_var
func lords_address() -> (address : felt):
end

@storage_var
func resources_address() -> (address : felt):
end

@storage_var
func realms_address() -> (address : felt):
end

@storage_var
func treasury_address() -> (address : felt):
end

@storage_var
func s_realms_address() -> (address : felt):
end

# #### Constructor #####
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        arbiter_address : felt, _lords_address : felt, _resources_address : felt,
        _realms_address : felt, _treasury_address : felt, _s_realms_address : felt):
    arbiter.write(arbiter_address)

    # write patterns known at deployment. E.g., 1->2, 1->3, 5->6.

    # settling to state
    can_write_to.write(ModuleIds.L01_Settling, ModuleIds.S01_Settling, TRUE)

    # resources logic to state
    can_write_to.write(ModuleIds.L02_Resources, ModuleIds.S02_Resources, TRUE)

    # buildings to state
    can_write_to.write(ModuleIds.L03_Buildings, ModuleIds.S03_Buildings, TRUE)

    # Contracts
    # TODO: Move to namespaces for easy upgradablity
    lords_address.write(_lords_address)
    resources_address.write(_resources_address)
    realms_address.write(_realms_address)
    treasury_address.write(_treasury_address)
    s_realms_address.write(_s_realms_address)
    return ()
end

# #### External functions #####
# Called by the current Arbiter to replace itself.
@external
func appoint_new_arbiter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        new_arbiter : felt):
    only_arbiter()
    arbiter.write(new_arbiter)
    return ()
end

# Called by the Arbiter to set new address mappings.
@external
func set_address_for_module_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        module_id : felt, module_address : felt):
    only_arbiter()
    module_id_of_address.write(module_address, module_id)
    address_of_module_id.write(module_id, module_address)

    return ()
end

# Called by the Arbiter to batch set new address mappings on deployment.
@external
func set_initial_module_addresses{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        module_01_addr : felt, module_02_addr : felt, module_03_addr : felt, module_04_addr : felt,
        module_05_addr : felt, module_06_addr : felt, module_07_addr : felt):
    only_arbiter()

    # # Settling Logic
    address_of_module_id.write(ModuleIds.L01_Settling, module_01_addr)
    module_id_of_address.write(module_01_addr, ModuleIds.L01_Settling)

    # # Settling State
    address_of_module_id.write(ModuleIds.S01_Settling, module_02_addr)
    module_id_of_address.write(module_02_addr, ModuleIds.S01_Settling)

    # # Resources Logic
    address_of_module_id.write(ModuleIds.L02_Resources, module_03_addr)
    module_id_of_address.write(module_03_addr, ModuleIds.L02_Resources)

    # # Resources State
    address_of_module_id.write(ModuleIds.S02_Resources, module_04_addr)
    module_id_of_address.write(module_04_addr, ModuleIds.S02_Resources)

    # # Buildings Logic
    address_of_module_id.write(ModuleIds.L03_Buildings, module_05_addr)
    module_id_of_address.write(module_05_addr, ModuleIds.L03_Buildings)

    # # Buildings State
    address_of_module_id.write(ModuleIds.S03_Buildings, module_06_addr)
    module_id_of_address.write(module_06_addr, ModuleIds.S03_Buildings)

    # # Calculator Logic
    address_of_module_id.write(ModuleIds.L04_Calculator, module_07_addr)
    module_id_of_address.write(module_07_addr, ModuleIds.L04_Calculator)
    return ()
end

# Called to authorise write access of one module to another.
@external
func set_write_access{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        module_id_doing_writing : felt, module_id_being_written_to : felt):
    only_arbiter()
    can_write_to.write(module_id_doing_writing, module_id_being_written_to, 1)
    return ()
end

# #### View functions #####
@view
func get_module_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        module_id : felt) -> (address : felt):
    let (address) = address_of_module_id.read(module_id)
    return (address)
end

@view
func get_lords_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        address : felt):
    let (address) = lords_address.read()
    return (address)
end

@view
func get_realms_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        address : felt):
    let (address) = realms_address.read()
    return (address)
end

@view
func get_resources_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        address : felt):
    let (address) = resources_address.read()
    return (address)
end

@view
func get_treasury_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        address : felt):
    let (address) = treasury_address.read()
    return (address)
end

@view
func get_s_realms_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        address : felt):
    let (address) = s_realms_address.read()
    return (address)
end

# Called by a module before it updates internal state.
@view
func has_write_access{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_attempting_to_write : felt):
    alloc_locals

    # Approves the write-permissions between two modules, ensuring
    # first that the modules are both active (not replaced), and
    # then that write-access has been given.

    # Get the address of the module calling (being written to).
    let (caller) = get_caller_address()
    let (module_id_being_written_to) = module_id_of_address.read(caller)

    # Make sure the module has not been replaced.
    let (local current_module_address) = address_of_module_id.read(module_id_being_written_to)
    assert current_module_address = caller

    # Get the module id of the contract that is trying to write.
    let (module_id_attempting_to_write) = module_id_of_address.read(address_attempting_to_write)
    # Make sure that module has not been replaced.
    let (local active_address) = address_of_module_id.read(module_id_attempting_to_write)
    assert active_address = address_attempting_to_write

    # See if the module has permission.
    let (bool) = can_write_to.read(module_id_attempting_to_write, module_id_being_written_to)
    assert_not_zero(bool)
    return ()
end

# #### Private functions #####
# Assert that the person calling has authority.
func only_arbiter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (local caller) = get_caller_address()
    let (current_arbiter) = arbiter.read()
    assert caller = current_arbiter
    return ()
end
