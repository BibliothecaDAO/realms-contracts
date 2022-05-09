# ____MODULE_L03___BUILDING_LOGIC
#   TODO: Add Module Description
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.general import unpack_data, transform_costs_to_token_ids_values
from contracts.settling_game.utils.game_structs import (
    RealmBuildings,
    RealmData,
    RealmBuildingsIds,
    ModuleIds,
    ExternalContractIds,
    Cost
)

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

from contracts.settling_game.utils.constants import (
    SHIFT_6_1,
    SHIFT_6_2,
    SHIFT_6_3,
    SHIFT_6_4,
    SHIFT_6_5,
    SHIFT_6_6,
    SHIFT_6_7,
    SHIFT_6_8,
    SHIFT_6_9,
    SHIFT_6_10,
    SHIFT_6_11,
    SHIFT_6_12,
    SHIFT_6_13,
    SHIFT_6_14,
    SHIFT_6_15,
    SHIFT_6_16,
    SHIFT_6_17,
    SHIFT_6_18,
    SHIFT_6_19,
    SHIFT_6_20,
)

from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721
from contracts.settling_game.interfaces.imodules import IModuleController, IS03_Buildings

from contracts.settling_game.utils.library import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
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
func BuildingBuilt(token_id : Uint256, building_id : felt):
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

@external
func build{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256, building_id : felt) -> (success : felt):
    alloc_locals

    let (caller) = get_caller_address()
    let (controller) = MODULE_controller_address()

    # S_REALMS_ADDRESS
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.S_Realms
    )

    # OWNER CHECK
    let (owner) = realms_IERC721.ownerOf(s_realms_address, token_id)
    assert caller = owner

    # REALMS ADDRESS
    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    )

    # REALMS ADDRESS
    let (lords_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Lords
    )
    
    # TREASURY ADDRESS
    let (treasury_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Treasury
    )

    # RESOURCES ADDRESS
    let (resource_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    )

    # REALMS DATA
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(
        contract_address=realms_address, token_id=token_id
    )

    # GET CURRENT BUILDINGS
    let (current_building) = get_realm_buildings(token_id)

    # CHECK CAN BUILD
    build_buildings(token_id, current_building, building_id)

    # GET BUILDING COSTS
    let (building_cost : Cost, lords : Uint256) = get_building_cost(building_id)

    let (costs : Cost*) = alloc()
    assert [costs] = building_cost
    let (token_ids : Uint256*) = alloc()
    let (token_values : Uint256*) = alloc()
    let (token_len : felt) = transform_costs_to_token_ids_values(1, costs, token_ids, token_values)

    # BURN RESOURCES
    IERC1155.burnBatch(resource_address, caller, token_len, token_ids, token_len, token_values)

    # TRANSFER LORDS
    IERC20.transfer(lords_address, treasury_address, lords) 

    # EMIT
    BuildingBuilt.emit(token_id, building_id)

    return (TRUE)
end

