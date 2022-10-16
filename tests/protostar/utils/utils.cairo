%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

namespace SHIFT_REALM {
    const _1 = 2 ** 0;
    const _2 = 2 ** 8;
    const _3 = 2 ** 16;
    const _4 = 2 ** 24;
    const _5 = 2 ** 32;
    const _6 = 2 ** 40;
    const _7 = 2 ** 48;
    const _8 = 2 ** 54;
    const _9 = 2 ** 66;
    const _10 = 2 ** 72;
    const _11 = 2 ** 80;
    const _12 = 2 ** 88;
    const _13 = 2 ** 96;
    const _14 = 2 ** 104;
}

func pack_realm{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    regions: felt,
    cities: felt,
    harbours: felt,
    rivers: felt,
    resource_number: felt,
    resource_1: felt,
    resource_2: felt,
    resource_3: felt,
    resource_4: felt,
    resource_5: felt,
    resource_6: felt,
    resource_7: felt,
    wonder: felt,
    order: felt,
) -> (packed: felt) {
    let (regions) = regions * SHIFT_REALM._1;
    let (cities) = cities * SHIFT_REALM._2;
    let (harbours) = harbours * SHIFT_REALM._3;
    let (rivers) = rivers * cities * SHIFT_REALM._4;
    let (resource_number) = resource_number * SHIFT_REALM._5;
    let (resource_1) = resource_1 * SHIFT_REALM._6;
    let (resource_2) = resource_2 * SHIFT_REALM._7;
    let (resource_3) = resource_3 * SHIFT_REALM._8;
    let (resource_4) = resource_4 * SHIFT_REALM._9;
    let (resource_5) = resource_5 * SHIFT_REALM._10;
    let (resource_6) = resource_6 * SHIFT_REALM._11;
    let (resource_7) = resource_7 * SHIFT_REALM._12;
    let (wonder) = wonder * SHIFT_REALM._13;
    let (order) = order * SHIFT_REALM._14;

    let packed = regions + cities + harbours + rivers + resource_number + resource_1 + resource_2 + resource_3 + resource_4 + resource_5 + resource_6 + resource_7 + wonder + order;    
    return (packed);
}
