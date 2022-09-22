%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from contracts.settling_game.modules.crypts.library import Crypts
from starkware.cairo.common.alloc import alloc

from cairo_graphs.graph.dijkstra import Dijkstra
from cairo_graphs.graph.graph import Graph
from cairo_graphs.data_types.data_types import Edge, Vertex, AdjacentVertex

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

    let (graph_len, graph, adj_vertices_count) = Crypts.build_graph_before_each(
        10, 10, 252232312312323232
    );

    // %{ print(ids.graph_len) %}

    // let (path_len, path, distance) = Dijkstra.shortest_path(
    //     graph_len, graph, adj_vertices_count, 1, 5
    // );

    %{
        IDENTIFIER_INDEX = 1
        ADJACENT_VERTICES_INDEX = 2
        for i in range(ids.graph_len):
            neighbours_len = memory[ids.adj_vertices_count+i]
            vertex_id = memory[ids.graph.address_+i*ids.Vertex.SIZE+IDENTIFIER_INDEX]
            adjacent_vertices_pointer = memory[ids.graph.address_+i*ids.Vertex.SIZE+ADJACENT_VERTICES_INDEX]
            print(f"{vertex_id} -> {{",end='')
            for j in range (neighbours_len):
                adjacent_vertex = memory[adjacent_vertices_pointer+j*ids.AdjacentVertex.SIZE+IDENTIFIER_INDEX]
                print(f"{adjacent_vertex} ",end='')
            print('}',end='')
            print()
    %}

    let (entity) = Crypts.get_entity_index(25, 25, 25232);

    %{ print(ids.entity) %}

    return ();
}
