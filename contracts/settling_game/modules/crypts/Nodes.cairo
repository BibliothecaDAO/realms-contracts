// ____MODULE_L07___CRYPTS_LOGIC
//   Staking/Unstaking a crypt.
//
// MIT License

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
from cairo_graphs.data_types.data_types import Graph, Vertex

struct Crypt {
    time_stamp: felt,
    seed: felt,
    successful_completions: felt,
}

struct AdventurerLocation {
    crypt: felt,  // crypt id
    location: felt,  // location within the crypt
    seed: felt,  // store seed, as during a run the crypts main seed my change
}

const NUMBER_SUCCESSFUL_RUNS = 10;
const NODE_START_INDEX = 0;
const EXAMPLE_RANDOM = 23123123123120;

namespace CryptData {
    const resource = 1;
    const environment = 2;
    const legendary = 0;
    const size = 9;
    const num_doors = 2;
    const num_points = 2;
    const affinity = 2;
}

// seed storage
@storage_var
func crypt(token_id: Uint256) -> (crypt: Crypt) {
}

@storage_var
func adventurer(token_id: Uint256) -> (location: AdventurerLocation) {
}

// opens a crypt.
// if SEED exists OR timestamp is less than 24hrs, use SEED, otherwise create new seed
// only the opener of the crypt does this.
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

@external
func move_to_location_in_crypt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    crypt_id: Uint256, adventurer_id: Uint256, start_location: felt, end_location: felt
) -> () {
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
    let (adventurer_location) = assert_and_return_location(crypt_id, adventurer_id, start_location);
    adventurer.write(
        adventurer_id, AdventurerLocation(crypt_id.low, end_location, adventurer_location.seed)
    );

    return ();
}

@external
func interact_with_node{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    crypt_id: Uint256, adventurer_id: Uint256, location: felt
) -> () {
    // check ownership
    assert_adventurer(adventurer_id);

    // assert at location
    let (adventurer_location) = assert_and_return_location(crypt_id, adventurer_id, location);

    // TODO: pass in new random number. Currently this will output the same entity everytime on specific indexes.
    let (entity) = Crypts.get_entity(adventurer_location.seed + location);

    entity_action(entity, adventurer_id);

    return ();
}

// actions on the entity
func entity_action{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    entity: felt, adventurer_id: Uint256
) -> () {
    // all possible entity interactions according to what the entity is
    return ();
}

// builds dungeon
func build_dungeon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    crypt_id: Uint256, seed: felt
) -> (dungeon: Graph) {
    // build graph from seed
    // TODO: fetch crypt metadata and pass into function. HARDCODED FOR NOW.
    let graph = Crypts.build_dungeon(CryptData.size, CryptData.size, seed);
    return (dungeon=graph);
}

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

func assert_adventurer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_id: Uint256
) -> () {
    // TODO:
    // assert caller == owner

    return ();
}

@view
func get_location{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    adventurer_id: Uint256
) -> (location: AdventurerLocation) {
    return adventurer.read(adventurer_id);
}
