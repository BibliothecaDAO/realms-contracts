%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

@external
func registerComponent{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    componentAddr: felt, id: felt
) {
    return ();
}

@external
func registerSystem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    systemAddr: felt, id: felt
) {
    return ();
}

@external
func registerComponentValueSet{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    entity: felt, component: felt
) {
    // emit event of changed data
    // set component value

    return ();
}

// emitted on every value change
@event
func ComponentValueSet(component_id: felt, component_addr: felt, entity_id: felt, data: felt) {
}
