import pytest

from tests.shared import str_to_felt, pack_values


@pytest.mark.asyncio
async def test_unpack_data(utils_general_tests):
    packed = pack_values([1, 4, 6])
    assert (await utils_general_tests.test_unpack_data(packed, 0, 0xFF).invoke()).result.score == 1
    assert (await utils_general_tests.test_unpack_data(packed, 8, 0xFF).invoke()).result.score == 4
    assert (await utils_general_tests.test_unpack_data(packed, 16, 0xFF).invoke()).result.score == 6


@pytest.mark.asyncio
async def test_sum_values_by_key(utils_general_tests):
    keys = list(map(str_to_felt, ["a", "c", "d", "c"]))
    values = [2, 2, 2, 2]

    tx = await utils_general_tests.test_sum_values_by_key(keys, values).invoke()

    d = tx.result.d  # list of DictAccess tuples
    assert len(d) == 3
    assert d[0].key == str_to_felt("a")
    assert d[0].new_value == 2
    assert d[1].key == str_to_felt("c")
    assert d[1].new_value == 4
    assert d[2].key == str_to_felt("d")
    assert d[2].new_value == 2
