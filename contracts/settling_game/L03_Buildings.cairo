# ____MODULE_L03___BUILDING_LOGIC
#   Manages all buildings in game. Responsible for construction of buildings.
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.library.library_buildings import BUILDINGS
from contracts.settling_game.utils.general import unpack_data, transform_costs_to_token_ids_values
from contracts.settling_game.utils.game_structs import (
    RealmBuildings,
    RealmData,
    RealmBuildingsIds,
    ModuleIds,
    ExternalContractIds,
    Cost,
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
from contracts.settling_game.interfaces.imodules import IModuleController

from contracts.settling_game.library.library_module import (
    MODULE_controller_address,
    MODULE_only_approved,
    MODULE_initializer,
    MODULE_only_arbiter,
    MODULE_ERC721_owner_check,
)

from openzeppelin.upgrades.library import (
    Proxy_initializer,
    Proxy_only_admin,
    Proxy_set_implementation,
)

##########
# EVENTS #
##########

@event
func BuildingBuilt(token_id : Uint256, building_id : felt):
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

@storage_var
func castle_time(token_id : felt) -> (time : felt):
end

###############
# CONSTRUCTOR #
###############

@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt, proxy_admin : felt
):
    MODULE_initializer(address_of_controller)
    Proxy_initializer(proxy_admin)
    return ()
end

@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
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

    # AUTH
    MODULE_ERC721_owner_check(token_id, ExternalContractIds.S_Realms)

    # EXTERNAL ADDRESSES
    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    )
    let (lords_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Lords
    )
    let (treasury_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Treasury
    )
    let (resource_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Resources
    )

    # REALMS DATA
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(
        contract_address=realms_address, token_id=token_id
    )

    # Check Area

    # BUILD
    build_buildings(token_id, building_id)

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
    # IERC20.transfer(lords_address, treasury_address, lords)

    # EMIT
    BuildingBuilt.emit(token_id, building_id)

    return (TRUE)
end

func build_buildings{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256, building_id : felt):
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
    let (current_buildings : RealmBuildings) = get_buildings_unpacked(token_id)

    let (buildings : felt*) = alloc()

    if building_id == RealmBuildingsIds.House:
        # CHECK SPACE
        if current_buildings.House == realms_data.regions:
            assert_not_zero(0)
        end
        local id_1 = (current_buildings.House + 1) * SHIFT_6_1
        buildings[0] = id_1
    else:
        buildings[0] = current_buildings.House * SHIFT_6_1
    end

    if building_id == RealmBuildingsIds.StoreHouse:
        if current_buildings.StoreHouse == realms_data.regions:
            assert_not_zero(0)
        end
        local id_2 = (current_buildings.StoreHouse + 1) * SHIFT_6_2
        buildings[1] = id_2
    else:
        local id_2 = current_buildings.StoreHouse * SHIFT_6_2
        buildings[1] = id_2
    end

    if building_id == RealmBuildingsIds.Granary:
        if current_buildings.Granary == realms_data.regions:
            assert_not_zero(0)
        end
        local id_3 = (current_buildings.Granary + 1) * SHIFT_6_3
        buildings[2] = id_3
    else:
        local id_3 = current_buildings.Granary * SHIFT_6_3
        buildings[2] = id_3
    end

    if building_id == RealmBuildingsIds.Farm:
        if current_buildings.Farm == realms_data.regions:
            assert_not_zero(0)
        end
        local id_4 = (current_buildings.Farm + 1) * SHIFT_6_4
        buildings[3] = id_4
    else:
        local id_4 = current_buildings.Farm * SHIFT_6_4
        buildings[3] = id_4
    end

    if building_id == RealmBuildingsIds.FishingVillage:
        if current_buildings.FishingVillage == realms_data.regions:
            assert_not_zero(0)
        end
        local id_5 = (current_buildings.FishingVillage + 1) * SHIFT_6_5
        buildings[4] = id_5
    else:
        local id_5 = current_buildings.FishingVillage * SHIFT_6_5
        buildings[4] = id_5
    end

    if building_id == RealmBuildingsIds.Barracks:
        if current_buildings.Barracks == realms_data.regions:
            assert_not_zero(0)
        end
        local id_6 = (current_buildings.Barracks + 1) * SHIFT_6_6
        buildings[5] = id_6
    else:
        local id_6 = current_buildings.Barracks * SHIFT_6_6
        buildings[5] = id_6
    end

    if building_id == RealmBuildingsIds.MageTower:
        if current_buildings.MageTower == realms_data.cities:
            assert_not_zero(0)
        end
        local id_7 = (current_buildings.MageTower + 1) * SHIFT_6_7
        buildings[6] = id_7
    else:
        local id_7 = current_buildings.MageTower * SHIFT_6_7
        buildings[6] = id_7
    end

    if building_id == RealmBuildingsIds.ArcherTower:
        if current_buildings.ArcherTower == realms_data.cities:
            assert_not_zero(0)
        end
        local id_8 = (current_buildings.ArcherTower + 1) * SHIFT_6_8
        buildings[7] = id_8
    else:
        local id_8 = current_buildings.ArcherTower * SHIFT_6_8
        buildings[7] = id_8
    end

    if building_id == RealmBuildingsIds.Castle:
        if current_buildings.Castle == realms_data.cities:
            assert_not_zero(0)
        end
        local id_9 = (current_buildings.Castle + 1) * SHIFT_6_9
        buildings[8] = id_9
    else:
        local id_9 = current_buildings.Castle * SHIFT_6_9
        buildings[8] = id_9
    end

    tempvar value = buildings[8] + buildings[7] + buildings[6] + buildings[5] + buildings[4] + buildings[3] + buildings[2] + buildings[1] + buildings[0]

    realm_buildings.write(token_id, value)
    return ()
end

###########
# GETTERS #
###########

@view
func get_buildings_unpacked{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (realm_buildings : RealmBuildings):
    alloc_locals

    let (data) = get_realm_buildings(token_id)

    let (House) = unpack_data(data, 0, 63)
    let (StoreHouse) = unpack_data(data, 6, 63)
    let (Granary) = unpack_data(data, 12, 63)
    let (Farm) = unpack_data(data, 18, 63)
    let (FishingVillage) = unpack_data(data, 24, 63)
    let (Barracks) = unpack_data(data, 30, 63)
    let (MageTower) = unpack_data(data, 36, 63)
    let (ArcherTower) = unpack_data(data, 42, 63)
    let (Castle) = unpack_data(data, 48, 63)

    return (
        realm_buildings=RealmBuildings(
        House=House,
        StoreHouse=StoreHouse,
        Granary=Granary,
        Farm=Farm,
        FishingVillage=FishingVillage,
        Barracks=Barracks,
        MageTower=MageTower,
        ArcherTower=ArcherTower,
        Castle=Castle
        ),
    )
end

@view
func get_realm_buildings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (buildings : felt):
    let (buildings) = realm_buildings.read(token_id)

    return (buildings)
end

@view
func get_building_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    building_id : felt
) -> (cost : Cost, lords : Uint256):
    let (cost) = building_cost.read(building_id)
    let (lords) = building_lords_cost.read(building_id)
    return (cost, lords)
end

#########
# ADMIN #
#########

@external
func set_building_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    building_id : felt, cost : Cost, lords : Uint256
):
    # TODO: range checks on the cost struct
    Proxy_only_admin()
    building_cost.write(building_id, cost)
    building_lords_cost.write(building_id, lords)
    return ()
end
