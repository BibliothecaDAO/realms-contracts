# -----------------------------------
# ____Module.Food
#   Logic around Food system

# ELI5:
#   Players can build (n) number of farms or fishing villages according to number
#   of rivers or harbours on the Realm. Once built, players can harvest these farms
#   at a set interval for $WHEAT or $FISH. The player has the option at harvest
#   time to either claim or store directly into the store_house. Once the food
#   is in the store_house it is depleted according to the population on the
#   Realm. If the player chooses to export the food, the tokens are minted
#   to the players wallet.

# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import assert_not_zero
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.utils.constants import (
    BASE_HARVESTS,
    BASE_FOOD_PRODUCTION,
    STORE_HOUSE_SIZE,
)
from contracts.settling_game.utils.general import transform_costs_to_tokens
from contracts.settling_game.utils.game_structs import (
    RealmData,
    ModuleIds,
    ExternalContractIds,
    ResourceIds,
    Cost,
    HarvestType,
    RealmBuildingsIds,
    FoodBuildings,
)
from contracts.settling_game.modules.food.library import Food
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from openzeppelin.upgrades.library import Proxy
from contracts.settling_game.interfaces.realms_IERC721 import realms_IERC721
from contracts.settling_game.interfaces.imodules import IL04_Calculator, IL03_Buildings

# -----------------------------------
# Events
# -----------------------------------

@event
func Created(token_id : Uint256, building_id : felt, qty : felt, harvests : felt, timestamp : felt):
end

@event
func Harvest(token_id : Uint256, building_id : felt, harvests : felt, timestamp : felt):
end

# -----------------------------------
# Storage
# -----------------------------------

# -------FARMS-------#
@storage_var
func farms(token_id : Uint256) -> (farms : felt):
end

# -------FISHING-------#
@storage_var
func fishing_villages(token_id : Uint256) -> (fishing_villages : felt):
end

# -------STORE HOUSE-------#
@storage_var
func store_house(token_id : Uint256) -> (available_food : felt):
end

# -----------------------------------
# INITIALIZER & UPGRADE
# -----------------------------------

# @notice Module initializer
# @param address_of_controller: Controller/arbiter address
# @proxy_admin: Proxy admin address
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
# EXTERNAL
# -----------------------------------

# @notice Creates either farms or fishing villages
# @param token_id: Staked Realm id (S_Realm)
# @param qty: qty to build on realm
# @param food_building_id: food building id
@external
func create{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256, qty : felt, food_building_id : felt):
    alloc_locals

    # check id
    Food.assert_ids(food_building_id)

    # checks
    Module.ERC721_owner_check(token_id, ExternalContractIds.S_Realms)

    # contracts
    let (realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms)
    let (s_realms_address) = Module.get_external_contract_address(ExternalContractIds.Realms)
    let (realm_data) = realms_IERC721.fetch_realm_data(realms_address, token_id)

    let (owner) = get_caller_address()

    # checks
    if food_building_id == RealmBuildingsIds.Farm:
        let (enough_rivers) = is_le(qty, realm_data.rivers + 1)
        with_attr error_message("FOOD: Not enough Rivers"):
            assert enough_rivers = TRUE
        end
    else:
        let (enough_harbours) = is_le(qty, realm_data.harbours + 1)
        with_attr error_message("FOOD: Not enough Harbours"):
            assert enough_harbours = TRUE
        end
    end

    # set plant time
    let (block_timestamp) = get_block_timestamp()

    let (packed) = Food.pack_food_buildings(
        food_buildings_unpacked=FoodBuildings(qty, BASE_HARVESTS, block_timestamp)
    )

    # build required building
    if food_building_id == RealmBuildingsIds.Farm:
        farms.write(token_id, packed)
    else:
        fishing_villages.write(token_id, packed)
    end

    # Costs
    let (buildings_address) = Module.get_module_address(ModuleIds.L03_Buildings)
    let (cost, _) = IL03_Buildings.get_building_cost(buildings_address, food_building_id)
    let (costs : Cost*) = alloc()
    assert [costs] = cost
    let (token_len, token_ids, token_values) = transform_costs_to_tokens(1, costs, qty)

    # BURN RESOURCES
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources)
    IERC1155.burnBatch(resources_address, owner, token_len, token_ids, token_len, token_values)

    Created.emit(token_id, food_building_id, qty, BASE_HARVESTS, block_timestamp)

    return ()
