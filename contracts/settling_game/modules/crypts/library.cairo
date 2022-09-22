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
    // TODO: unpack the bitmapped crypts and pass in index + POI and rebuild graph
    func populate_edges{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        graph_len: felt, row_len: felt, edge: Edge*, seed: felt
    ) -> (graph_len: felt, row_len: felt, edge: Edge*) {
        alloc_locals;

        if (graph_len == 0) {
            return (graph_len, row_len, edge);
        }

        // randomise node connections
        let (_, r) = unsigned_div_rem(seed + graph_len, graph_len);

        if (graph_len == 1) {
            tempvar dst = 0;  // final node has path back to start
        } else {
            if (r == (row_len - graph_len)) {
                tempvar dst = r + 1;
            } else {
                tempvar dst = r;
            }
        }

        local edge_a: Edge = Edge(row_len - graph_len, dst, 1);

        assert [edge] = edge_a;

        return populate_edges(graph_len - 1, row_len, edge + Edge.SIZE, seed);
    }

    // TODO: injext this with a seed + crypts metadata
    // outputs a dungeon which can be used in other parts.
    func build_graph_before_each{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        num_vertex: felt, row_len: felt, seed: felt
    ) -> (graph_len: felt, graph: Vertex*, neighbors: felt*) {
        alloc_locals;

        // add in some random edges ontop of fixed amount
        let (_, r) = unsigned_div_rem(seed + num_vertex, 100);

        let (edges: Edge*) = alloc();
        populate_edges(num_vertex + r, row_len + r, edges, seed);

        let (graph_len, graph, adj_vertices_count) = Graph.build_directed_graph_from_edges(
            num_vertex, edges
        );

        return (graph_len, graph, adj_vertices_count);
    }

    // @notice: calculates what will be at the index of the graph. Moster, Loot, nothing.
    func get_entity_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        num_vertex: felt, row_len: felt, seed: felt
    ) -> (entity: felt) {
        alloc_locals;

        // add in some random edges ontop of fixed amount
        let (_, r) = unsigned_div_rem(seed + num_vertex, 100);

        let (_, entity) = unsigned_div_rem(row_len + r, 5);

        return (entity=entity);
    }

    // TOOD: PATHING: stop travellers from jumping nodes. Eg: Check if a path exists.
    //
}
