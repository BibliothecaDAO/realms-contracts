%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

// Questions:
// Should have have type system at the component level. We can have a view function that fetches the type so clients know what the component accepts.
// How should we pack the values? Do we come up with generic bitmapping system?

const ID = 'example.component.Location';

struct Position {
    x: felt,
    y: felt,
}

@external
func set{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    entity: felt, value: felt
) {
    // set value
    // call world contract registerComponentValueSet -> emits information
    return ();
}

// auth
