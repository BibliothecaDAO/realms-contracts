// -----------------------------------
//   Crypts.Library
//   Crypts Graph library. This library creates procedually generated dungeons from a seed and other parameters.
//
// MIT License
// -----------------------------------

// <author :: ponderingdemocritus@protonmail.com>

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc
from starkware.cairo.common.registers import get_label_location

from cairo_graphs.graph.graph import (
    add_neighbor,
    GraphMethods,
    build_directed_graph_from_edges_internal,
    build_undirected_graph_from_edges_internal,
)

from cairo_graphs.graph.dijkstra import Dijkstra
from cairo_graphs.data_types.data_types import Edge, Vertex, AdjacentVertex, Graph
from cairo_graphs.utils.array_utils import Stack

from contracts.settling_game.modules.crypts.constants import Entity

// TODO: Build n number of branches

// Maximum length of branch
const MAX_EDGE_LENGTH = 8;

// Monster, Loot, Resource, Item, Chest
const NUMBER_OF_POTENTIAL_ENTITIES = 5;

namespace Crypts {
    // -----------------------------------
    // GRAPH - (THE DUNGEON SHAPE)
    // These functions build the shape of the dungeon.
    // -----------------------------------

    // @notice Builds dungeon from seed and len
    // @param num_vertex: Number of vertexs
    // @param seed: Random seed to build the dungeon
    // @return: Graph: The dungeon
    func build_dungeon{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        num_vertex: felt, seed: felt
    ) -> Graph {
        alloc_locals;

        // build straight line - Start at index 0
        let (edges: Edge*) = alloc();
        build_straight_line_of_edges(num_vertex, 0, edges);
        let graph = GraphMethods.build_directed_graph_from_edges(num_vertex, edges);

        // get potential branch nodes as array
        let (start_indexes_len, start_indexes) = get_potential_branches(graph, seed);

        // recurse through the potential branches and build graph
        let graph = build_and_add_vertices(
            graph, num_vertex, seed, start_indexes_len, start_indexes
        );

        return (graph);
    }

    // @notice Builds list of indexes which will become the start indexes of the branches
    func get_potential_branches{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        graph: Graph, seed: felt
    ) -> (branches_len: felt, branches: felt*) {
        alloc_locals;

        // pop final vertice which is the exit
        let (updated_vertices: Vertex*) = alloc();
        pop_vertex_array(graph.length, graph.vertices, updated_vertices);

        // get random number of side edges in the dungeon.
        let (_, number_of_branches) = unsigned_div_rem(seed, graph.length);

        // build_branches
        let (branches: felt*) = alloc();
        build_random_index_list_from_vertices(
            number_of_branches, branches, updated_vertices, seed, graph.length
        );

        return (branches_len=number_of_branches, branches=branches);
    }

    // @notice Removes final item in an array of Vertices
    func pop_vertex_array{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        vertex_len: felt, existing_vertices: Vertex*, new_vertices: Vertex*
    ) -> (vertex_len: felt, new_vertices: Vertex*) {
        alloc_locals;
        if (vertex_len == 1) {
            return (vertex_len, new_vertices);
        }

        assert [new_vertices] = [existing_vertices];

        return pop_vertex_array(
            vertex_len - 1, existing_vertices + Vertex.SIZE, new_vertices + Vertex.SIZE
        );
    }

    // @notice Builds branches
    func build_and_add_vertices{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        graph: Graph, num_vertex: felt, seed: felt, start_indexes_len: felt, start_indexes: felt*
    ) -> Graph {
        alloc_locals;

        if (start_indexes_len == 0) {
            return (graph);
        }

        let graph = add_edges(graph, num_vertex, [start_indexes], seed);

        // we change the seed by 100 to make the length of the branches edges random
        return build_and_add_vertices(
            graph, num_vertex, seed + 123456789, start_indexes_len - 1, start_indexes + 1
        );
    }

    // @notice Add branches to a graph
    func add_edges{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        graph: Graph, num_vertex: felt, start_index: felt, seed: felt
    ) -> Graph {
        alloc_locals;
        // TODO: edge lengths are the same
        let (_, random_number_edges) = unsigned_div_rem(seed, MAX_EDGE_LENGTH);

        let index_shift = 100;  // hardcode for now - we shift to avoid index clashes

        // add branch off straight line
        let (side_edges: Edge*) = alloc();
        build_straight_line_of_edges(random_number_edges, start_index * index_shift, side_edges);
        let graph = build_directed_graph_from_edges_internal(
            random_number_edges, side_edges, graph
        );

        // connect graph back to node back to vertex in the straight line
        // shift seed so we get a different connecting node
        let (_, connecting_node) = unsigned_div_rem(seed, num_vertex);
        local start_edge: Edge = Edge(start_index, start_index * index_shift, 1);
        local final_edge: Edge = Edge(
            start_index * index_shift + random_number_edges, connecting_node, 1
        );
        let graph = GraphMethods.add_edge(graph, start_edge);
        let graph = GraphMethods.add_edge(graph, final_edge);

        return (graph);
    }

