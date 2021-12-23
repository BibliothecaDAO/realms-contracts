import pytest
import asyncio
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.definitions.error_codes import StarknetErrorCode

from utils.GridPosition import pack_position, unpack_position

@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope='module')
async def movement_factory():
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the movement contract.
    movement = await starknet.deploy(
        "contracts/l2/minigame/03_GridMovement.cairo"
    )

    # This contract wraps the util contract
    # just for testing
    grid_position = await starknet.deploy(
        "contracts/l2/game_utils/grid_position_test.cairo"
    )

    return movement, grid_position

@pytest.mark.asyncio
async def test_position_packing(movement_factory):
    _, grid_coord = movement_factory

    grid_size = 4
    execution_info = await grid_coord.test_pack_position(grid_size,1,3).call()
    assert execution_info.result == (7,)

@pytest.mark.asyncio
async def test_position_unpacking(movement_factory):
    _, grid_coord = movement_factory

    grid_size = 4
    execution_info = await grid_coord.test_unpack_position(grid_size,7).call()
    (row,col) = execution_info.result

    assert row == 1
    assert col == 3

@pytest.mark.asyncio
async def test_movement(movement_factory):
    movement,_ = movement_factory

    grid_size = 4
    player = pack_position(grid_size, 1, 3)

    # Outside of grid
    target = pack_position(grid_size, 1, grid_size + 1)
    try:
        await movement.assert_move(grid_size, player, target).call()
        assert False
    except StarkException as err:
        _, error = err.args
        assert error['code'] == StarknetErrorCode.TRANSACTION_FAILED

    # Two steps away
    target = pack_position(grid_size, 1, 1)
    try:
        await movement.assert_move(grid_size, player, target).call()
        assert False
    except StarkException as err:
        _, error = err.args
        assert error['code'] == StarknetErrorCode.TRANSACTION_FAILED

    # Many steps away
    target = pack_position(grid_size, 0, 0)
    try:
        await movement.assert_move(grid_size, player, target).call()
        assert False
    except StarkException as err:
        _, error = err.args
        assert error['code'] == StarknetErrorCode.TRANSACTION_FAILED

    # One step away (legal movement)
    target = pack_position(grid_size, 1, 2)
    execution_info = await movement.assert_move(grid_size, player, target).call()
    assert execution_info.result == (1,)