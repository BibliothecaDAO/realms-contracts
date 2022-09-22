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

@external
func create_nodes{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (graph_len, graph, adj_vertices_count, neighbors_len) = Crypts.build_graph_before_each(
        4, 4
    );
    return ();
}