    // @notice Builds a list of edges in a sequential line
    func build_straight_line_of_edges{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(graph_len: felt, index_start: felt, edge: Edge*) -> (graph_len: felt, edge: Edge*) {
        alloc_locals;

        local new_edge: Edge = Edge(index_start, index_start + 1, 1);

        assert [edge] = new_edge;

        if (graph_len == 0) {
            return (graph_len, edge);
        }

        return build_straight_line_of_edges(graph_len - 1, index_start + 1, edge + Edge.SIZE);
    }

    // -----------------------------------
    // ENTITY
    // -----------------------------------
    // Entities are objects within the dungeon. They could be anything!
    // A player cannot move through them and must interact in order to pass.

    // @notice Gets random entity from a random number
    func get_entity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        random_number: felt
    ) -> (entity: felt) {
        alloc_locals;

        let (_, entity) = unsigned_div_rem(random_number, NUMBER_OF_POTENTIAL_ENTITIES);

        return (entity=entity);
    }

    // TODO: OPTIMISATION IDEA: This could be stored in the state as a bitmapped felt. This way the user when interacting with it does not need to recreate the graph everytime. This might be a cheaper option...
    // @notice Gets the entity list at indexes.
    func get_entity_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        graph: Graph, seed: felt
    ) -> (entity_len: felt, entities: felt*) {
        alloc_locals;

        // get number of entities in the dungeon
        let (_, random_number_of_entities) = unsigned_div_rem(seed, graph.length);

        // build array of entites
        let (entities: felt*) = alloc();
        build_random_index_list_from_vertices(
            random_number_of_entities, entities, graph.vertices, seed, graph.length
        );

        return (entity_len=random_number_of_entities, entities=entities);
    }

    // @notice Recursively builds a list of indexes from array of Vertices
    func build_random_index_list_from_vertices{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(quantity: felt, index_list: felt*, vertices: Vertex*, seed: felt, length: felt) -> (
        entities: felt*
    ) {
        alloc_locals;

        if (quantity == 0) {
            return (entities=index_list);
        }

        // Get random index
        // TODO: Bug when the same index is used. We need to pop copies so the array returned only contains unique indexes.
        let (_, vertex_index) = unsigned_div_rem(seed, length);

        assert [index_list] = vertices[vertex_index].identifier;

        return build_random_index_list_from_vertices(
            quantity - 1, index_list + 1, vertices, seed + 123456789, length
        );
    }

    // @notice Checks path exists between two vertices
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

    func lookup_entity{syscall_ptr: felt*, range_check_ptr}(entity_id: felt) -> (entity: felt) {
        alloc_locals;

        let (label_location) = get_label_location(labels);
        return ([label_location + entity_id - 1],);

        labels:
        dw Entity.Generic;
        dw Entity.Adventurer;
        dw Entity.Item.Generic;
        dw Entity.Item.Key;
        dw Entity.Item.Potion;
        dw Entity.Item.Weapon;
        dw Entity.Item.Armor;
        dw Entity.Item.Jewlery;
        dw Entity.Item.Artifact;
        dw Entity.Enemy.Generic;
        dw Entity.Enemy.Orc;
        dw Entity.Enemy.GiantSpider;
        dw Entity.Enemy.Troll;
        dw Entity.Enemy.Zombie;
        dw Entity.Enemy.GiantRat;
        dw Entity.Enemy.Minotaur;
        dw Entity.Enemy.Werewolf;
        dw Entity.Enemy.Beserker;
        dw Entity.Enemy.Goblin;
        dw Entity.Enemy.Gnome;
        dw Entity.Enemy.Ghoul;
        dw Entity.Enemy.Wraith;
        dw Entity.Enemy.Skeleton;
        dw Entity.Enemy.Revenant;
        dw Entity.Enemy.GoldenDragon;
        dw Entity.Enemy.BlackDragon;
        dw Entity.Enemy.BronzeDragon;
        dw Entity.Enemy.RedDragon;
        dw Entity.Enemy.Wyvern;
        dw Entity.Enemy.FireGiant;
        dw Entity.Enemy.StormGiant;
        dw Entity.Enemy.IceGiant;
        dw Entity.Enemy.FrostGiant;
        dw Entity.Enemy.HillGiant;
        dw Entity.Enemy.Ogre;
        dw Entity.Enemy.SkeletonLord;
        dw Entity.Enemy.KnightsOfChaos;
        dw Entity.Enemy.LizardKing;
        dw Entity.Enemy.Medusa;
        dw Entity.Obstacle.Generic;
        dw Entity.Obstacle.TrapDoor;
        dw Entity.Obstacle.PoisonDart;
        dw Entity.Obstacle.FlameJet;
        dw Entity.Obstacle.PoisonWell;
        dw Entity.Obstacle.FallingNet;
        dw Entity.Obstacle.BlindingLight;
        dw Entity.Obstacle.LightningBolt;
        dw Entity.Obstacle.PendulumBlades;
        dw Entity.Obstacle.SnakePit;
        dw Entity.Obstacle.PoisonousGas;
        dw Entity.Obstacle.LavaPit;
        dw Entity.Obstacle.BurningOil;
        dw Entity.Obstacle.FireBreathingGargoyle;
        dw Entity.Obstacle.HiddenArrow;
        dw Entity.Obstacle.SpikedPit;
    }
}