end

# @notice Harvests either farms or fishing villages
# @param token_id: Staked Realm id (S_Realm)
# @param harvest_type: this is either export or store. Export mints tokens, store keeps on the realm as food
# @param food_building_id: food building id
@external
func harvest{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256, harvest_type : felt, food_building_id : felt):
    alloc_locals

    # check id and harvest type
    Food.assert_ids(food_building_id)
    Food.assert_harvest_type(harvest_type)

    # check owner
    Module.ERC721_owner_check(token_id, ExternalContractIds.S_Realms)

    # contracts
    let (s_realms_address) = Module.get_external_contract_address(ExternalContractIds.S_Realms)
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources)
    let (owner) = realms_IERC721.ownerOf(s_realms_address, token_id)

    # get packed building info from storage
    if food_building_id == RealmBuildingsIds.Farm:
        let (packed) = farms.read(token_id)
        tempvar packed = packed
    else:
        let (packed) = fishing_villages.read(token_id)
        tempvar packed = packed
    end

    # unpack and calculate
    let (unpacked_food_buildings : FoodBuildings) = Food.unpack_food_buildings(packed)

    let (block_timestamp) = get_block_timestamp()

    let (total_harvest, total_remaining, decayed_farms) = Food.calculate_harvest(
        block_timestamp - unpacked_food_buildings.update_time
    )

    # update storage
    update(
        unpacked_food_buildings.collections_left,
        unpacked_food_buildings.number_built,
        total_harvest,
        decayed_farms,
        token_id,
        food_building_id,
    )

    # total food to harvest - either sent to export or sent to store
    let total_food = total_harvest * BASE_FOOD_PRODUCTION

    # set default data in mint call
    let (local data : felt*) = alloc()
    assert data[0] = 0

    # mint food
    if harvest_type == HarvestType.Export:
        if food_building_id == RealmBuildingsIds.Farm:
            # wheat
            IERC1155.mint(
                resources_address,
                owner,
                Uint256(ResourceIds.wheat, 0),
                Uint256(total_food * 10 ** 18, 0),
                1,
                data,
            )
        else:
            # fish
            IERC1155.mint(
                resources_address,
                owner,
                Uint256(ResourceIds.fish, 0),
                Uint256(total_food * 10 ** 18, 0),
                1,
                data,
            )
        end
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        # turn directly into useable food
        convert_to_store(token_id, total_food)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    return ()
end

# @notice Converts harvest directly into food store on a Realm
# @param token_id: Staked Realm id (S_Realm)
# @param quantity: quantity of food to store
# @param resource_id: id of food to be stored (FISH or WHEAT)
@external
func convert_food_tokens_to_store{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(token_id : Uint256, quantity : felt, resource_id : felt):
    alloc_locals
    let (caller) = get_caller_address()

    # check id and harvest type
    Food.assert_food_type(resource_id)

    # check owner
    Module.ERC721_owner_check(token_id, ExternalContractIds.S_Realms)

    # contracts
    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources)

    # set default data in burn call
    let (local data : felt*) = alloc()
    assert data[0] = 0

    # burn resources
    IERC1155.burn(
        resources_address, caller, Uint256(resource_id, 0), Uint256(quantity * 10 ** 18, 0)
    )

    convert_to_store(token_id, quantity)
    return ()
end

# -----------------------------------
# INTERNAL
# -----------------------------------

