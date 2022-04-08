# TODO: Add Contract Title
#   TODO: Add Contract Description
# 
# MIT License

%lang starknet

from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.access.ownable import Ownable_initializer, Ownable_only_owner

from openzeppelin.utils.constants import TRUE

###########
# STORAGE #
###########

# RESOURCES #

@storage_var
func resource_upgrade_cost(resource_id : felt) -> (value : felt):
end

@storage_var
func resource_upgrade_value(resource_id : felt) -> (ids : felt):
end

# BUILDINGS #

@storage_var
func building_cost_ids(building_id : felt) -> (cost_ids : felt):
end

@storage_var
func building_cost_values(building_id : felt) -> (cost_values : felt):
end

###############
# CONSTRUCTOR #
###############

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt):
    Ownable_initializer(owner)
    return ()
end

############
# EXTERNAL #
############

# RESOURCES #

@external
func set_resource_upgrade_value{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(resource_id : felt, _resource_upgrade_ids : felt) -> (success : felt):
    Ownable_only_owner()
    resource_upgrade_value.write(resource_id, _resource_upgrade_ids)

    return (TRUE)
end

@external
func set_resource_upgrade_cost{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(resource_id : felt, _resource_upgrade_values : felt) -> (success : felt):
    Ownable_only_owner()
    resource_upgrade_cost.write(resource_id, _resource_upgrade_values)

    return (TRUE)
end

# BUILDINGS #

@external
func set_building_cost_ids{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    building_id : felt, cost : felt
) -> (success : felt):
    Ownable_only_owner()
    building_cost_ids.write(building_id, cost)

    return (TRUE)
end

@external
func set_building_cost_values{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    building_id : felt, cost : felt
) -> (success : felt):
    Ownable_only_owner()
    building_cost_values.write(building_id, cost)

    return (TRUE)
end

###########
# GETTERS #
###########

# RESOURCES #

@view
func get_resource_upgrade_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    resource_id : felt
) -> (value : felt):
    let (value) = resource_upgrade_value.read(resource_id)

    return (value=value)
end

# BUILDINGS #

@view
func get_building_cost_ids{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    building_id : felt
) -> (ids : felt):
    let (ids) = building_cost_ids.read(building_id)

    return (ids=ids)
end

@view
func get_building_cost_values{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    building_id : felt
) -> (cost : felt):
    let (cost) = building_cost_values.read(building_id)

    return (cost=cost)
end
