%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from contracts.settling_game.modules.crypts.library import Crypts
from starkware.cairo.common.alloc import alloc

// @external
// func test_calculate_traverse{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     alloc_locals;
//     let (a_array: felt*) = alloc();

// assert a_array[0] = 0;
//     assert a_array[1] = 0;

// let (x_len, x) = Crypts.traverse(2, a_array, 2);

// let first = x[0];

// %{ print('len:', ids.first) %}

// return ();
// }

@external
func test_build_graph_before_each{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    alloc_locals;

    let (graph, graph_len, adj_vertices_count, neighbors_len) = Crypts.build_graph_before_each(
        625, 25
    );

    assert graph[0].identifier = 123;
    assert graph[1].identifier = 123;
    assert graph[2].identifier = 123;

    return ();
}
