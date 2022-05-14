import pytest
import asyncio
import json
from openzeppelin.tests.utils import Signer, uint, str_to_felt, from_uint, felt_to_str
import time
from enum import IntEnum

FIRST_TOKEN_ID = uint(1)

@pytest.mark.asyncio
async def test_get_happiness(l04_Calculator):
    tx = await l04_Calculator.calculateHappiness(FIRST_TOKEN_ID).invoke()
    print(tx)