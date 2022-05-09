# ____MODULE_L01___SETTLING_LOGIC
#   Core Settling Game logic including setting up the world
#   and staking/unstaking a realm.
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_timestamp,
    get_contract_address,
)
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.utils.game_structs import ModuleIds, ExternalContractIds, RealmData
from contracts.settling_game.utils.constants import TRUE, FALSE
from contracts.settling_game.utils.library import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
)

from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721
from contracts.settling_game.interfaces.imodules import (
    IModuleController,
    IL05_Wonders,
    IL02_Resources,
)

from openzeppelin.upgrades.library import (
    Proxy_initializer,
    Proxy_only_admin,
    Proxy_set_implementation
)

##########
# EVENTS #
##########

@event
func Settled(owner : felt, token_id : Uint256):
end

@event
func UnSettled(owner : felt, token_id : Uint256):
end

###########
# STORAGE #
###########

# STAKE TIME - THIS IS USED AS THE MAIN IDENTIFIER FOR STAKING TIME
# IT IS UPDATED ON RESOURCE CLAIM, STAKE, UNSTAKE
@storage_var
func time_staked(token_id : Uint256) -> (time : felt):
end

@storage_var
func time_vault_staked(token_id : Uint256) -> (time : felt):
end

@storage_var
func total_realms_settled() -> (amount : felt):
end

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

# SETTLES REALM
@external
func settle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (success : felt):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()
    let (contract_address) = get_contract_address()

    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    )
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms
    )

    # TRANSFER REALM
    realms_IERC721.transferFrom(realms_address, caller, contract_address, token_id)

    # MINT S_REALM
    s_realms_IERC721.mint(s_realms_address, caller, token_id)

    # SETS WORLD AND REALM STATE
    _set_world_state(token_id, caller, controller, realms_address)

    # EMIT
    Settled.emit(caller, token_id)

    return (TRUE)
end

# UNSETTLES REALM
@external
func unsettle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (success : felt):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()
    let (contract_address) = get_contract_address()

    # FETCH ADDRESSES
    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    )
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms
    )

    let (resource_logic_address) = IModuleController.get_module_address(
        controller, ModuleIds.L02_Resources
    )

    # CHECK NO PENDING RESOURCES OR LORDS
    let (can_claim) = IL02_Resources.check_if_claimable(resource_logic_address, token_id)

    if can_claim == TRUE:
        IL02_Resources.claim_resources(resource_logic_address, token_id)
        _set_world_state(token_id, caller, controller, realms_address)
    else:
        _set_world_state(token_id, caller, controller, realms_address)
    end

    # TRANSFER REALM BACK TO OWNER
    realms_IERC721.transferFrom(realms_address, contract_address, caller, token_id)

    # BURN S_REALM
    s_realms_IERC721.burn(s_realms_address, token_id)

    # EMIT
    UnSettled.emit(caller, token_id)

    return (TRUE)
end

# TIME_LEFT -> WHEN PLAYER CLAIMS, THIS IS THE REMAINDER TO BE PASSED BACK INTO STORAGE
# THIS ALLOWS FULL DAYS TO BE CLAIMED ONLY AND ALLOWS LESS THAN FULL DAYS TO CONTINUE ACCRUREING
@external
func set_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, time_left : felt
):
    MODULE_only_approved()
    _set_time_staked(token_id, time_left)
    return ()
end

@external
func set_time_vault_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, time_left : felt
):
    MODULE_only_approved()
    _set_time_vault_staked(token_id, time_left)
    return ()
end

############
# INTERNAL #
############

func _set_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, time_left : felt
):  
    let (block_timestamp) = get_block_timestamp()
    time_staked.write(token_id, block_timestamp - time_left)
    return ()
end

func _set_time_vault_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, time_left : felt
):
    let (block_timestamp) = get_block_timestamp()
    time_vault_staked.write(token_id, block_timestamp - time_left)
    return ()
end

func _set_total_realms_settled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    amount : felt
):
    total_realms_settled.write(amount)
    return ()
end

func _set_world_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256,
    caller : felt,
    controller : felt,
    realms_address : felt,
):
    # SET REALM SETTLED/UNSETTLED STATE - PARSE 0 TO SET CURRENT TIME
    _set_time_staked(token_id, 0)
    _set_time_vault_staked(token_id, 0)

    # CHECK REALMS STATE
    let (realms_settled) = get_total_realms_settled()
    _set_total_realms_settled(realms_settled + 1)

    # GET REALM DATA
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(realms_address, token_id)

    # UPDATE WONDERS
    if realms_data.wonder != FALSE:
        let (wonders_logic_address) = IModuleController.get_module_address(
            controller, ModuleIds.L05_Wonders
        )
        IL05_Wonders.update_wonder_settlement(wonders_logic_address, token_id)
        return ()
    end
    return ()
end

###########
# GETTERS #
###########

@view
func get_time_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (time : felt):
    let (time) = time_staked.read(token_id)

    return (time=time)
end

@view
func get_time_vault_staked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (time : felt):
    let (time) = time_vault_staked.read(token_id)

    return (time=time)
end

@view
func get_total_realms_settled{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (realms_settled : felt):
    let (amount) = total_realms_settled.read()

    return (realms_settled=amount)
end
