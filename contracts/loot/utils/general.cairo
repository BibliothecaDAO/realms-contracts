from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_lt_felt
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE

func _uint_to_felt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    value: Uint256
) -> (value: felt) {
    assert_lt_felt(value.high, 2 ** 123);
    return (value.high * (2 ** 128) + value.low,);
}

namespace Rarity {
    const common = 700;
    const uncommmon = 200;
    const rare = 90;
    const legendary = 10;
}

namespace RarityId {
    const common = 1;
    const uncommmon = 2;
    const rare = 3;
    const legendary = 4;
}

func rare_number_generator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    number: felt
) -> (rarity: felt) {
    let (_, r) = unsigned_div_rem(number, 1000);

    let legendary = is_le(r, Rarity.legendary);
    if (legendary == TRUE) {
        return (RarityId.legendary,);
    }

    let rare = is_le(r, Rarity.rare);
    if (rare == TRUE) {
        return (RarityId.rare,);
    }

    let uncommmon = is_le(r, Rarity.uncommmon);
    if (uncommmon == TRUE) {
        return (RarityId.uncommmon,);
    }
    return (RarityId.common,);
}
