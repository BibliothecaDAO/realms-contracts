%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_in_range, assert_nn, assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.general import scale
from contracts.settling_game.utils.interfaces import (
    IModuleController, IS02_Resources, IS01_Settling, IL04_Calculator, IS05_Wonders)

from contracts.settling_game.utils.game_structs import RealmData, ResourceUpgradeIds
from contracts.settling_game.utils.general import unpack_data

from contracts.token.ERC20.interfaces.IERC20 import IERC20
from contracts.token.ERC1155.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721


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
        token_id : Uint256):
    alloc_locals
    let ( controller ) = controller_address.read()
    let ( caller ) = get_caller_address()

    let ( treasury_address ) = IModuleController.get_treasury_address(contract_address=controller)
    let ( resources_address ) = IModuleController.get_resources_address(contract_address=controller)
    let ( wonder_tax_pool_address ) = IModuleController.get_module_address(contract_address=controller, module_id=9)

    # calculator logic contract
    let ( calculator_address ) = IModuleController.get_module_address(
        contract_address=controller, module_id=7)

    # get currenty epoch
    let ( current_epoch ) = IL04_Calculator.calculateEpoch(calculator_address)

    assert_nn_le(current_epoch, epoch)

    # Set upkept for epoch
    IS05_Wonders.set_wonder_epoch_upkeep(wonder_tax_pool_address, epoch, token_id, 1)

    # Upkeep cost, to be moved
    let ( local upkeep_token_ids : Uint256* ) = alloc()
    let ( local upkeep_token_amounts : felt* ) = alloc()

    # assert upkeep_token_ids[0] = Uint256(19, 0)
    # assert upkeep_token_ids[1] = Uint256(20, 0)
    # assert upkeep_token_ids[2] = Uint256(21, 0)
    # assert upkeep_token_ids[3] = Uint256(22, 0)

    assert upkeep_token_amounts[0] = 28
    assert upkeep_token_amounts[1] = 21
    assert upkeep_token_amounts[2] = 14
    assert upkeep_token_amounts[3] = 7

    IERC1155.safeBatchTransferFrom(
        resources_address,
        caller,
        treasury_address,
        4,
        upkeep_token_ids,
        4,
        upkeep_token_amounts)

        return ()
end

@external
func claim_wonder_tax{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256):
    alloc_locals
    let ( caller ) = get_caller_address()
    let ( controller ) = controller_address.read()
    let ( s_realms_address ) = IModuleController.get_s_realms_address(contract_address=controller)
    let ( wonders_state_address ) = IModuleController.get_module_address(contract_address=controller, module_id=9)
    let ( calculator_address ) = IModuleController.get_module_address(contract_address=controller, module_id=7)

    # Check that wonder is staked (this also checks if token_id a wonder at all)
    let ( staked_epoch ) = IS05_Wonders.get_wonder_id_staked(wonders_state_address, token_id)
    assert_not_zero(staked_epoch)
    
    # Check that wonder is owned by caller
    let ( owner_of_wonder ) = s_realms_IERC721.ownerOf(s_realms_address, token_id)

    assert owner_of_wonder = caller

    let ( current_epoch ) = IL04_Calculator.calculateEpoch(calculator_address)

    loop_epochs_claim(
        caller,
        token_id,
        current_epoch,
        staked_epoch)

    IS05_Wonders.set_wonder_id_staked(wonders_state_address, token_id, current_epoch - 1)

    return ()
end

func loop_epochs_claim{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        caller : felt, token_id : Uint256, current_epoch : felt, claiming_epoch : felt ):
    alloc_locals
    # stop here if over latest claimable epoch
    let ( local within_max_epoch ) = is_nn_le(claiming_epoch, current_epoch - 1) 
    if within_max_epoch == 0:
        return()
    end

    let ( controller ) = controller_address.read()
    let ( wonders_state_address ) = IModuleController.get_module_address(contract_address=controller, module_id=9)

    let ( epoch_upkept ) = IS05_Wonders.get_wonder_epoch_upkeep(wonders_state_address, current_epoch, token_id)
    if epoch_upkept == 1:
        let (treasury_address) = IModuleController.get_treasury_address(contract_address=controller)
        let ( resources_address ) = IModuleController.get_resources_address(contract_address=controller)
        let ( epoch_total_wonders ) = IS05_Wonders.get_total_wonders_staked(contract_address=wonders_state_address, epoch=claiming_epoch)

        let ( ids_arr ) = alloc()
        let ( amounts_arr ) = alloc()

        # Get claimable resources
        loop_resources_claim(
            wonders_state_address,
            token_id,
            current_epoch,
            epoch_total_wonders,
            1,
            ids_arr,
            1,
            amounts_arr)

        # Transfer claimable resources
        IERC1155.safeBatchTransferFrom(
            resources_address,
            caller,
            treasury_address,
            22, 
            ids_arr, 
            22, 
            amounts_arr)
    else:

    # Recurse
    return loop_epochs_claim(
        caller,
        token_id,
        current_epoch,
        claiming_epoch + 1)
    end
    return ()
end

func loop_resources_claim{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
            wonders_state_address : felt, token_id : Uint256, epoch : felt, epoch_total_wonders : felt,
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

    let ( below_max_id ) = is_nn_le(resource_claim_ids_len, 22)

    assert_in_range(resource_claim_amounts_len, 1, 2**15)
    if below_max_id == 1:
        let ( resource_pool ) = IS05_Wonders.get_tax_pool(wonders_state_address, epoch, Uint256(resource_claim_ids_len, 0))
        assert resource_claim_ids[resource_claim_ids_len - 1] = resource_claim_ids_len
        assert resource_claim_amounts[resource_claim_ids_len - 1] = resource_pool / epoch_total_wonders 
    
        return loop_resources_claim(
            wonders_state_address, token_id, epoch, epoch_total_wonders,
            resource_claim_ids_len + 1, 
            resource_claim_ids, 
            resource_claim_amounts_len + 1, 
            resource_claim_amounts)
    else:
    return (
        resource_claim_ids_len, 
        resource_claim_ids, 
        resource_claim_amounts_len, 
        resource_claim_amounts)
    end
end