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

const NUM_VERTEX = 9;
const ROW_LEN = 9;
const SEED = 252232312312323232;

@external
func test_build_graph_before_each{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    alloc_locals;

    let graph = Crypts.build_graph_before_each(NUM_VERTEX, ROW_LEN, SEED);

    let graph_len = graph.length;
    let vertices = graph.vertices;
    let adjacent_vertices_count = graph.adjacent_vertices_count;

    %{
        IDENTIFIER_INDEX = 1
        ADJACENT_VERTICES_INDEX = 2
        for i in range(ids.graph_len):
            neighbours_len = memory[ids.adjacent_vertices_count+i]
            vertex_id = memory[ids.vertices.address_+i*ids.Vertex.SIZE+IDENTIFIER_INDEX]
            adjacent_vertices_pointer = memory[ids.vertices.address_+i*ids.Vertex.SIZE+ADJACENT_VERTICES_INDEX]
            print(f"{vertex_id} -> {{",end='')
            for j in range (neighbours_len):
                adjacent_vertex = memory[adjacent_vertices_pointer+j*ids.AdjacentVertex.SIZE+IDENTIFIER_INDEX]
                print(f"{adjacent_vertex} ",end='')
            print('}',end='')
            print()
    %}

    // let (entity) = Crypts.get_entity_index(25, 25, 25232);

    // %{ print(ids.entity) %}

    return ();
}

const START_VERTEX_1 = 1;
const END_VERTEX_1 = 204;

@external
func test_check_path_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let graph = Crypts.build_graph_before_each(NUM_VERTEX, ROW_LEN, SEED);

    let (shortest_path_len, identifiers, total_distance) = Crypts.check_path_exists(
        graph, START_VERTEX_1, END_VERTEX_1
    );

    %{
        for i in range(ids.shortest_path_len):
            path = memory[ids.identifiers+i]
            print(f"{path}")
    %}
    return ();
}

@external
func test_check_entity_in_path{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let graph = Crypts.build_graph_before_each(NUM_VERTEX, ROW_LEN, SEED);

    let (shortest_path_len, identifiers, total_distance) = Crypts.check_path_exists(
        graph, START_VERTEX_1, END_VERTEX_1
    );

    let (entites_index: felt*) = alloc();

    assert entites_index[0] = 203;
    assert entites_index[1] = 3;

    let (can_pass) = Crypts.check_entity_in_path(shortest_path_len, identifiers, 2, entites_index);

    %{ print(ids.can_pass) %}

    return ();
}

@external
func test_get_entity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let graph = Crypts.build_graph_before_each(NUM_VERTEX, ROW_LEN, SEED);

    let (entity, len) = Crypts.get_entity_list(graph, SEED);

    %{
        for i in range(ids.len):
            path = memory[ids.entity+i]
            print(f"{path}")
    %}

    return ();
}
