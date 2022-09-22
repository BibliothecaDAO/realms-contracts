%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from contracts.settling_game.modules.crypts.library import Crypts
from starkware.cairo.common.alloc import alloc

from cairo_graphs.graph.dijkstra import Dijkstra
from cairo_graphs.graph.graph import Graph
from cairo_graphs.data_types.data_types import Edge, Vertex

from starkware.cairo.common.registers import get_fp_and_pc

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

    let (graph_len, graph, adj_vertices_count) = Crypts.build_graph_before_each(25, 25, 25232);

    %{ print(ids.graph_len) %}

    let (path_len, path, distance) = Dijkstra.shortest_path(
        graph_len, graph, adj_vertices_count, 1, 5
    );

    // let (graph_len, predecessors, distances) = Dijkstra.run(
    //     graph_len, graph, adj_vertices_count, 6
    // );

    // let d = predecessors[1];

    // %{ print(ids.d) %}

    let (entity) = Crypts.get_entity_index(25, 25, 25232);

    %{ print(ids.entity) %}

    return ();
}
