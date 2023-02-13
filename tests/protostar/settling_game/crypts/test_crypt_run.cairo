%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_add
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem, signed_div_rem
from contracts.settling_game.modules.crypts.library import Crypts
from starkware.cairo.common.alloc import alloc

from cairo_graphs.graph.dijkstra import Dijkstra
from cairo_graphs.graph.graph import Graph
from cairo_graphs.data_types.data_types import Edge, Vertex, AdjacentVertex

from starkware.cairo.common.registers import get_fp_and_pc

@contract_interface
namespace ICryptRun {
    func open_crypt(crypt_id: Uint256, adventurer_id: Uint256) -> (seed: felt) {
    }
}

@external
func __setup__() {
    %{ context.contract_a_address = deploy_contract("./contracts/settling_game/modules/crypts/CryptRun.cairo").contract_address %}
    return ();
}

@external
func test_open_crypt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    tempvar contract_address;
    %{ ids.contract_address = context.contract_a_address %}

    %{ stop_mock = mock_call(context.contract_a_address, "open_crypt", [123456842657854254785]) %}

    let (res) = ICryptRun.open_crypt(contract_address, Uint256(1, 2), Uint256(1, 2));

    %{ stop_mock() %}

    assert res = 123456842657854254785;

    %{ print(ids.res) %}

    return ();
}
