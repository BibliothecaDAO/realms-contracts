%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.general import scale
from contracts.settling_game.utils.interfaces import (
    IModuleController, I02B_Resources, I01B_Settling, I01A_Settling, I04A_Calculator, I05B_Wonders)

from contracts.settling_game.utils.game_structs import RealmData, ResourceUpgradeIds
from contracts.settling_game.utils.general import unpack_data

from contracts.token.ERC20.interfaces.IERC20 import IERC20
from contracts.token.ERC1155.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721

# #### Module 2A ##########
#                        #
# Claim & Resource Logic #
#                        #
##########################

@storage_var
func controller_address() -> (address : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    controller_address.write(address_of_controller)
    return ()
end

@external
func pay_wonder_upkeep{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        epoch : felt,
        token_id : felt):
    alloc_locals
    let ( controller ) = controller_address.read()
    let ( caller ) = get_caller_address()

    let ( resources_address ) = IModuleController.get_resources_address(contract_address=controller)
    let ( wonder_tax_pool_address ) = IModuleController.get_module_address(contract_address=controller, module_id=9)

    # calculator logic contract
    let (calculator_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=7)

    # get currenty epoch
    let ( current_epoch ) = I04A_Calculator.calculateEpoch(calculator_address)

    # TODO
    # ASSERT current_epoch > epoch

    # Set upkept for epoch
    I05B_Wonders.set_wonder_epoch_upkeep(epoch=epoch, token_id=token_id, upkept=1)

    # Upkeep cost, to be moved
    let ( local upkeep_token_ids : felt* ) = alloc()
    let ( local upkeep_token_amounts : felt* ) = alloc()

    assert upkeep_token_ids[0] = 19
    assert upkeep_token_ids[1] = 20
    assert upkeep_token_ids[2] = 21
    assert upkeep_token_ids[3] = 22

    assert upkeep_token_amounts[0] = 7
    assert upkeep_token_amounts[1] = 14
    assert upkeep_token_amounts[2] = 21
    assert upkeep_token_amounts[3] = 28

    IERC1155.safeBatchTransferFrom(
        resources_address,
        caller,
        wonder_tax_pool_address,
        4,
        upkeep_token_ids,
        4,
        upkeep_token_amounts)
end

@external
func claim_wonder_tax{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt):
    alloc_locals
    let ( controller ) = controller_address.read()
    let ( wonder_tax_pool_address ) = IModuleController.get_module_address(contract_address=controller, module_id=9)
    let ( calculator_address ) = IModuleController.get_module_address(contract_address=controller, module_id=7)

    let ( current_epoch ) = I04A_Calculator.calculateEpoch(calculator_address)
    let ( staked_epoch ) = I05B_Wonders.get_wonder_id_staked(wonders_state_address, token_id)

    assert assert_not_zero(staked_epoch)

    loop_epochs_claim(
        current_epoch,
        staked_epoch)

    return ()
end

func loop_epochs_claim{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        current_epoch : felt, claiming_epoch : felt ):
    alloc_locals

    # stop here if over at latest claimable epoch
    let ( local within_max_epoch ) = is_nn_le(claiming_epoch, current_epoch - 1) 
    if within_max_epoch = 0:
        return()
    end

    let ( controller ) = controller_address.read()
    let ( wonder_tax_pool_address ) = IModuleController.get_module_address(contract_address=controller, module_id=9)

    let ( epoch_upkept ) = I05B_Wonders.get_wonder_epoch_upkeep(wonders_state_address, epoch, token_id)
    if epoch_upkept = 1:
        # Get claimable resources
        let ( resource_claim_ids_len, resource_claim_ids, resource_claim_amounts_len, resource_claim_amounts ) = loop_resources_claim(
            current_epoch,
            epoch_total_wonders,
            1)

        # Transfer claimable resources
        IERC1155.safeBatchTransferFrom(
            resources_address,
            caller,
            wonder_tax_pool_address,
            resource_claim_ids_len, 
            resource_claim_ids, 
            resource_claim_amounts_len, 
            resource_claim_amounts)
    end

    # Recurse
    return loop_epochs_claim(
        current_epoch,
        claiming_epoch + 1)
end

func loop_resources_claim{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            wonders_state_address : felt, token_id : felt, epoch : felt, epoch_total_wonders : felt,
            resource_claim_ids_len : felt, 
            resource_claim_ids : felt*, 
            resource_claim_amounts_len : felt, 
            resource_claim_amounts : felt*) 
        -> (
            resource_claim_ids_len : felt, 
            resource_claim_ids : felt*, 
            resource_claim_amounts_len : felt, 
            resource_claim_amounts : felt*):
    alloc_locals

    let ( resource_pool ) = I05B_Wonders.get_tax_pool(wonders_state_address, epoch, resource_claim_ids_len + 1)
    resource_claim_ids[resource_claim_ids_len] = resource_claim_ids_len + 1
    resource_claim_amounts[resource_claim_ids_len] = resource_pool / epoch_total_wonders 
    
    return loop_resources_claim(
        wonders_state_address, epoch, epoch_total_wonders,
        resource_claim_ids_len + 1, 
        resource_claim_ids, 
        resource_claim_amounts_len + 1, 
        resource_claim_amounts)
end