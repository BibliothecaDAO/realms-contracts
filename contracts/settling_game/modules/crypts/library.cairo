// -----------------------------------
//   Crypts.Library
//   Crypts
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc

from cairo_graphs.graph.graph import (
    add_neighbor,
    GraphMethods,
    build_directed_graph_from_edges_internal,
    build_undirected_graph_from_edges_internal,
)

from cairo_graphs.graph.dijkstra import Dijkstra
from cairo_graphs.data_types.data_types import Edge, Vertex, AdjacentVertex, Graph

namespace Crypts {
    // -----------------------------------
    // GRAPH
    // -----------------------------------

    // TODO: inject this with a seed + crypts metadata
    // @notice Builds dungeon seed and length
    func build_dungeon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        num_vertex: felt, row_len: felt, seed: felt
    ) -> Graph {
        alloc_locals;

        // straight line
        let (edges: Edge*) = alloc();
        populate_edges(num_vertex, row_len, edges, seed);
        let graph = GraphMethods.build_directed_graph_from_edges(num_vertex, edges);

        // get potential branch nodes as array
        let (start_indexes_len, start_indexes) = get_potential_branches(graph, seed);

        // recurse through the potential branches and build graph
        let graph = build_edge_branches(graph, num_vertex, seed, start_indexes_len, start_indexes);

        return (graph);
    }

    // @notice builds list of potential node branches
    func get_potential_branches{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        graph: Graph, seed: felt
    ) -> (branches_len: felt, branches: felt*) {
        alloc_locals;

        // get number of branches in the dungeon. -1 to stop the final node from having branches.
        let (_, r) = unsigned_div_rem(seed, graph.length - 1);

        let (branches: felt*) = alloc();
        build_entity_list(r, r, branches, graph.vertices, seed, graph.length);

        return (branches_len=r, branches=branches);
    }

    func build_edge_branches{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        graph: Graph, num_vertex: felt, seed: felt, start_indexes_len: felt, start_indexes: felt*
    ) -> Graph {
        alloc_locals;

        if (start_indexes_len == 0) {
            return (graph);
        }

        let graph = add_edges(graph, num_vertex, [start_indexes], seed);

        // we change the seed by 100 to make the length of the branches edges random
        return build_edge_branches(
            graph, num_vertex, seed + 100, start_indexes_len - 1, start_indexes + 1
        );
    }

    func add_edges{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        graph: Graph, num_vertex: felt, start_index: felt, seed: felt
    ) -> Graph {
        alloc_locals;
        let (_, random_number_edges) = unsigned_div_rem(seed, 4);

        let index_shift = 100;  // hardcode for now - we shift to avoid index clashes

        // add branch off straight line
        let (side_edges: Edge*) = alloc();
        populate_side_edges(
            random_number_edges,
            random_number_edges,
            start_index,
            start_index * index_shift,
            side_edges,
            seed,
        );
        let graph = build_directed_graph_from_edges_internal(
            random_number_edges, side_edges, graph
        );

        // connect graph back to node back to vertex in the straight line
        let (_, connecting_node) = unsigned_div_rem(seed, num_vertex);
        local start_edge: Edge = Edge(start_index, start_index * index_shift, 1);
        local final_edge: Edge = Edge(start_index * index_shift + random_number_edges, connecting_node, 1);
        let graph = GraphMethods.add_edge(graph, start_edge);
        let graph = GraphMethods.add_edge(graph, final_edge);

        return (graph);
    }
    // @notice recursivley builds a straight graph to the length of the crypt
    func populate_edges{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        graph_len: felt, row_len: felt, edge: Edge*, seed: felt
    ) -> (graph_len: felt, row_len: felt, edge: Edge*) {
        alloc_locals;

        if (graph_len == 0) {
            return (graph_len, row_len, edge);
        }

        // randomise node connections
        let (_, r) = unsigned_div_rem(seed + graph_len, graph_len);

        // if (graph_len == 1) {
        //     tempvar dst = 0;  // final node has path back to start
        // } else {
        // if (r == (row_len - graph_len)) {
        tempvar dst = (row_len - graph_len) + 1;
        // } else {
        //     tempvar dst = r;
        // }
        // }

        local edge_a: Edge = Edge(row_len - graph_len, dst, 1);

        assert [edge] = edge_a;

        return populate_edges(graph_len - 1, row_len, edge + Edge.SIZE, seed);
    }

    // @notice recursivley builds a list of edges
    func populate_side_edges{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        graph_len: felt,
        row_len: felt,
        start_index: felt,
        branch_identifier: felt,
        edge: Edge*,
        seed: felt,
    ) -> (graph_len: felt, row_len: felt, edge: Edge*) {
        alloc_locals;

        if (graph_len == 0) {
            tempvar dst = start_index;
        } else {
            tempvar dst = branch_identifier;
        }

        local edge_a: Edge = Edge(dst, branch_identifier + 1, 1);

        assert [edge] = edge_a;

        if (graph_len == 0) {
            return (graph_len, row_len, edge);
        }

        return populate_side_edges(
            graph_len - 1, row_len, start_index + 1, branch_identifier + 1, edge + Edge.SIZE, seed
        );
    }

    // -----------------------------------
    // ENTITY
    // -----------------------------------

    // @notice Gets a single entity
    func get_entity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        random_number: felt
    ) -> (entity: felt) {
        alloc_locals;

        let (_, entity) = unsigned_div_rem(random_number, 5);

        return (entity=entity);
    }

    // OPTIMISATION IDEA: This could be stored in the state as a bitmapped felt. This way the user when interacting with it does not need to recreate the graph everytime. This might be a cheaper option...
    // @notice Gets the entity list at indexes.
    func get_entity_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        graph: Graph, seed: felt
    ) -> (entity_len: felt, entities: felt*) {
        alloc_locals;

        // get number of entities in the dungeon
        let (_, r) = unsigned_div_rem(seed, graph.length);

        // build array of entites
        let (entities: felt*) = alloc();
        build_entity_list(r, r, entities, graph.vertices, seed, graph.length);

        return (entity_len=r, entities=entities);
    }

    // @notice Recursively builds a list of entities from a seed
    func build_entity_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        entity_quantity: felt,
        fixed_entity_quantity: felt,
        entities: felt*,
        vertices: Vertex*,
        seed: felt,
        length: felt,
    ) -> (entities: felt*) {
        alloc_locals;

        if (entity_quantity == 0) {
            return (entities=entities);
        }

        // TODO: Bug when the same index is used. We need to pop copies so the array returned only contains unique indexes.
        let (_, num) = unsigned_div_rem(seed, length);

        // let (exists) = check_no_repeated_indexes(
        //     fixed_entity_quantity - entity_quantity, entities, vertices[num].identifier
        // );

        // if (exists == FALSE) {
        assert [entities] = vertices[num].identifier;
        // }

        return build_entity_list(
            entity_quantity - 1, fixed_entity_quantity, entities + 1, vertices, seed - 3, length
        );
    }

    // @notice Checks index not already in array
    func check_no_repeated_indexes{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        entities_len: felt, entities: felt*, current_entity: felt
    ) -> (exists: felt) {
        alloc_locals;

        if (entities_len == 0) {
            return (exists=FALSE);
        }

        if ([entities] == current_entity) {
            return (exists=TRUE);
        }

        return check_no_repeated_indexes(entities_len - 1, entities + 1, current_entity);
    }

    // @notice Checks path exists between two vertexs
    func check_path_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        graph: Graph, start_vertex: felt, end_vertex: felt
    ) -> (shortest_path_len: felt, identifiers: felt*, total_distance: felt) {
        alloc_locals;

        let (shortest_path_len, identifiers, total_distance) = Dijkstra.shortest_path(
            graph, start_vertex, end_vertex
        );

        return (shortest_path_len, identifiers, total_distance);
    }

    // @notice Checks entity exists in the path
    func check_entity_in_path{range_check_ptr}(
        identifiers_len: felt, identifiers: felt*, entity_ids_len: felt, entity_ids: felt*
    ) -> (can_pass: felt) {
        alloc_locals;

        if (identifiers_len == 0) {
            return (can_pass=TRUE);
        }

        let (i) = check_entity_nested([identifiers], entity_ids_len, entity_ids);

        if (i == FALSE) {
            return (can_pass=FALSE);
        }

        return check_entity_in_path(
            identifiers_len - 1, identifiers + 1, entity_ids_len, entity_ids
        );
    }

    // @notice Inner recursive method for checking entity path
    func check_entity_nested{range_check_ptr}(
        identifier: felt, entity_ids_len: felt, entity_ids: felt*
    ) -> (can_pass: felt) {
        alloc_locals;

        if (entity_ids_len == 0) {
            return (can_pass=TRUE);
        }

        if (identifier == [entity_ids]) {
            return (can_pass=FALSE);
        }

        return check_entity_nested(identifier, entity_ids_len - 1, entity_ids + 1);
    }

    // @notice Assert entity exists
    func check_entity_at_index{range_check_ptr}(
        identifier: felt, entity_ids_len: felt, entity_ids: felt*
    ) -> (entity_exists: felt) {
        alloc_locals;

        if (entity_ids_len == 0) {
            return (entity_exists=FALSE);
        }

        if (identifier == [entity_ids]) {
            return (entity_exists=TRUE);
        }

        return check_entity_at_index(identifier, entity_ids_len - 1, entity_ids + 1);
    }
}
