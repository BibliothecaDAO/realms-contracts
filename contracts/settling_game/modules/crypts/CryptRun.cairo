// -----------------------------------
//   CryptRun.Library
//   CryptRun
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_timestamp,
    get_contract_address,
)

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import assert_not_zero

from contracts.settling_game.utils.constants import DAY
from contracts.settling_game.modules.crypts.library import Crypts
from contracts.settling_game.interfaces.imodules import IModuleController
from contracts.settling_game.library.library_module import Module

from openzeppelin.upgrades.library import Proxy
from cairo_graphs.data_types.data_types import Graph, Vertex

struct Crypt {
    time_stamp: felt,  // timestamp of when crypt was opened + 1 DAY
    seed: felt,  // random seed
    successful_completions: felt,  // number of times completed
}

struct AdventurerLocation {
    crypt: felt,  // crypt id
    location: felt,  // location within the crypt
    seed: felt,  // store seed, as during a run the crypts main seed my change
}

// FOR TESTING
namespace CryptData {
    const resource = 1;
    const environment = 2;
    const legendary = 0;
    const size = 9;
    const num_doors = 2;
    const num_points = 2;
    const affinity = 2;
}

const NUMBER_SUCCESSFUL_RUNS = 10;
const NODE_START_INDEX = 0;
const EXAMPLE_RANDOM = 23123123123120;

// -----------------------------------
// Storage
// -----------------------------------

@storage_var
func crypt(token_id: Uint256) -> (crypt: Crypt) {
}

@storage_var
func adventurer(token_id: Uint256) -> (location: AdventurerLocation) {
}

// -----------------------------------
// INITIALIZER & UPGRADE
// -----------------------------------

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address_of_controller: felt, proxy_admin: felt
) {
    Module.initializer(address_of_controller);
    Proxy.initializer(proxy_admin);
    return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}

// -----------------------------------
// EXTERNAL
// -----------------------------------

// @notice Opens crypt.... Checks if the Crypt is active. If < 24hrs or > 10 successful quests, function creates a new seed.
// @param crypt_id: Crypts erc721 ID
// @param adventurer_id: Adventurer erc721 ID
// @returns seed: Random seed. This is used in the Client to reconstruct the Crypt in a visual form.
@external
func open_crypt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    crypt_id: Uint256, adventurer_id: Uint256
) -> (seed: felt) {
    // check ownership
    assert_adventurer(adventurer_id);

    let (now) = get_block_timestamp();

    let (crypt_status) = crypt.read(crypt_id);
    let is_seed_active = is_le(now, crypt_status.time_stamp);

    if (is_seed_active == FALSE) {
        // get random
        tempvar randomSeed = 123456842657854254785;

        // write crypt set ts 1 day from now
        crypt.write(crypt_id, Crypt(now + DAY, randomSeed, NUMBER_SUCCESSFUL_RUNS));

        // write adventurer
        adventurer.write(
            adventurer_id, AdventurerLocation(crypt_id.low, NODE_START_INDEX, randomSeed)
        );

        return (seed=crypt_status.seed);
    }

    // we save the seed within the adventurer struct, this is incase the seed changes midrun the player can still complete
    adventurer.write(
        adventurer_id, AdventurerLocation(crypt_id.low, NODE_START_INDEX, crypt_status.seed)
    );

    return (seed=crypt_status.seed);
}

// @notice Move Adventurer within the Crypt.
// @param crypt_id: Crypts erc721 ID
// @param adventurer_id: Adventurer erc721 ID
// @param start_location: Index of the current location
// @param end_location: Index of the location wishing to travel to
@external
func move_to_location_in_crypt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    crypt_id: Uint256, adventurer_id: Uint256, start_location: felt, end_location: felt
) -> () {
    alloc_locals;
    // check ownership
    assert_adventurer(adventurer_id);

    // assert at location requested
    let (adventurer_location) = assert_and_return_location(crypt_id, adventurer_id, start_location);

    let (dungeon) = build_dungeon(crypt_id, adventurer_location.seed);

    // check path exists
    let (shortest_path_len, identifiers, total_distance) = Crypts.check_path_exists(
        dungeon, start_location, end_location
    );

    // check path exists
    with_attr error_message("Crypts: unmoveable location from your location") {
        assert_not_zero(shortest_path_len);
    }

    // move player and store state
    adventurer.write(
        adventurer_id, AdventurerLocation(crypt_id.low, end_location, adventurer_location.seed)
    );

    return ();
}

