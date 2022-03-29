%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.general import unpack_data
from contracts.settling_game.utils.game_structs import (
    RealmBuildings, RealmData, RealmBuildingCostIds, RealmBuildingCostValues, RealmBuildingsIds,
    ModuleIds)

from contracts.settling_game.utils.constants import (
    SHIFT_6_1, SHIFT_6_2, SHIFT_6_3, SHIFT_6_4, SHIFT_6_5, SHIFT_6_6, SHIFT_6_7, SHIFT_6_8,
    SHIFT_6_9, SHIFT_6_10, SHIFT_6_11, SHIFT_6_12, SHIFT_6_13, SHIFT_6_14, SHIFT_6_15, SHIFT_6_16,
    SHIFT_6_17, SHIFT_6_18, SHIFT_6_19, SHIFT_6_20)

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721
from contracts.settling_game.interfaces.imodules import IModuleController, IS03_Buildings

# #### Module 3A ####
#                   #
# Buildings Logic   #
#                   #
#####################

@storage_var
func controller_address() -> (address : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address_of_controller : felt):
    # Store the address of the only fixed contract in the system.
    controller_address.write(address_of_controller)
    return ()
end

@external
func build{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(
        token_id : Uint256, building_id : felt, token_ids_len : felt, token_ids : felt*,
        token_values_len : felt, token_values : felt*):
    alloc_locals

    let (caller) = get_caller_address()
    let (controller) = controller_address.read()

    # s realms address
    let (s_realms_address) = IModuleController.get_s_realms_address(contract_address=controller)

    # check owner
    let (owner) = realms_IERC721.ownerOf(contract_address=s_realms_address, token_id=token_id)
    assert caller = owner

    # realms address
    let (realms_address) = IModuleController.get_realms_address(contract_address=controller)

    # resource address
    let (resource_address) = IModuleController.get_resources_address(contract_address=controller)

    # realms data
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(
        contract_address=realms_address, token_id=token_id)

    # building state address
    let (buildings_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S03_Buildings)

    # get current buildings already constructed
    let (current_building) = IS03_Buildings.get_realm_buildings(buildings_state_address, token_id)

    # check can build
    build_buildings(buildings_state_address, token_id, current_building, building_id)

    # get costs of building
    let (_token_ids_len, ids) = fetch_building_cost_ids(building_id)
    let (_token_values_len, values) = fetch_building_cost_values(building_id)

    # loop to check correct resources been sent
    check_correct_resources(
        token_ids_len,
        token_ids,
        token_values_len,
        token_values,
        _token_ids_len,
        ids,
        _token_values_len,
        values)

    # burnt the resources
    IERC1155.burn_batch(
        resource_address, caller, token_ids_len, token_ids, token_values_len, token_values)

    return ()
end

@external
func build_buildings{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(
        buildings_state_address : felt, token_id : Uint256, current_realm_buildings : felt,
        building_id : felt):
    alloc_locals
    let (caller) = get_caller_address()
    let (controller) = controller_address.read()

    # realms address
    let (realms_address) = IModuleController.get_realms_address(contract_address=controller)

    # realms data
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(
        contract_address=realms_address, token_id=token_id)

    # get current buildings on realm
    let (current_buildings : RealmBuildings) = fetch_buildings_by_type(token_id)

    # make tempvar
    let (local buildings : felt*) = alloc()

    if building_id == RealmBuildingsIds.Fairgrounds:
        # check space
        if current_buildings.Fairgrounds == realms_data.regions:
            assert_not_zero(0)
        end
        local id_1 = (current_buildings.Fairgrounds + 1) * SHIFT_6_1
        buildings[0] = id_1
    else:
        buildings[0] = current_buildings.Fairgrounds * SHIFT_6_1
    end

    if building_id == RealmBuildingsIds.RoyalReserve:
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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
        # check space
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

    # # TODO: EMIT BUILDING CONSTRUCTION

    return ()
end

func check_correct_resources{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(
        token_ids_len : felt, token_ids : felt*, token_values_len : felt, token_values : felt*,
        ids_len : felt, ids : felt*, values_len : felt, values : felt*):
    if token_ids_len == 0:
        return ()
    end
    if [token_ids] != [ids]:
        assert_not_zero(0)
    end
    if [token_values] != [values]:
        assert_not_zero(0)
    end

    return check_correct_resources(
        token_ids_len=token_ids_len - 1,
        token_ids=token_ids + 1,
        token_values_len=token_values_len - 1,
        token_values=token_values + 1,
        ids_len=ids_len - 1,
        ids=ids + 1,
        values_len=values_len - 1,
        values=values + 1)
end

@external
func fetch_building_cost_ids{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(building_id : felt) -> (
        realm_building_ids_len : felt, realm_building_ids : felt*):
    alloc_locals

    let (controller) = controller_address.read()

    # state contract
    let (buildings_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S03_Buildings)

    let (local data) = IS03_Buildings.get_building_cost_ids(buildings_state_address, building_id)

    let (local resource_1) = unpack_data(data, 0, 255)
    let (local resource_2) = unpack_data(data, 8, 255)
    let (local resource_3) = unpack_data(data, 16, 255)
    let (local resource_4) = unpack_data(data, 24, 255)
    let (local resource_5) = unpack_data(data, 32, 255)
    let (local resource_6) = unpack_data(data, 40, 255)
    let (local resource_7) = unpack_data(data, 48, 255)
    let (local resource_8) = unpack_data(data, 56, 255)
    let (local resource_9) = unpack_data(data, 64, 255)
    let (local resource_10) = unpack_data(data, 72, 255)

    let (local resource_ids : felt*) = alloc()
    let len = 0

    if resource_1 != 0:
        resource_ids[0] = resource_1
        tempvar len = 1
    else:
        tempvar len = len
    end

    if resource_2 != 0:
        resource_ids[1] = resource_2
        tempvar len = 2
    else:
        tempvar len = len
    end

    if resource_3 != 0:
        resource_ids[2] = resource_3
        tempvar len = 3
    else:
        tempvar len = len
    end

    if resource_4 != 0:
        resource_ids[3] = resource_4
        tempvar len = 4
    else:
        tempvar len = len
    end

    if resource_5 != 0:
        resource_ids[4] = resource_5
        tempvar len = 5
    else:
        tempvar len = len
    end

    if resource_6 != 0:
        resource_ids[5] = resource_6
        tempvar len = 6
    else:
        tempvar len = len
    end

    if resource_7 != 0:
        resource_ids[6] = resource_7
        tempvar len = 7
    else:
        tempvar len = len
    end

    if resource_8 != 0:
        resource_ids[7] = resource_8
        tempvar len = 8
    else:
        tempvar len = len
    end

    if resource_9 != 0:
        resource_ids[8] = resource_9
        tempvar len = 9
    else:
        tempvar len = len
    end

    if resource_10 != 0:
        resource_ids[9] = resource_10
        tempvar len = 10
    else:
        tempvar len = len
    end

    return (realm_building_ids_len=len, realm_building_ids=resource_ids)
end

@external
func fetch_building_cost_values{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(building_id : felt) -> (
        realm_building_costs_len : felt, realm_building_costs : felt*):
    alloc_locals

    let (controller) = controller_address.read()

    # state contract
    let (buildings_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=6)

    let (local data) = IS03_Buildings.get_building_cost_values(buildings_state_address, building_id)

    let (local resource_1_values) = unpack_data(data, 0, 4095)
    let (local resource_2_values) = unpack_data(data, 12, 4095)
    let (local resource_3_values) = unpack_data(data, 24, 4095)
    let (local resource_4_values) = unpack_data(data, 36, 4095)
    let (local resource_5_values) = unpack_data(data, 48, 4095)
    let (local resource_6_values) = unpack_data(data, 60, 4095)
    let (local resource_7_values) = unpack_data(data, 72, 4095)
    let (local resource_8_values) = unpack_data(data, 84, 4095)
    let (local resource_9_values) = unpack_data(data, 96, 4095)
    let (local resource_10_values) = unpack_data(data, 108, 4095)

    let (local resource_values : felt*) = alloc()
    local len = 0

    if resource_1_values != 0:
        resource_values[0] = resource_1_values
        tempvar len = 1
    else:
        tempvar len = len
    end

    if resource_2_values != 0:
        resource_values[1] = resource_2_values
        tempvar len = 2
    else:
        tempvar len = len
    end

    if resource_3_values != 0:
        resource_values[2] = resource_3_values
        tempvar len = 3
    else:
        tempvar len = len
    end

    if resource_4_values != 0:
        resource_values[3] = resource_4_values
        tempvar len = 4
    else:
        tempvar len = len
    end

    if resource_5_values != 0:
        resource_values[4] = resource_5_values
        tempvar len = 5
    else:
        tempvar len = len
    end

    if resource_6_values != 0:
        resource_values[5] = resource_6_values
        tempvar len = 6
    else:
        tempvar len = len
    end

    if resource_7_values != 0:
        resource_values[6] = resource_7_values
        tempvar len = 7
    else:
        tempvar len = len
    end

    if resource_8_values != 0:
        resource_values[7] = resource_8_values
        tempvar len = 8
    else:
        tempvar len = len
    end

    if resource_9_values != 0:
        resource_values[8] = resource_9_values
        tempvar len = 9
    else:
        tempvar len = len
    end

    if resource_10_values != 0:
        resource_values[9] = resource_10_values
        tempvar len = 10
    else:
        tempvar len = len
    end

    return (realm_building_costs_len=len, realm_building_costs=resource_values)
end

@external
func fetch_buildings_by_type{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(token_id : Uint256) -> (realm_buildings : RealmBuildings):
    alloc_locals

    let (controller) = controller_address.read()

    # state contract
    let (buildings_state_address) = IModuleController.get_module_address(
        contract_address=controller, module_id=ModuleIds.S03_Buildings)

    let (local data) = IS03_Buildings.get_realm_buildings(buildings_state_address, token_id)

    let (local Fairgrounds) = unpack_data(data, 0, 63)
    let (local RoyalReserve) = unpack_data(data, 6, 63)
    let (local GrandMarket) = unpack_data(data, 12, 63)
    let (local Castle) = unpack_data(data, 18, 63)
    let (local Guild) = unpack_data(data, 24, 63)
    let (local OfficerAcademy) = unpack_data(data, 30, 63)
    let (local Granary) = unpack_data(data, 36, 63)
    let (local Housing) = unpack_data(data, 42, 63)
    let (local Amphitheater) = unpack_data(data, 48, 63)
    let (local Carpenter) = unpack_data(data, 54, 63)
    let (local School) = unpack_data(data, 60, 63)
    let (local Symposium) = unpack_data(data, 66, 63)
    let (local LogisticsOffice) = unpack_data(data, 72, 63)
    let (local ExplorersGuild) = unpack_data(data, 78, 63)
    let (local ParadeGrounds) = unpack_data(data, 84, 63)
    let (local ResourceFacility) = unpack_data(data, 90, 63)
    let (local Dock) = unpack_data(data, 96, 63)
    let (local Fishmonger) = unpack_data(data, 102, 63)
    let (local Farms) = unpack_data(data, 108, 63)
    let (local Hamlet) = unpack_data(data, 114, 63)

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
        ))
end
