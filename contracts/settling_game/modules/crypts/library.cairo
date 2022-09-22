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

// traverse array
namespace Crypts {
    func get_neigbours{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        idx: felt, graph_len: felt, row_len: felt
    ) -> (neigbours: felt) {
        alloc_locals;

        // TODO: inject correct neighbours accordingly

        return (neigbours=3);
    }

    // TODO: unpack the bitmapped crypts and pass in index + POI and rebuild graph
    func populate_edges{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        graph_len: felt, row_len: felt, edge: Edge*
    ) -> (graph_len: felt, row_len: felt, edge: Edge*) {
        alloc_locals;

        if (graph_len == 0) {
            return (graph_len, row_len, edge);
        }

        // TODO: Replace TOKEN_A with actual POI

        if (graph_len == 1) {
            tempvar dst = 0;  // final node has path back to start
        } else {
            tempvar dst = row_len - graph_len + 1;
        }

        local edge_a: Edge = Edge(row_len - graph_len, dst, 1);

        assert [edge] = edge_a;

        // TODO: since maps at a 2d array, we need to make adj_vertices_count represent this.
        // let (neigbours) = get_neigbours(graph_len, graph_len, row_len);
        // assert [adj_vertices_count] = 1;

        return populate_edges(graph_len - 1, row_len, edge + Edge.SIZE);
    }

    func build_graph_before_each{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        num_vertex: felt, row_len: felt
    ) -> (graph_len: felt, graph: Vertex*, neighbors: felt*) {
        alloc_locals;

        let (edges: Edge*) = alloc();

        populate_edges(num_vertex, row_len, edges);

        let (graph_len, graph, adj_vertices_count) = Graph.build_directed_graph_from_edges(
            num_vertex, edges
        );

        // adds edge to graph between two vertices
        local edge_a: Edge = Edge(1, 4, 1);

        let (graph_len, adj_vertices_count) = Graph.add_edge(
            graph, graph_len, adj_vertices_count, edge_a
        );

        return (graph_len, graph, adj_vertices_count);
    }
}