func build_buildings{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(
    token_id : Uint256,
    current_realm_buildings : felt,
    building_id : felt,
):
    alloc_locals

    let (controller) = MODULE_controller_address()

    # REALMS ADDRESS
    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    )

    # REALMS DATA
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(
        contract_address=realms_address, token_id=token_id
    )

    # GET CURRENT BUILDINGS
    let (current_buildings : RealmBuildings) = fetch_buildings_by_type(token_id)

    let (buildings : felt*) = alloc()

    if building_id == RealmBuildingsIds.Fairgrounds:
        # CHECK SPACE
        if current_buildings.Fairgrounds == realms_data.regions:
            assert_not_zero(0)
        end
        local id_1 = (current_buildings.Fairgrounds + 1) * SHIFT_6_1
        buildings[0] = id_1
    else:
        buildings[0] = current_buildings.Fairgrounds * SHIFT_6_1
    end

    if building_id == RealmBuildingsIds.RoyalReserve:
        if current_buildings.RoyalReserve == realms_data.regions:
            assert_not_zero(0)
        end
        local id_2 = (current_buildings.RoyalReserve + 1) * SHIFT_6_2
        buildings[1] = id_2
    else:
        local id_2 = current_buildings.RoyalReserve * SHIFT_6_2
        buildings[1] = id_2
    end

    if building_id == RealmBuildingsIds.GrandMarket:
        if current_buildings.GrandMarket == realms_data.regions:
            assert_not_zero(0)
        end
        local id_3 = (current_buildings.GrandMarket + 1) * SHIFT_6_3
        buildings[2] = id_3
    else:
        local id_3 = current_buildings.GrandMarket * SHIFT_6_3
        buildings[2] = id_3
    end

    if building_id == RealmBuildingsIds.Castle:
        if current_buildings.Castle == realms_data.regions:
            assert_not_zero(0)
        end
        local id_4 = (current_buildings.Castle + 1) * SHIFT_6_4
        buildings[3] = id_4
    else:
        local id_4 = current_buildings.Castle * SHIFT_6_4
        buildings[3] = id_4
    end

    if building_id == RealmBuildingsIds.Guild:
        if current_buildings.Guild == realms_data.regions:
            assert_not_zero(0)
        end
        local id_5 = (current_buildings.Guild + 1) * SHIFT_6_5
        buildings[4] = id_5
    else:
        local id_5 = current_buildings.Guild * SHIFT_6_5
        buildings[4] = id_5
    end

    if building_id == RealmBuildingsIds.OfficerAcademy:
        if current_buildings.OfficerAcademy == realms_data.regions:
            assert_not_zero(0)
        end
        local id_6 = (current_buildings.OfficerAcademy + 1) * SHIFT_6_6
        buildings[5] = id_6
    else:
        local id_6 = current_buildings.OfficerAcademy * SHIFT_6_6
        buildings[5] = id_6
    end

    if building_id == RealmBuildingsIds.Granary:
        if current_buildings.Granary == realms_data.cities:
            assert_not_zero(0)
        end
        local id_7 = (current_buildings.Granary + 1) * SHIFT_6_7
        buildings[6] = id_7
    else:
        local id_7 = current_buildings.Granary * SHIFT_6_7
        buildings[6] = id_7
    end

    if building_id == RealmBuildingsIds.Housing:
        if current_buildings.Housing == realms_data.cities:
            assert_not_zero(0)
        end
        local id_8 = (current_buildings.Housing + 1) * SHIFT_6_8
        buildings[7] = id_8
    else:
        local id_8 = current_buildings.Housing * SHIFT_6_8
        buildings[7] = id_8
    end

    if building_id == RealmBuildingsIds.Amphitheater:
        if current_buildings.Amphitheater == realms_data.cities:
            assert_not_zero(0)
        end
        local id_9 = (current_buildings.Amphitheater + 1) * SHIFT_6_9
        buildings[8] = id_9
    else:
        local id_9 = current_buildings.Amphitheater * SHIFT_6_9
        buildings[8] = id_9
    end

    if building_id == RealmBuildingsIds.ArcherTower:
        if current_buildings.ArcherTower == realms_data.cities:
            assert_not_zero(0)
        end
        local id_10 = (current_buildings.ArcherTower + 1) * SHIFT_6_10
        buildings[9] = id_10
    else:
        local id_10 = current_buildings.ArcherTower * SHIFT_6_10
        buildings[9] = id_10
    end

    if building_id == RealmBuildingsIds.School:
        if current_buildings.School == realms_data.cities:
            assert_not_zero(0)
        end
        local id_11 = (current_buildings.School + 1) * SHIFT_6_11
        buildings[10] = id_11
    else:
        local id_11 = current_buildings.School * SHIFT_6_11
        buildings[10] = id_11
    end

    if building_id == RealmBuildingsIds.MageTower:
        if current_buildings.MageTower == realms_data.cities:
            assert_not_zero(0)
        end
        local id_12 = (current_buildings.MageTower + 1) * SHIFT_6_12
        buildings[11] = id_12
    else:
        local id_12 = current_buildings.MageTower * SHIFT_6_12
        buildings[11] = id_12
    end

    if building_id == RealmBuildingsIds.TradeOffice: 
        if current_buildings.TradeOffice == realms_data.cities:
            assert_not_zero(0)
        end
        local id_13 = (current_buildings.TradeOffice + 1) * SHIFT_6_13
        buildings[12] = id_13
    else:
        local id_13 = current_buildings.TradeOffice * SHIFT_6_13
        buildings[12] = id_13
    end

    if building_id == RealmBuildingsIds.Architect:
        if current_buildings.Architect == realms_data.cities:
            assert_not_zero(0)
        end
        local id_14 = (current_buildings.Architect + 1) * SHIFT_6_14
        buildings[13] = id_14
    else:
        local id_14 = current_buildings.Architect * SHIFT_6_14
        buildings[13] = id_14
    end

    if building_id == RealmBuildingsIds.ParadeGrounds:
        if current_buildings.ParadeGrounds == realms_data.cities:
            assert_not_zero(0)
        end
        local id_15 = (current_buildings.ParadeGrounds + 1) * SHIFT_6_15
        buildings[14] = id_15
    else:
        local id_15 = current_buildings.ParadeGrounds * SHIFT_6_15
        buildings[14] = id_15
    end

    if building_id == RealmBuildingsIds.Barracks:
        if current_buildings.Barracks == realms_data.cities:
            assert_not_zero(0)
        end
        local id_16 = (current_buildings.Barracks + 1) * SHIFT_6_16
        buildings[15] = id_16
    else:
        local id_16 = current_buildings.Barracks * SHIFT_6_16
        buildings[15] = id_16
    end

    if building_id == RealmBuildingsIds.Dock:
        if current_buildings.Dock == realms_data.harbours:
            assert_not_zero(0)
        end
        local id_17 = (current_buildings.Dock + 1) * SHIFT_6_17
        buildings[16] = id_17
    else:
        local id_17 = current_buildings.Dock * SHIFT_6_17
        buildings[16] = id_17
    end

    if building_id == RealmBuildingsIds.Fishmonger:
        if current_buildings.Fishmonger == realms_data.harbours:
            assert_not_zero(0)
        end
        local id_18 = (current_buildings.Fishmonger + 1) * SHIFT_6_18
        buildings[17] = id_18
    else:
        local id_18 = current_buildings.Fishmonger * SHIFT_6_18
        buildings[17] = id_18
    end

    if building_id == RealmBuildingsIds.Farms:
        if current_buildings.Farms == realms_data.rivers:
            assert_not_zero(0)
        end
        local id_19 = (current_buildings.Farms + 1) * SHIFT_6_19
        buildings[18] = id_19
    else:
        local id_19 = current_buildings.Farms * SHIFT_6_19
        buildings[18] = id_19
    end

    if building_id == RealmBuildingsIds.Hamlet:
        if current_buildings.Hamlet == realms_data.rivers:
            assert_not_zero(0)
        end
        local id_20 = (current_buildings.Hamlet + 1) * SHIFT_6_20
        buildings[19] = id_20
    else:
        local id_20 = current_buildings.Hamlet * SHIFT_6_20
        buildings[19] = id_20
    end

    tempvar value = buildings[19] + buildings[18] + buildings[17] + buildings[16] + buildings[15] + buildings[14] + buildings[13] + buildings[12] + buildings[11] + buildings[10] + buildings[9] + buildings[8] + buildings[7] + buildings[6] + buildings[5] + buildings[4] + buildings[3] + buildings[2] + buildings[1] + buildings[0]

    set_realm_buildings(token_id, value)
    return ()
