# -----------------------------------
# ____MODULE_L05___WONDERS_LOGIC
#   Controls all logic around the Wonder tax.
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import (
    assert_in_range,
    assert_nn_le,
    unsigned_div_rem,
    assert_not_zero,
)
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256
from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds
from contracts.settling_game.interfaces.imodules import IModuleController, IL04_Calculator

from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721

from contracts.settling_game.library.library_module import Module

# -----------------------------------
# Storage
# -----------------------------------

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
func tax_pool(epoch : felt, resource_id : Uint256) -> (supply : felt):
end

###############
# CONSTRUCTOR #
###############

@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt, proxy_admin : felt
):
    Module.initializer(address_of_controller)
    Proxy.initializer(proxy_admin)
    return ()
end

@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy.assert_only_admin()
    Proxy._set_implementation_hash(new_implementation)
    return ()
end

############
# EXTERNAL #
############

@external
func pay_wonder_upkeep{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    epoch : felt, token_id : Uint256
):
    alloc_locals
    let (controller) = Module.controller_address()
    let (caller) = get_caller_address()

    # ADDRESSES
    let (treasury_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Treasury
    )
    let (resources_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    )
    let (calculator_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L04_Calculator
    )

    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)

    assert_nn_le(current_epoch, epoch)

    # Set upkept for epoch
    set_wonder_epoch_upkeep(epoch, token_id, 1)

    # Upkeep cost, to be moved
    let (local upkeep_token_ids : Uint256*) = alloc()
    let (local upkeep_token_amounts : Uint256*) = alloc()

    # TODO: Convert into ids and values into storage so can be adjusted dynamically
    assert upkeep_token_ids[0] = Uint256(19, 0)
    assert upkeep_token_ids[1] = Uint256(20, 0)
    assert upkeep_token_ids[2] = Uint256(21, 0)
    assert upkeep_token_ids[3] = Uint256(22, 0)

    assert upkeep_token_amounts[0] = Uint256(28, 0)
    assert upkeep_token_amounts[1] = Uint256(21, 0)
    assert upkeep_token_amounts[2] = Uint256(14, 0)
    assert upkeep_token_amounts[3] = Uint256(7, 0)

    IERC1155.safeBatchTransferFrom(
        resources_address, caller, treasury_address, 4, upkeep_token_ids, 4, upkeep_token_amounts
    )

    return ()
end

# Called when a settlement is staked/unstaked to update the wonder pool
@external
func update_wonder_settlement{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
):
    alloc_locals
    Module.only_approved()
    update_epoch_pool()

    let (controller) = Module.controller_address()

    # calculator logic contract
    let (calculator_address) = IModuleController.get_module_address(
        controller, ModuleIds.L04_Calculator
    )

    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)
    let (total_wonders_staked) = get_total_wonders_staked(current_epoch)

    let (wonder_id_staked) = get_wonder_id_staked(token_id)

    if wonder_id_staked == 0:
        set_total_wonders_staked(current_epoch, total_wonders_staked + 1)
        set_wonder_id_staked(token_id, current_epoch)
    else:
        set_total_wonders_staked(current_epoch, total_wonders_staked - 1)
        set_wonder_id_staked(token_id, 0)
    end
    return ()
end

@external
func claim_wonder_tax{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
):
    alloc_locals
    update_epoch_pool()
    let (caller) = get_caller_address()
    let (controller) = Module.controller_address()

    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms
    )

    let (calculator_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L04_Calculator
    )

    # Check that wonder is staked (this also checks if token_id a wonder at all)
    let (staked_epoch) = get_wonder_id_staked(token_id)
    assert_not_zero(staked_epoch)

    let claiming_epoch_start = staked_epoch + 1
    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)
    # assert that claim loop starts at a past epoch
    assert_nn_le(claiming_epoch_start, current_epoch - 1)

    # Check that wonder is owned by caller
    let (owner_of_wonder) = s_realms_IERC721.ownerOf(s_realms_address, token_id)
    assert owner_of_wonder = caller

    loop_epochs_claim(caller, token_id, current_epoch, claiming_epoch_start)

    set_wonder_id_staked(token_id, current_epoch - 1)

    return ()
end

func loop_epochs_claim{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    caller : felt, token_id : Uint256, current_epoch : felt, claiming_epoch : felt
):
    alloc_locals
    # stop here if over latest claimable epoch
    let (local within_max_epoch) = is_nn_le(claiming_epoch, current_epoch - 1)
    if within_max_epoch == 0:
        return ()
    end

    let (controller) = Module.controller_address()

    let (epoch_upkept) = get_wonder_epoch_upkeep(claiming_epoch, token_id)
    if epoch_upkept == 1:
        # treasury address
        let (treasury_address) = IModuleController.get_external_contract_address(
            controller, ExternalContractIds.Treasury
        )
        # resources address
        let (resources_address) = IModuleController.get_external_contract_address(
            controller, ExternalContractIds.Resources
        )
        let (epoch_total_wonders) = get_total_wonders_staked(claiming_epoch)

        let (ids_arr : Uint256*) = alloc()

        let (amounts_arr : Uint256*) = alloc()

        # Get claimable resources
        loop_resources_claim(
            token_id, current_epoch, epoch_total_wonders, 1, ids_arr, 1, amounts_arr
        )

        # Transfer claimable resources
        IERC1155.safeBatchTransferFrom(
            resources_address, caller, treasury_address, 22, ids_arr, 22, amounts_arr
        )

        return loop_epochs_claim(caller, token_id, current_epoch, claiming_epoch + 1)
    end
    return loop_epochs_claim(caller, token_id, current_epoch, claiming_epoch + 1)
