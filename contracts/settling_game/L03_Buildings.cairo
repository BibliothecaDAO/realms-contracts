# -----------------------------------
# ____MODULE_L03___BUILDING_LOGIC
#   Manages all buildings in game. Responsible for construction of buildings.
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.library.library_buildings import Buildings
from contracts.settling_game.library.library_resources import Resources
from contracts.settling_game.utils.constants import STORE_HOUSE_SIZE

from contracts.settling_game.utils.general import unpack_data, transform_costs_to_tokens
from contracts.settling_game.utils.game_structs import (
    RealmBuildings,
    RealmData,
    RealmBuildingsIds,
    ModuleIds,
    ExternalContractIds,
    Cost,
    PackedBuildings,
)

from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.imodules import IFood
from contracts.settling_game.library.library_module import Module

# -----------------------------------
# Events
# -----------------------------------

@event
func BuildingBuilt(token_id : Uint256, building_id : felt):
end

@event
func BuildingIntegrity(token_id : Uint256, building_id : felt, building_integrity : felt):
end

# -----------------------------------
# Storage
# -----------------------------------

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
func buildings_integrity(token_id : Uint256) -> (integrity : PackedBuildings):
end

# -----------------------------------
# Initialize & upgrade
# -----------------------------------

# @notice Module initializer
# @param address_of_controller: Controller/arbiter address
# @return proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt, proxy_admin : felt
):
    Module.initializer(address_of_controller)
    Proxy.initializer(proxy_admin)
    return ()
end

# @notice Set new proxy implementation
# @dev Can only be set by the arbiter
# @param new_implementation: New implementation contract address
@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy.assert_only_admin()
    Proxy._set_implementation_hash(new_implementation)
    return ()
end

# -----------------------------------
# External
# -----------------------------------

# @notice Build building on a realm
# @param token_id: Staked Realm id (S_Realm)
# @param building_id: Building id
# @return success: Returns TRUE when successfull
@external
func build{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256, building_id : felt, quantity : felt) -> (success : felt):
    alloc_locals

    let (caller) = get_caller_address()
    let (controller) = Module.controller_address()

    # AUTH
    Module.ERC721_owner_check(token_id, ExternalContractIds.S_Realms)

    # EXTERNAL ADDRESSES
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms)
    let (resource_address) = Module.get_external_contract_address(ExternalContractIds.Resources)

    # Get Realm Data
    let (realms_data : RealmData) = realms_IERC721.fetch_realm_data(
        contract_address=realms_address, token_id=token_id
    )

    let (realm_buildings_integrity : RealmBuildings) = get_effective_buildings(token_id)

    # Check Area, revert if no space available
    let (can_build) = Buildings.can_build(
        building_id, quantity, realm_buildings_integrity, realms_data.cities, realms_data.regions
    )

    with_attr error_message("Buildings: building size greater than buildable area"):
        assert_not_zero(can_build)
    end

    with_attr error_message("Buildings: QTY must be greater than 0"):
        assert_not_zero(quantity)
    end

    # Build buildings and set state
    build_buildings(token_id, building_id, quantity, realms_data)

    # Workhuts have a fixed cost according to the Realms resources
    if building_id == RealmBuildingsIds.House:
        let (
            resource_ids_len, resource_ids, resource_values_len, resource_values
        ) = get_workhut_costs(realms_data, quantity)

        IERC1155.burnBatch(
            resource_address,
            caller,
            resource_ids_len,
            resource_ids,
            resource_values_len,
            resource_values,
        )
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar bitwise_ptr = bitwise_ptr
    else:
        let (building_cost : Cost, _) = get_building_cost(building_id)

        let (local data : Cost*) = alloc()
        assert data[0] = building_cost

        let (token_len, token_ids, token_values) = transform_costs_to_tokens(1, data, quantity)
        IERC1155.burnBatch(resource_address, caller, token_len, token_ids, token_len, token_values)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar bitwise_ptr = bitwise_ptr
    end

    # EMIT
    # TODO: Emit left, do calculation in client
    BuildingBuilt.emit(token_id, building_id)

    return (TRUE)
end

# -----------------------------------
# INTERNAL
# -----------------------------------

# @notice Build buildings
# @param token_id: Staked Realm id (S_Realm)
# @param building_id: Building id
func build_buildings{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256, building_id : felt, quantity : felt, realms_data : RealmData):
    alloc_locals

    let (block_timestamp) = get_block_timestamp()

    # calculate time to add
    let (time_to_add) = Buildings.get_integrity_length(block_timestamp, building_id, quantity)

    # get unpacked buildings integrity
    let (current_buildings_integrity_unpacked) = get_buildings_integrity_unpacked(token_id)

    # set integrity for adjusted buildings
    let (updated_buildings_unpacked) = Buildings.add_time_to_buildings(
        current_buildings_integrity_unpacked, building_id, block_timestamp, time_to_add
    )

    # pack buildings
    let (updated_buildings_integrity) = Buildings.pack_buildings(updated_buildings_unpacked)

    # Save new packed buildings
    buildings_integrity.write(token_id, updated_buildings_integrity)

    let (updated_time_emit) = Buildings.get_unpacked_value(updated_buildings_unpacked, building_id)

    # Emit Building Integrity
    BuildingIntegrity.emit(token_id, building_id, updated_time_emit)

    return ()
