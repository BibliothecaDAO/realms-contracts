# ____MODULE_L05___WONDERS_LOGIC
#   TODO: Write Module Description
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import (
    assert_in_range,
    assert_nn,
    assert_nn_le,
    unsigned_div_rem,
    assert_not_zero,
)
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.general import scale
from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds
from contracts.settling_game.interfaces.imodules import (
    IModuleController,
    IS02_Resources,
    IS01_Settling,
    IL04_Calculator,
    IS05_Wonders,
)

from contracts.settling_game.utils.game_structs import RealmData
from contracts.settling_game.utils.general import unpack_data

from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721

from contracts.settling_game.utils.library import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
)

from openzeppelin.upgrades.library import (
    Proxy_initializer,
    Proxy_only_admin,
    Proxy_set_implementation,
    Proxy_get_implementation,
    Proxy_set_admin,
    Proxy_get_admin,
)

###############
# CONSTRUCTOR #
###############

@external
func initializer{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        address_of_controller : felt,
        proxy_admin : felt
    ):
    MODULE_initializer(address_of_controller)
    Proxy_initializer(proxy_admin)
    return ()
end

@external
func upgrade{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(new_implementation: felt):
    Proxy_only_admin()
    Proxy_set_implementation(new_implementation)
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
    let (controller) = MODULE_controller_address()
    let (caller) = get_caller_address()

    # treasury address
    let (treasury_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Treasury
    )
    # resources address
    let (resources_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    )
    let (wonders_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S05_Wonders
    )

    # calculator logic contract
    let (calculator_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L04_Calculator
    )
    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)

    assert_nn_le(current_epoch, epoch)

    # Set upkept for epoch
    IS05_Wonders.set_wonder_epoch_upkeep(wonders_state_address, epoch, token_id, 1)

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
    MODULE_only_approved()
    update_epoch_pool()

    let (controller) = MODULE_controller_address()

    let (wonders_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S05_Wonders
    )

    # calculator logic contract
    let (calculator_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L04_Calculator
    )

    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)
    let (total_wonders_staked) = IS05_Wonders.get_total_wonders_staked(
        contract_address=wonders_state_address, epoch=current_epoch
    )

    let (wonder_id_staked) = IS05_Wonders.get_wonder_id_staked(
        contract_address=wonders_state_address, token_id=token_id
    )
    if wonder_id_staked == 0:
        IS05_Wonders.set_total_wonders_staked(
            contract_address=wonders_state_address,
            epoch=current_epoch,
            amount=total_wonders_staked + 1,
        )
        IS05_Wonders.set_wonder_id_staked(
            contract_address=wonders_state_address, token_id=token_id, epoch=current_epoch
        )
    else:
        IS05_Wonders.set_total_wonders_staked(
            contract_address=wonders_state_address,
            epoch=current_epoch,
            amount=total_wonders_staked - 1,
        )
        IS05_Wonders.set_wonder_id_staked(
            contract_address=wonders_state_address, token_id=token_id, epoch=0
        )
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
    let (controller) = MODULE_controller_address()

    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms
    )
    let (wonders_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S05_Wonders
    )
    let (calculator_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L04_Calculator
    )

    # Check that wonder is staked (this also checks if token_id a wonder at all)
    let (staked_epoch) = IS05_Wonders.get_wonder_id_staked(wonders_state_address, token_id)
    assert_not_zero(staked_epoch)

    let claiming_epoch_start = staked_epoch + 1
    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)
    # assert that claim loop starts at a past epoch
    assert_nn_le(claiming_epoch_start, current_epoch - 1)

    # Check that wonder is owned by caller
    let (owner_of_wonder) = s_realms_IERC721.ownerOf(s_realms_address, token_id)
    assert owner_of_wonder = caller

    loop_epochs_claim(caller, token_id, current_epoch, claiming_epoch_start)

    IS05_Wonders.set_wonder_id_staked(wonders_state_address, token_id, current_epoch - 1)

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

    let (controller) = MODULE_controller_address()
    let (wonders_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S05_Wonders
    )

    let (epoch_upkept) = IS05_Wonders.get_wonder_epoch_upkeep(
        wonders_state_address, claiming_epoch, token_id
    )
    if epoch_upkept == 1:
        # treasury address
        let (treasury_address) = IModuleController.get_external_contract_address(
            controller, ExternalContractIds.Treasury
        )
        # resources address
        let (resources_address) = IModuleController.get_external_contract_address(
            controller, ExternalContractIds.Resources
        )
        let (epoch_total_wonders) = IS05_Wonders.get_total_wonders_staked(
            contract_address=wonders_state_address, epoch=claiming_epoch
        )

        let (ids_arr : Uint256*) = alloc()
        let (amounts_arr : Uint256*) = alloc()

        # Get claimable resources
        loop_resources_claim(
            wonders_state_address,
            token_id,
            current_epoch,
            epoch_total_wonders,
            1,
            ids_arr,
            1,
            amounts_arr,
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
    wonders_state_address : felt,
    token_id : Uint256,
    claiming_epoch : felt,
    epoch_total_wonders : felt,
    resource_claim_ids_len : felt,
    resource_claim_ids : felt*,
    resource_claim_amounts_len : felt,
    resource_claim_amounts : felt*,
) -> (
    resource_claim_ids_len : felt,
    resource_claim_ids : felt*,
    resource_claim_amounts_len : felt,
    resource_claim_amounts : felt*,
):
    alloc_locals

    let (below_max_id) = is_nn_le(resource_claim_ids_len, 22)

    assert_in_range(resource_claim_amounts_len, 1, 2 ** 15)
    if below_max_id == 1:
        let (resource_pool) = IS05_Wonders.get_tax_pool(
            wonders_state_address, claiming_epoch, resource_claim_ids_len
        )
        let (resource_claim_amount, _) = unsigned_div_rem(resource_pool, epoch_total_wonders)

        assert resource_claim_ids[resource_claim_ids_len - 1] = resource_claim_ids_len
        assert resource_claim_amounts[resource_claim_ids_len - 1] = resource_claim_amount

        return loop_resources_claim(
            wonders_state_address,
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
    let (controller) = MODULE_controller_address()
    let (wonders_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S05_Wonders
    )
    let (calculator_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.L04_Calculator
    )

    let (current_epoch) = IL04_Calculator.calculate_epoch(calculator_address)
    let (last_updated_epoch) = IS05_Wonders.get_last_updated_epoch(wonders_state_address)

    # Epochs that havent been updated since last update or recursion
    let epochs_to_update = current_epoch - last_updated_epoch

    if epochs_to_update == 0:
        return ()
    else:
        let updating_epoch = current_epoch - epochs_to_update

        # roll over total wonders staked for the next epoch
        let (total_wonders_staked) = IS05_Wonders.get_total_wonders_staked(
            wonders_state_address, updating_epoch
        )
        IS05_Wonders.set_total_wonders_staked(
            wonders_state_address, updating_epoch + 1, total_wonders_staked
        )

        IS05_Wonders.set_last_updated_epoch(wonders_state_address, updating_epoch + 1)

        return update_epoch_pool()
    end
end