end

@view
func fetch_buildings_by_type{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (realm_buildings : RealmBuildings):
    alloc_locals

    let (data) = get_realm_buildings(token_id)

    let (Fairgrounds) = unpack_data(data, 0, 63)
    let (RoyalReserve) = unpack_data(data, 6, 63)
    let (GrandMarket) = unpack_data(data, 12, 63)
    let (Castle) = unpack_data(data, 18, 63)
    let (Guild) = unpack_data(data, 24, 63)
    let (OfficerAcademy) = unpack_data(data, 30, 63)
    let (Granary) = unpack_data(data, 36, 63)
    let (Housing) = unpack_data(data, 42, 63)
    let (Amphitheater) = unpack_data(data, 48, 63)
    let (ArcherTower) = unpack_data(data, 54, 63)
    let (School) = unpack_data(data, 60, 63)
    let (MageTower) = unpack_data(data, 66, 63)
    let (TradeOffice) = unpack_data(data, 72, 63)
    let (Architect) = unpack_data(data, 78, 63)
    let (ParadeGrounds) = unpack_data(data, 84, 63)
    let (Barracks) = unpack_data(data, 90, 63)
    let (Dock) = unpack_data(data, 96, 63)
    let (Fishmonger) = unpack_data(data, 102, 63)
    let (Farms) = unpack_data(data, 108, 63)
    let (Hamlet) = unpack_data(data, 114, 63)

    return (
        realm_buildings=RealmBuildings(
        Fairgrounds=Fairgrounds,
        RoyalReserve=RoyalReserve,
        GrandMarket=GrandMarket,
        Castle=Castle,
        Guild=Guild,
        OfficerAcademy=OfficerAcademy,
        Granary=Granary,
        Housing=Housing,
        Amphitheater=Amphitheater,
        ArcherTower=ArcherTower,
        School=School,
        MageTower=MageTower,
        TradeOffice=TradeOffice,
        Architect=Architect,
        ParadeGrounds=ParadeGrounds,
        Barracks=Barracks,
        Dock=Dock,
        Fishmonger=Fishmonger,
        Farms=Farms,
        Hamlet=Hamlet
        ),
    )
end

###########
# STORAGE #
###########

@storage_var
func realm_buildings(token_id : Uint256) -> (buildings : felt):
end

@storage_var
func building_cost(building_id : felt) -> (cost : Cost):
end

@storage_var
func building_lords_cost(building_id : felt) -> (lords : Uint256):
end


###########
# SETTERS #
###########

func set_realm_buildings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, buildings_value : felt
):
    realm_buildings.write(token_id, buildings_value)

    return ()
end

@external
func set_building_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    building_id : felt, cost : Cost, lords : Uint256
):
    # TODO: auth + range checks on the cost struct
    building_cost.write(building_id, cost)
    building_lords_cost.write(building_id, lords)
    return ()
end

###########
# GETTERS #
###########

@view
func get_realm_buildings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (buildings : felt):
    let (buildings) = realm_buildings.read(token_id)

    return (buildings=buildings)
end

@view
func get_building_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    building_id : felt
) -> (cost : Cost, lords: Uint256):
    let (cost) = building_cost.read(building_id)
    let (lords) = building_lords_cost.read(building_id)
    return (cost, lords)
end
