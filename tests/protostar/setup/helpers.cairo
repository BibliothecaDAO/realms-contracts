%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.registers import get_label_location

func get_resources{syscall_ptr: felt*, range_check_ptr}() -> (
    resources: Uint256*
) {
    let (RESOURCES_ARR) = get_label_location(resource_start);
    return (resources=cast(RESOURCES_ARR, Uint256*));

    resource_start:
    dw 1;
    dw 0;
    dw 2;
    dw 0;
    dw 3;
    dw 0;
    dw 4;
    dw 0;
    dw 5;
    dw 0;
    dw 6;
    dw 0;
    dw 7;
    dw 0;
    dw 8;
    dw 0;
    dw 9;
    dw 0;
    dw 10;
    dw 0;
    dw 11;
    dw 0;
    dw 12;
    dw 0;
    dw 13;
    dw 0;
    dw 14;
    dw 0;
    dw 15;
    dw 0;
    dw 16;
    dw 0;
    dw 17;
    dw 0;
    dw 18;
    dw 0;
    dw 19;
    dw 0;
    dw 20;
    dw 0;
    dw 21;
    dw 0;
    dw 22;
    dw 0;
}

func get_owners{syscall_ptr: felt*, range_check_ptr}(owner: felt) -> (
    owners_len: felt, owners: felt*
) {
    let (owners: felt*) = alloc();
    assert [owners] = owner;
    assert [owners + 1] = owner;
    assert [owners + 2] = owner;
    assert [owners + 3] = owner;
    assert [owners + 4] = owner;
    assert [owners + 5] = owner;
    assert [owners + 6] = owner;
    assert [owners + 7] = owner;
    assert [owners + 8] = owner;
    assert [owners + 9] = owner;
    assert [owners + 10] = owner;
    assert [owners + 11] = owner;
    assert [owners + 12] = owner;
    assert [owners + 13] = owner;
    assert [owners + 14] = owner;
    assert [owners + 15] = owner;
    assert [owners + 16] = owner;
    assert [owners + 17] = owner;
    assert [owners + 18] = owner;
    assert [owners + 19] = owner;
    assert [owners + 20] = owner;
    assert [owners + 21] = owner;
    return (owners_len=22, owners=owners);
}