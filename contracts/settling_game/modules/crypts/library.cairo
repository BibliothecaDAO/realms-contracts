// -----------------------------------
// ____Food Library
//   Food
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc

from cairo_graphs.graph.graph import add_neighbor, Graph
from cairo_graphs.data_types.data_types import Edge, Vertex, AdjacentVertex

namespace Points {
    const nothing = 0;
    const wall = 1;
    const enemy = 2;
    const loot = 3;
}

const TOKEN_A = 123;
const TOKEN_B = 456;
const TOKEN_C = 990;
const TOKEN_D = 982;

// traverse array
namespace Crypts {
    func traverse{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        x_len: felt, x: felt*, y: felt
    ) -> (a_len: felt, a: felt*) {
        alloc_locals;

        let (a_array: felt*) = alloc();
        traverse_x(x_len, a_array);

        return (x_len, a_array);
    }

    func get_neigbours{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        idx: felt, length: felt, rows: felt
    ) -> (neigbours: felt) {
        alloc_locals;

        // TODO: inject correct neighbours accordingly

        return (neigbours=3);
    }

    // TODO: unpack the bitmapped crypts and pass in index + POI and rebuild graph
    func traverse_x{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        x_len: felt, x: Vertex*, adj_vertices_count: felt*
    ) -> (x_len: felt, x: Vertex*, adj_vertices_count: felt*) {
        alloc_locals;

        if (x_len == 0) {
            return (x_len, x, adj_vertices_count);
        }

        let (vertex_a_neighbors: AdjacentVertex*) = alloc();

        local vertex_a: Vertex = Vertex(x_len - 0, TOKEN_A, vertex_a_neighbors);

        assert [x] = vertex_a;

        // TODO: since maps at a 2d array, we need to make adj_vertices_count represent this.

        let (neigbours) = get_neigbours(x_len, x_len);
        assert [adj_vertices_count] = neigbours;

        return traverse_x(x_len - 1, x + Vertex.SIZE, adj_vertices_count + 1);
    }

    func build_graph_before_each{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        num_vertex: felt
    ) -> (graph: Vertex*, graph_len: felt, neighbors: felt*, neighbors_len: felt) {
        alloc_locals;

        let (graph_len, graph, adj_vertices_count) = Graph.new_graph();

        // populate graph
        traverse_x(num_vertex, graph, adj_vertices_count);

        let neighbors_len = num_vertex;

        let graph_len = num_vertex;

        return (graph, graph_len, adj_vertices_count, neighbors_len);
    }
}
