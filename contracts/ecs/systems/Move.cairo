%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

// import component
from contracts.ecs.IComponent import IComponent as ILocation

// single function that executes the move system
@external
func execute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    entity: felt, value: felt
) {
    // decode to get id and data
    // get component address

    // add logic specific to system. Auth etc..

    // ILocation.set(addr, id, data)
    return ();
}

// auth