# @notice Updates values after harvest
# @param current_harvests: current harvests on Realm
# @param number_built: farms built - this is just unpacked data from above
# @param total_harvest: total qty harvested
# @param decayed_farms: decayed farms
# @param token_id: Staked Realm id (S_Realm)
# @param food_building_id: food building id
func update{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(
    current_harvests : felt,
    number_built : felt,
    total_harvest : felt,
    decayed_farms : felt,
    token_id : Uint256,
    food_building_id : felt,
):
    alloc_locals
    let (block_timestamp) = get_block_timestamp()

    # check harvests left

    with_attr error_message("FOOD: No Harvests available"):
        assert_not_zero(current_harvests)
    end

    # calculated harvests to save
    let harvests_to_save = current_harvests - total_harvest - decayed_farms

    # # if 0 harvests left: Some can decay if you do not harvest.
    let (is_zero_harvests) = is_le(harvests_to_save, 0)

    if is_zero_harvests == TRUE:
        tempvar harvests_to_save = 0
    else:
        tempvar harvests_to_save = harvests_to_save
    end

    let (packed) = Food.pack_food_buildings(
        food_buildings_unpacked=FoodBuildings(number_built, harvests_to_save, block_timestamp)
    )

    # save packed
    if food_building_id == RealmBuildingsIds.Farm:
        farms.write(token_id, packed)
    else:
        fishing_villages.write(token_id, packed)
    end

    Harvest.emit(token_id, food_building_id, harvests_to_save, block_timestamp)

    return ()
end

# @notice Converts harvest directly into food store
# @param token_id: Staked Realm id (S_Realm)
# @param quantity: quantity of food to store
func convert_to_store{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, quantity : felt
):
    alloc_locals
    let (block_timestamp) = get_block_timestamp()

    let (current) = food_in_store(token_id)

    store_house.write(token_id, current + quantity + block_timestamp)

    return ()
end

# @notice Available food in store
# @param token_id: Staked Realm id (S_Realm)
# @return total_harvest: Total food in storehouse
@view
func food_in_store{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (available : felt):
    alloc_locals
    let (block_timestamp) = get_block_timestamp()

    let (current_food_supply) = store_house.read(token_id)

    let (available) = Food.calculate_food_in_store_house(current_food_supply - block_timestamp)

    return (available)
end

# -----------------------------------
# GETTERS
# -----------------------------------

# @notice Available food in store
# @param token_id: Staked Realm id (S_Realm)
# @return total_harvest: Total food in storehouse
@view
func available_food_in_store{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (available : felt):
    alloc_locals

    let (calculator_address) = Module.get_module_address(ModuleIds.L04_Calculator)

    # get raw amount
    let (current) = food_in_store(token_id)

    # get population
    let (population) = IL04_Calculator.calculate_population(calculator_address, token_id)

    # get actual food
    # TODO: Get Population
    let (available) = Food.calculate_available_food(current, population)

    return (available)
end

# @notice harvests left
# @param token_id: Staked Realm id (S_Realm)
# @return farm_harvests_left: Harvests left
@view
func get_farm_harvests_left{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (farm_harvests_left : felt):
    alloc_locals
    let (packed) = farms.read(token_id)
    # unpack
    let (unpacked_food_buildings : FoodBuildings) = Food.unpack_food_buildings(packed)

    return (unpacked_food_buildings.collections_left)
end

# @notice gets base fishing villages data
# @param token_id: Staked Realm id (S_Realm)
# @return total_harvest: Total harvestable
# @return total_remaining: Total remaining
# @return decayed_farms: Decayed
@view
func get_farms_to_harvest{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (total_harvest, total_remaining, decayed_farms, farms_built):
    alloc_locals

    # farm expirary time
    let (block_timestamp) = get_block_timestamp()

    let (packed) = farms.read(token_id)

    # unpack
    let (unpacked_food_buildings : FoodBuildings) = Food.unpack_food_buildings(packed)

    let (total_harvest, total_remaining, decayed_farms) = Food.calculate_harvest(
        block_timestamp - unpacked_food_buildings.update_time
    )
    return (total_harvest, total_remaining, decayed_farms, unpacked_food_buildings.number_built)
end

# @notice harvests left
# @param token_id: Staked Realm id (S_Realm)
# @return farm_harvests_left: Harvests left
@view
func get_fishing_villages_harvests_left{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (farm_harvests_left : felt):
    alloc_locals
    let (packed) = fishing_villages.read(token_id)
    # unpack
    let (unpacked_food_buildings : FoodBuildings) = Food.unpack_food_buildings(packed)

    return (unpacked_food_buildings.collections_left)
end

# @notice gets base fishing villages data
# @param token_id: Staked Realm id (S_Realm)
# @return total_harvest: Total harvestable
# @return total_remaining: Total remaining
# @return decayed_farms: Decayed
@view
func get_fishing_villages_to_harvest{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (total_harvest, total_remaining, decayed_farms, villages_built):
    alloc_locals
    # farm expirary time
    let (block_timestamp) = get_block_timestamp()

    let (packed) = fishing_villages.read(token_id)
    # unpack
    let (unpacked_food_buildings : FoodBuildings) = Food.unpack_food_buildings(packed)

    let (total_harvest, total_remaining, decayed_farms) = Food.calculate_harvest(
        block_timestamp - unpacked_food_buildings.update_time
    )
    return (total_harvest, total_remaining, decayed_farms, unpacked_food_buildings.number_built)
end

@view
func get_all_food_information{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (
    total_farm_harvest,
    total_farm_remaining,
    decayed_farms,
    farms_built,
    farm_harvests_left,
    total_village_harvest,
    total_village_remaining,
    decayed_villages,
    villages_built,
    fishing_villages_harvests_left,
):
    alloc_locals
    # farm expirary time
    let (farm_harvests_left) = get_farm_harvests_left(token_id)
    let (
        total_farm_harvest, total_farm_remaining, decayed_farms, farms_built
    ) = get_farms_to_harvest(token_id)

    let (fishing_villages_harvests_left) = get_fishing_villages_harvests_left(token_id)
    let (
        total_village_harvest, total_village_remaining, decayed_villages, villages_built
    ) = get_fishing_villages_to_harvest(token_id)

    return (
        total_farm_harvest,
        total_farm_remaining,
        decayed_farms,
        farms_built,
        farm_harvests_left,
        total_village_harvest,
        total_village_remaining,
        decayed_villages,
        villages_built,
        fishing_villages_harvests_left,
    )
end

# @notice Computes value of store houses. Store houses take up variable space on the Realm according to STORE_HOUSE_SIZE
# @param token_id: Staked Realm id (S_Realm)
# @return full_store_houses: A full decimal value of storehouses
@view
func get_full_store_houses{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(token_id : Uint256) -> (full_store_houses : felt):
    alloc_locals

    let (food_in_store) = available_food_in_store(token_id)

    let (total_store_house) = Food.get_full_store_houses(food_in_store)

    return (total_store_house)
end

# -----------------------------------
# HOOKS
# -----------------------------------

# @notice updates food value to match computed.
# this stops food ever returning to a greater value than what it was
# @param token_id: Staked Realm id (S_Realm)
@external
func update_food_hook{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
):
    alloc_locals
    Module.only_approved()

    let (block_timestamp) = get_block_timestamp()

    let (current_food_supply) = available_food_in_store(token_id)

    let (is_empty) = is_le(current_food_supply, 0)

    if is_empty == TRUE:
        store_house.write(token_id, 0)
    else:
        store_house.write(token_id, current_food_supply + block_timestamp)
    end

    return ()
end

# -----------------------------------
# ADMIN
# -----------------------------------
# @external
# func reset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token_id : Uint256):
#     alloc_locals

# fishing_villages.write(token_id, 0)
#     farms.write(token_id, 0)
#     store_house.write(token_id, 0)

# return ()
# end