end

func loop_resources_claim{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256,
    claiming_epoch : felt,
    epoch_total_wonders : felt,
    resource_claim_ids_len : felt,
    resource_claim_ids : Uint256*,
    resource_claim_amounts_len : felt,
    resource_claim_amounts : Uint256*,
) -> (
    resource_claim_ids_len : felt,
    resource_claim_ids : Uint256*,
    resource_claim_amounts_len : felt,
    resource_claim_amounts : Uint256*,
):
    alloc_locals

    let (below_max_id) = is_nn_le(resource_claim_ids_len, 22)

    assert_in_range(resource_claim_amounts_len, 1, 2 ** 15)
    if below_max_id == 1:
        let (resource_pool) = get_tax_pool(claiming_epoch, [resource_claim_ids])
        let (resource_claim_amount, _) = unsigned_div_rem(resource_pool, epoch_total_wonders)

        # assert resource_claim_ids[resource_claim_ids_len - 1] = resource_claim_ids_len
        # assert resource_claim_amounts[resource_claim_ids_len - 1] = resource_claim_amount

        return loop_resources_claim(
            token_id,
            claiming_epoch,
            epoch_total_wonders,
            resource_claim_ids_len + 1,
            resource_claim_ids,
            resource_claim_amounts_len + 1,
            resource_claim_amounts,
        )
    end
    return (
        resource_claim_ids_len,
        resource_claim_ids,
        resource_claim_amounts_len,
        resource_claim_amounts,
    )
end

# Called everytime a user settled, unsettles or claims taxes
# Recurses for every epoch that passed since last update
func update_epoch_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    let (controller) = Module.controller_address()

    let (calculator_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L04_Calculator
    )

    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)
    let (last_updated_epoch) = get_last_updated_epoch()

    # Epochs that havent been updated since last update or recursion
    let epochs_to_update = current_epoch - last_updated_epoch

    if epochs_to_update == 0:
        return ()
    else:
        let updating_epoch = current_epoch - epochs_to_update

        # roll over total wonders staked for the next epoch
        let (total_wonders_staked) = get_total_wonders_staked(updating_epoch)
        set_total_wonders_staked(updating_epoch + 1, total_wonders_staked)

        set_last_updated_epoch(updating_epoch + 1)

        return update_epoch_pool()
    end
end

###########
# SETTERS #
###########

func set_total_wonders_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    epoch : felt, amount : felt
):
    total_wonders_staked.write(epoch, amount)
    return ()
end

func set_last_updated_epoch{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    epoch : felt
):
    last_updated_epoch.write(epoch)
    return ()
end

func set_wonder_id_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, epoch : felt
):
    wonder_id_staked.write(token_id, epoch)

    return ()
end

func set_wonder_epoch_upkeep{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    epoch : felt, token_id : Uint256, upkept : felt
):
    wonder_epoch_upkeep.write(epoch, token_id, upkept)
    return ()
end

func set_tax_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    epoch : felt, resource_id : Uint256, amount : felt
):
    tax_pool.write(epoch, resource_id, amount)
    return ()
end

@external
func batch_set_tax_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    epoch : felt,
    resource_ids_len : felt,
    resource_ids : Uint256*,
    amounts_len : felt,
    amounts : felt*,
):
    alloc_locals
    Module.only_approved()
    # Update tax pool
    if resource_ids_len == 0:
        return ()
    end
    let (tax_pool) = get_tax_pool(epoch, [resource_ids])

    set_tax_pool(0, [resource_ids], 0)

    # Recurse
    return batch_set_tax_pool(
        epoch, resource_ids_len - 1, resource_ids + 1, amounts_len - 1, amounts + 1
    )
end

###########
# GETTERS #
###########

@view
func get_total_wonders_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    epoch : felt
) -> (amount : felt):
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
    token_id : Uint256
) -> (wonder_id : felt):
    let (wonder_id) = wonder_id_staked.read(token_id)

    return (wonder_id=wonder_id)
end

@view
func get_wonder_epoch_upkeep{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    epoch : felt, token_id : Uint256
) -> (upkept : felt):
    let (upkept) = wonder_epoch_upkeep.read(epoch, token_id)

    return (upkept=upkept)
end

@view
func get_tax_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    epoch : felt, resource_id : Uint256
) -> (supply : felt):
    let (supply) = tax_pool.read(epoch, resource_id)

    return (supply)
end
