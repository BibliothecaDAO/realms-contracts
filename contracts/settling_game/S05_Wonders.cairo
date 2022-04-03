%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, uint256_add
from contracts.settling_game.interfaces.imodules import IModuleController
from contracts.settling_game.utils.library import MODULE_only_approved, MODULE_initializer

# ____MODULE_S05___WONDERS_STATE

###########
# STORAGE #
###########

@storage_var
func epoch_claimed(address : felt) -> (epoch : felt):
end

@storage_var
func total_wonders_staked(epoch : felt) -> (amount : felt):
end

@storage_var
func last_updated_epoch() -> (epoch : felt):
end

@storage_var
func wonder_id_staked(token_id : Uint256) -> (epoch : felt):
end

@storage_var
func wonder_epoch_upkeep(epoch : felt, token_id : Uint256) -> (upkept : felt):
end

@storage_var
func tax_pool(epoch : felt, resource_id : Uint256) -> (supply : Uint256):
end

###############
# CONSTRUCTOR #
###############

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    MODULE_initializer(address_of_controller)
    return ()
end

###########
# SETTERS #
###########

@external
func set_total_wonders_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, amount : felt):
    MODULE_only_approved()

    total_wonders_staked.write(epoch, amount)
    return ()
end

@external
func set_last_updated_epoch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt):
    MODULE_only_approved()

    last_updated_epoch.write(epoch)
    return ()
end

@external
func set_wonder_id_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, epoch : felt):
    MODULE_only_approved()

    wonder_id_staked.write(token_id, epoch)
    return ()
end

@external
func set_wonder_epoch_upkeep{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, token_id : Uint256, upkept : felt):
    MODULE_only_approved()

    wonder_epoch_upkeep.write(epoch, token_id, upkept)
    return ()
end

@external
func set_tax_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, resource_id : Uint256, amount : Uint256):
    MODULE_only_approved()

    tax_pool.write(epoch, resource_id, amount)
    return ()
end

@external
func batch_set_tax_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, resource_ids_len : felt, resource_ids : Uint256*, amounts_len : felt,
        amounts : Uint256*):
    alloc_locals
    MODULE_only_approved()
    # Update tax pool
    if resource_ids_len == 0:
        return ()
    end
    let (tax_pool) = get_tax_pool(epoch, [resource_ids])

    let (sum, _) = uint256_add(tax_pool, [amounts])
    set_tax_pool(epoch, [resource_ids], sum)

    # Recurse
    return batch_set_tax_pool(
        epoch=epoch,
        resource_ids_len=resource_ids_len - 1,
        resource_ids=resource_ids + 1,
        amounts_len=amounts_len - 1,
        amounts=amounts + 1)
end

###########
# GETTERS #
###########

@view
func get_total_wonders_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt) -> (amount : felt):
    let (amount) = total_wonders_staked.read(epoch)

    return (amount=amount)
end

@view
func get_last_updated_epoch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (epoch : felt):
    let (epoch) = last_updated_epoch.read()

    return (epoch=epoch)
end

@view
func get_wonder_id_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (wonder_id : felt):
    let (wonder_id) = wonder_id_staked.read(token_id)

    return (wonder_id=wonder_id)
end

@view
func get_wonder_epoch_upkeep{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, token_id : Uint256) -> (upkept : felt):
    let (upkept) = wonder_epoch_upkeep.read(epoch, token_id)

    return (upkept=upkept)
end

@view
func get_tax_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt, resource_id : Uint256) -> (supply : Uint256):
    let (supply) = tax_pool.read(epoch, resource_id)

    return (supply)
end