end

# -----------------------------------
# Getters
# -----------------------------------

# @notice Get Workhut costs
# @param token_id: Staked Realm id (S_Realm)
@view
func get_workhut_costs{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(realms_data : RealmData, quantity : felt) -> (
    resource_ids_len : felt,
    resource_ids : Uint256*,
    resource_values_len : felt,
    resource_values : Uint256*,
):
    alloc_locals

    let (ids, values) = Resources.workhut_costs(realms_data, quantity)

    return (realms_data.resource_number, ids, realms_data.resource_number, values)
end

# @notice Gets integrity of buildings unpacked
# @param token_id: Staked Realm id (S_Realm)
# @return : unpacked buildings
@view
func get_buildings_integrity_unpacked{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (realm_buildings : RealmBuildings):
    alloc_locals

    let (buildings_) = buildings_integrity.read(token_id)

    let (unpacked) = Buildings.unpack_buildings(buildings_)

    return (unpacked)
end

# @notice Gets all effective buildings on a Realm. This is a computed value.
# @param token_id: Staked Realm id (S_Realm)
# @return : unpacked buildings
@view
func get_effective_buildings{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (realm_buildings : RealmBuildings):
    alloc_locals

    let (functional_buildings : RealmBuildings) = get_buildings_integrity_unpacked(token_id)

    let (block_timestamp) = get_block_timestamp()

    let (House) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.House, functional_buildings.House, block_timestamp
    )

    # storehouse is computed from food. TODO: deprecate struct
    let (food_address) = Module.get_module_address(ModuleIds.L10_Food)
    let (StoreHouse) = IFood.get_full_store_houses(food_address, token_id)

    let (Granary) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.Granary, functional_buildings.Granary, block_timestamp
    )
    let (Farm) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.Farm, functional_buildings.Farm, block_timestamp
    )
    let (FishingVillage) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.FishingVillage, functional_buildings.FishingVillage, block_timestamp
    )
    let (Barracks) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.Barracks, functional_buildings.Barracks, block_timestamp
    )
    let (MageTower) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.MageTower, functional_buildings.MageTower, block_timestamp
    )
    let (ArcherTower) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.ArcherTower, functional_buildings.ArcherTower, block_timestamp
    )
    let (Castle) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.Castle, functional_buildings.Castle, block_timestamp
    )

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

# @notice Gets all effective buildings on a Realm. This is a computed value. helper function otherwise infinite loop happens. TODO: could be better solution
# @param token_id: Staked Realm id (S_Realm)
# @return : unpacked buildings
@view
func get_effective_population_buildings{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (realm_buildings : RealmBuildings):
    alloc_locals

    let (functional_buildings : RealmBuildings) = get_buildings_integrity_unpacked(token_id)

    let (block_timestamp) = get_block_timestamp()

    let (House) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.House, functional_buildings.House, block_timestamp
    )

    let StoreHouse = 0

    let (Granary) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.Granary, functional_buildings.Granary, block_timestamp
    )
    let (Farm) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.Farm, functional_buildings.Farm, block_timestamp
    )
    let (FishingVillage) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.FishingVillage, functional_buildings.FishingVillage, block_timestamp
    )
    let (Barracks) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.Barracks, functional_buildings.Barracks, block_timestamp
    )
    let (MageTower) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.MageTower, functional_buildings.MageTower, block_timestamp
    )
    let (ArcherTower) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.ArcherTower, functional_buildings.ArcherTower, block_timestamp
    )
    let (Castle) = Buildings.calculate_effective_buildings(
        RealmBuildingsIds.Castle, functional_buildings.Castle, block_timestamp
    )

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

# @notice Gets storage on realm. TODO: Deprecate
# @param token_id: Staked Realm id (S_Realm)
# @return : buildings
@view
func get_storage_realm_buildings{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (buildings : felt):
    return realm_buildings.read(token_id)
end

# @notice Gets building cost according to Cost tuple
# @param building_id: Building ID
# @return : building cost in resources
# @return : lords cost
@view
func get_building_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    building_id : felt
) -> (cost : Cost, lords : Uint256):
    let (cost) = building_cost.read(building_id)
    let (lords) = building_lords_cost.read(building_id)
    return (cost, lords)
end

# -----------------------------------
# Admin
# -----------------------------------

# @notice Sets cost of the buildings
# @param building_id: Staked Realm id (S_Realm)
# @param : building cost in resources
# @param : lords cost
@external
func set_building_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    building_id : felt, cost : Cost, lords : Uint256
):
    # TODO: range checks on the cost struct
    Proxy.assert_only_admin()
    building_cost.write(building_id, cost)
    building_lords_cost.write(building_id, lords)
    return ()
end

# TODO: Deprecate or keep? It is a permanent record of how many buildings have been built
@view
func get_buildings_unpacked{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (realm_buildings : RealmBuildings):
    alloc_locals

    let (data) = get_storage_realm_buildings(token_id)

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
