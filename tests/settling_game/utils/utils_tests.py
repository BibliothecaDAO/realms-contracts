import struct
import pytest


# TODO: same function is define in 06_combat_test, use it in one place
def pack_values(values: list[int]) -> int:
    return int.from_bytes(struct.pack(f"<{len(values)}b", *values), "little")


@pytest.mark.asyncio
async def test_unpack_data(utils_general_tests):
    packed = pack_values([1, 4, 6])
    assert (await utils_general_tests.test_unpack_data(packed, 0, 0xFF).invoke()).result.score == 1
    assert (await utils_general_tests.test_unpack_data(packed, 8, 0xFF).invoke()).result.score == 4
    assert (await utils_general_tests.test_unpack_data(packed, 16, 0xFF).invoke()).result.score == 6
