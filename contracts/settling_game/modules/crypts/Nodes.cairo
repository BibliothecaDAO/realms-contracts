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
from starkware.cairo.common.bool import TRUE

from contracts.settling_game.modules.crypts.library import Crypts
from cairo_graphs.data_types.data_types import Graph, Vertex

struct Crypt {
    time_stamp: felt,
    seed: felt,
    successful_completions: felt,
}

struct AdventurerLocation {
    dungeon: felt,  // crypt id
    location: felt,  // location within the crypt
    seed: felt,  // store seed, as during a run the crypts main seed my change
}

// seed storage
@storage_var
func crypt(token_id: Uint256) -> (crypt: Crypt) {
}

@storage_var
func adventurer(token_id: Uint256) -> (location: AdventurerLocation) {
}

//

// opens a crypt.
// if SEED exists OR timestamp is less than 24hrs, use SEED, otherwise create new seed
// only the opener of the crypt does this.
@external
func open_crypt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    crypt_id: Uint256, adventurer_id: Uint256
) -> (seed: felt) {
    let (crypt_status) = crypt.read(crypt_id);
    return (seed=crypt_status.seed);
}