// @notice Can be called when the Adventurer exists on a Vertex
// @param crypt_id: Crypts erc721 ID
// @param adventurer_id: Adventurer erc721 ID
// @param location: Index of the vertex
@external
func interact_with_vertex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    crypt_id: Uint256, adventurer_id: Uint256, location: felt
) -> () {
    alloc_locals;
    // check ownership
    assert_adventurer(adventurer_id);

    // assert at location
    let (adventurer_location) = assert_and_return_location(crypt_id, adventurer_id, location);

    // build dungeon
    let (dungeon) = build_dungeon(crypt_id, adventurer_location.seed);

    // get entites
    let (entity_list_len, entity_list) = Crypts.get_entity_list(dungeon, adventurer_location.seed);

    // check entity exists
    let (entity_exists) = Crypts.check_entity_at_index(location, entity_list_len, entity_list);

    with_attr error_message("Crypts: There is no entity here") {
        assert entity_exists = TRUE;
    }

    // TODO: pass in new random number. Currently this will output the same entity everytime on specific indexes.
    let (entity) = Crypts.get_entity(adventurer_location.seed + location);

    // action with entity
    entity_action(entity, adventurer_id);

    return ();
}

// -----------------------------------
// INTERNAL
// -----------------------------------

// @notice Actions the entity at an index
// @param crypt_id: Crypts erc721 ID
// @param seed: Generated seed for the crypt
func entity_action{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    entity: felt, adventurer_id: Uint256
) -> () {
    // all possible entity interactions according to what the entity is
    // IF monster -> take health (perhaps calls back to Adventurer module). If dead, kill.
    // IF loot -> store loot in state, when Adventurer leaves the dungeon mint loot.
    return ();
}

// @notice Builds the graph of the Dungeon from the crypt and a Seed
// @param crypt_id: Crypts erc721 ID
// @param seed: Generated seed for the crypt
func build_dungeon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    crypt_id: Uint256, seed: felt
) -> (dungeon: Graph) {
    // build graph from seed
    // TODO: fetch crypt metadata and pass into function. HARDCODED FOR NOW.
    let graph = Crypts.build_dungeon(CryptData.size, CryptData.size, seed);
    return (dungeon=graph);
}

// @notice Asserts Adventurer is at the location requested and then returns the location if they are.
// @param crypt_id: Crypts erc721 ID
// @param adventurer_id: Adventurer erc721 ID
// @param location: Location of Adventurer within the crypt
func assert_and_return_location{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    crypt_id: Uint256, adventurer_id: Uint256, location: felt
) -> (adventurer_location: AdventurerLocation) {
    let (adventurer_location) = get_location(adventurer_id);

    with_attr error_message("Crypts: You are not in this Crypt") {
        assert adventurer_location.crypt = crypt_id.low;
    }

    with_attr error_message("Crypts: You are not at this location within the Crypt") {
        assert location = adventurer_location.location;
    }

    return (adventurer_location=adventurer_location);
}

// @notice Asserts caller owns Adventurer
// @param adventurer_id: Adventurer erc721 ID
func assert_adventurer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_id: Uint256
) -> () {
    // TODO:
    // assert caller == owner

    return ();
}

// -----------------------------------
// GETTERS
// -----------------------------------

// @notice Get the location of an Adventurer within this module
// @param adventurer_id: Adventurer erc721 ID
@view
func get_location{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_id: Uint256
) -> (location: AdventurerLocation) {
    return adventurer.read(adventurer_id);
}
