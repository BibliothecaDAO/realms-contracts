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

from contracts.settling_game.utils.general import (
    unpack_data,
    convert_cost_dict_to_tokens_and_values,
    load_resource_ids_and_values_from_costs,
    sum_values_by_key,
)
from contracts.settling_game.utils.game_structs import (
    RealmBuildings,
    RealmData,
    RealmBuildingCostIds,
    RealmBuildingCostValues,
    RealmBuildingsIds,
    ModuleIds,
    ExternalContractIds,
)

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
from contracts.settling_game.interfaces.IStorage import IStorage

from contracts.settling_game.utils.library import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
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

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt
):
    # Store the address of the only fixed contract in the system.
    MODULE_initializer(address_of_controller)
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
    let (owner) = realms_IERC721.ownerOf(contract_address=s_realms_address, token_id=token_id)
    assert caller = owner

    # REALMS ADDRESS
    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    )

    # RESOURCE ADDRESS
    let (resource_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    )

    # REALMS DATA
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(
        contract_address=realms_address, token_id=token_id
    )

    # BUILDINGS STATE
    let (buildings_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S03_Buildings
    )

    # GET CURRENT BUILDINGS
    let (current_building) = IS03_Buildings.get_realm_buildings(buildings_state_address, token_id)

    # CHECK CAN BUILD
    build_buildings(buildings_state_address, token_id, current_building, building_id)

    # GET BUILDING COSTS

    # TODO:
    # the original fetch_building_cost_values used "different" values
    # in the unpack_data (0..108 by 12 for index, 4095 as mask size)
    # adapt the algo to accept this, maybe have it in the Cost struct?

    let (building_cost : Cost) = IS03_Buildings.get_building_cost(
        buildings_state_address, building_id
    )
    let (costs : Cost*) = alloc()
    assert [costs] = building_cost
    let (resource_ids : felt*) = alloc()
    let (resource_values : felt*) = alloc()
    let (resource_len : felt) = load_resource_ids_and_values_from_costs(
        resource_ids, resource_values, 1, costs, 0
    )
    let (d_len : felt, d : DictAccess*) = sum_values_by_key(
        resource_len, resource_ids, resource_values
    )
    let (token_ids : Uint256*) = alloc()
    let (token_values : Uint256*) = alloc()
    convert_cost_dict_to_tokens_and_values(d_len, d, token_ids, token_values)

    # BURN RESOURCES
    IERC1155.burnBatch(resource_address, caller, d_len, token_ids, d_len, token_values)

    # EMIT
    BuildingBuilt.emit(token_id, building_id)

    return (TRUE)
end

func build_buildings{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(
    buildings_state_address : felt,
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

    if building_id == RealmBuildingsIds.Carpenter:
        if current_buildings.Carpenter == realms_data.cities:
            assert_not_zero(0)
        end
        local id_10 = (current_buildings.Carpenter + 1) * SHIFT_6_10
        buildings[9] = id_10
    else:
        local id_10 = current_buildings.Carpenter * SHIFT_6_10
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

    if building_id == RealmBuildingsIds.Symposium:
        if current_buildings.Symposium == realms_data.cities:
            assert_not_zero(0)
        end
        local id_12 = (current_buildings.Symposium + 1) * SHIFT_6_12
        buildings[11] = id_12
    else:
        local id_12 = current_buildings.Symposium * SHIFT_6_12
        buildings[11] = id_12
    end

    if building_id == RealmBuildingsIds.LogisticsOffice:
        if current_buildings.LogisticsOffice == realms_data.cities:
            assert_not_zero(0)
        end
        local id_13 = (current_buildings.LogisticsOffice + 1) * SHIFT_6_13
        buildings[12] = id_13
    else:
        local id_13 = current_buildings.LogisticsOffice * SHIFT_6_13
        buildings[12] = id_13
    end

    if building_id == RealmBuildingsIds.ExplorersGuild:
        if current_buildings.ExplorersGuild == realms_data.cities:
            assert_not_zero(0)
        end
        local id_14 = (current_buildings.ExplorersGuild + 1) * SHIFT_6_14
        buildings[13] = id_14
    else:
        local id_14 = current_buildings.ExplorersGuild * SHIFT_6_14
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

    if building_id == RealmBuildingsIds.ResourceFacility:
        if current_buildings.ResourceFacility == realms_data.cities:
            assert_not_zero(0)
        end
        local id_16 = (current_buildings.ResourceFacility + 1) * SHIFT_6_16
        buildings[15] = id_16
    else:
        local id_16 = current_buildings.ResourceFacility * SHIFT_6_16
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

    IS03_Buildings.set_realm_buildings(buildings_state_address, token_id, value)
    return ()
end

@view
func fetch_buildings_by_type{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (realm_buildings : RealmBuildings):
    alloc_locals

    let (controller) = MODULE_controller_address()

    # state contract
    let (buildings_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S03_Buildings
    )

    let (data) = IS03_Buildings.get_realm_buildings(buildings_state_address, token_id)

    let (Fairgrounds) = unpack_data(data, 0, 63)
    let (RoyalReserve) = unpack_data(data, 6, 63)
    let (GrandMarket) = unpack_data(data, 12, 63)
    let (Castle) = unpack_data(data, 18, 63)
    let (Guild) = unpack_data(data, 24, 63)
    let (OfficerAcademy) = unpack_data(data, 30, 63)
    let (Granary) = unpack_data(data, 36, 63)
    let (Housing) = unpack_data(data, 42, 63)
    let (Amphitheater) = unpack_data(data, 48, 63)
    let (Carpenter) = unpack_data(data, 54, 63)
    let (School) = unpack_data(data, 60, 63)
    let (Symposium) = unpack_data(data, 66, 63)
    let (LogisticsOffice) = unpack_data(data, 72, 63)
    let (ExplorersGuild) = unpack_data(data, 78, 63)
    let (ParadeGrounds) = unpack_data(data, 84, 63)
    let (ResourceFacility) = unpack_data(data, 90, 63)
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
        Carpenter=Carpenter,
        School=School,
        Symposium=Symposium,
        LogisticsOffice=LogisticsOffice,
        ExplorersGuild=ExplorersGuild,
        ParadeGrounds=ParadeGrounds,
        ResourceFacility=ResourceFacility,
        Dock=Dock,
        Fishmonger=Fishmonger,
        Farms=Farms,
        Hamlet=Hamlet
        ),
    )
end
