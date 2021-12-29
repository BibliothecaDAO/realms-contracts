%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.general import scale
from contracts.settling_game.utils.interfaces import IModuleController, I02B_Claim

from contracts.settling_game.utils.game_structs import RealmData 

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155
from contracts.settling_game.realms_IERC721 import realms_IERC721

# #### Module 2A #####
# Allows Player to Claim resources
####################

# ########### Game state ############

# Stores the address of the ModuleController.
@storage_var
func controller_address() -> (address : felt):
end


# ########### Admin Functions for Testing ############
# Called on deployment only.
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    # Store the address of the only fixed contract in the system.
    controller_address.write(address_of_controller)
    return ()
end

@external
func claim_resources{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token_id : Uint256):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()

    # realms contract
    let (realms_address) = IModuleController.get_realms_address(
        contract_address=controller)

    # resource contract
    let (resources_address) = IModuleController.get_resources_address(
        contract_address=controller)

    # state contract
    let (claim_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=4)

    # check owner
    let (owner) = realms_IERC721.ownerOf(contract_address=realms_address, token_id=token_id)
    assert caller = owner        

    #TODO check settled state
    let (local a : felt*) = alloc() 
    let (local b : felt*) = alloc() 

    local count


    
    let (realms_data: RealmData) = realms_IERC721.fetch_realm_data(contract_address=realms_address, token_id=token_id)
    
    let (r_1) = I02B_Claim.get_resource_level(contract_address=claim_state_address, token_id=token_id, resource=realms_data.resource_1)
    
    assert a[0] = realms_data.resource_1 
    assert b[0] = r_1
     
    if realms_data.resource_2 != 0:
        assert a[1] = realms_data.resource_2
        assert b[1] = 10
        assert count = 2
    else:
        assert count = 1 
    end

    if realms_data.resource_3 != 0:
        assert a[2] = realms_data.resource_3
        assert b[2] = 10
        assert count = 3
    end

    if realms_data.resource_4 != 0:
        assert a[3] = realms_data.resource_4
        assert b[3] = 10
        assert count = 4
    end

    if realms_data.resource_5 != 0:
        assert a[4] = realms_data.resource_5
        assert b[4] = 10
        assert count = 5
    end

    if realms_data.resource_6 != 0:
        assert a[5] = realms_data.resource_7
        assert b[5] = 10
        assert count = 6
    end

    if realms_data.resource_7 != 0:
        assert a[6] = realms_data.resource_7
        assert b[6] = 10 
        assert count = 7
    end    
    
    # # TODO: only allow claim contract to mint
    IERC1155.mint_batch(resources_address, caller, count, a, count, b) 


    # mint reousrces for wonder tax
    return ()
end

@external
func payment_split{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token_id : Uint256):
    # calculate resources from packed struct
    # add in tax

    # mint resources for user
    # mint reousrces for wonder tax
    return ()
end

# Checks write-permission of the calling contract.
func only_approved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    # Get the address of the module trying to write to this contract.
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()
    # Pass this address on to the ModuleController.
    # "Does this address have write-authority here?"
    # Will revert the transaction if not.
    IModuleController.has_write_access(
        contract_address=controller, address_attempting_to_write=caller)
    return ()
end
