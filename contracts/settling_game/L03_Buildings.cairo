%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math import assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_nn_le
from starkware.cairo.common.hash_state import hash_init, hash_update, HashState
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from contracts.settling_game.utils.interfaces import IModuleController, IS03_Buildings
from contracts.settling_game.utils.general import unpack_data

from contracts.settling_game.utils.game_structs import (
    RealmBuildings, RealmData, RealmBuildingCostIds, RealmBuildingCostValues)

from contracts.settling_game.utils.constants import (
    SHIFT_8_1, SHIFT_8_2, SHIFT_8_3, SHIFT_8_4, SHIFT_8_5, SHIFT_8_6, SHIFT_8_7, SHIFT_8_8)

from contracts.token.IERC20 import IERC20
from contracts.token.ERC1155.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.s_realms_IERC721 import s_realms_IERC721

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
        contract_address=controller, module_id=6)

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

    if building_id == 0:
        # check space
        if current_buildings.castles == realms_data.regions:
            assert 1 = 2
        end
        local id_1 = (current_buildings.castles + 1) * SHIFT_8_1
        buildings[0] = id_1
    else:
        buildings[0] = current_buildings.castles * SHIFT_8_1
    end

    if building_id == 1:
        # check space
        if current_buildings.markets == realms_data.cities:
            assert 1 = 2
        end
        local id_2 = (current_buildings.markets + 1) * SHIFT_8_2
        buildings[1] = id_2
    else:
        local id_2 = current_buildings.markets * SHIFT_8_2
        buildings[1] = id_2
    end

    if building_id == 2:
        # check space
        if current_buildings.aquaducts == realms_data.rivers:
            assert 1 = 2
        end
        local id_3 = (current_buildings.aquaducts + 1) * SHIFT_8_3
        buildings[2] = id_3
    else:
        local id_3 = current_buildings.aquaducts * SHIFT_8_3
        buildings[2] = id_3
    end

    if building_id == 3:
        # check space
        if current_buildings.ports == realms_data.harbours:
            assert 1 = 2
        end
        local id_4 = (current_buildings.ports + 1) * SHIFT_8_4
        buildings[3] = id_4
    else:
        local id_4 = current_buildings.ports * SHIFT_8_4
        buildings[3] = id_4
    end

    if building_id == 4:
        # check space
        if current_buildings.barracks == realms_data.cities:
            assert 1 = 2
        end
        local id_5 = (current_buildings.barracks + 1) * SHIFT_8_5
        buildings[4] = id_5
    else:
        local id_5 = current_buildings.barracks * SHIFT_8_5
        buildings[4] = id_5
    end

    if building_id == 5:
        # check space
        if current_buildings.farms == realms_data.cities:
            assert 1 = 2
        end
        local id_6 = (current_buildings.farms + 1) * SHIFT_8_6
        buildings[5] = id_6
    else:
        local id_6 = current_buildings.farms * SHIFT_8_6
        buildings[5] = id_6
    end

    if building_id == 6:
        # check space
        if current_buildings.temples == realms_data.cities:
            assert 1 = 2
        end
        local id_7 = (current_buildings.temples + 1) * SHIFT_8_7
        buildings[6] = id_7
    else:
        local id_7 = current_buildings.temples * SHIFT_8_7
        buildings[6] = id_7
    end

    if building_id == 7:
        # check space
        if current_buildings.shipyards == realms_data.harbours:
            assert 1 = 2
        end
        local id_8 = (current_buildings.shipyards + 1) * SHIFT_8_8
        buildings[7] = id_8
    else:
        local id_8 = current_buildings.shipyards * SHIFT_8_8
        buildings[7] = id_8
    end

    tempvar value = buildings[7] + buildings[6] + buildings[5] + buildings[4] + buildings[3] + buildings[2] + buildings[1] + buildings[0]

    IS03_Buildings.set_realm_buildings(buildings_state_address, token_id, value)

    return ()
end

@external
func check_correct_resources{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*}(
        token_ids_len : felt, token_ids : felt*, token_values_len : felt, token_values : felt*,
        ids_len : felt, ids : felt*, values_len : felt, values : felt*):
    if token_ids_len == 0:
        return ()
    end
    if [token_ids] != [ids]:
        assert 1 = 1 + 1
    end
    if [token_values] != [values]:
        assert 1 = 1 + 1
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
        contract_address=controller, module_id=6)

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
        contract_address=controller, module_id=6)

    let (local data) = IS03_Buildings.get_realm_buildings(buildings_state_address, token_id)

    let (local castles) = unpack_data(data, 0, 255)
    let (local markets) = unpack_data(data, 8, 255)
    let (local aquaducts) = unpack_data(data, 16, 255)
    let (local ports) = unpack_data(data, 24, 255)
    let (local barracks) = unpack_data(data, 32, 255)
    let (local farms) = unpack_data(data, 40, 255)
    let (local temples) = unpack_data(data, 48, 255)
    let (local shipyards) = unpack_data(data, 56, 255)

    return (
        realm_buildings=RealmBuildings(
        castles=castles,
        markets=markets,
        aquaducts=aquaducts,
        ports=ports,
        barracks=barracks,
        farms=farms,
        temples=temples,
        shipyards=shipyards))
end
