import pytest
import asyncio
import enum

from starkware.starknet.business_logic.state import BlockInfo
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.definitions.error_codes import StarknetErrorCode

LIGHT_TOKEN_ID = 1
DARK_TOKEN_ID = 2

SHIELD_ROLE = 0
ATTACK_ROLE = 1

# Boost units are in basis points, so every value needs to be multiplied
BOOST_UNIT_MULTIPLIER = 100

class GameStatus(enum.Enum):
    Active = 0
    Expired = 1


BLOCKS_PER_MINUTE = 4  # 15sec
HOURS_PER_GAME = 36


@pytest.fixture()
async def game_factory(ctx_factory):
    ctx = ctx_factory()

    # The Controller is the only unchangeable contract.
    # First deploy Arbiter.
    # Then send the Arbiter address during Controller deployment.
    # Then save the controller address in the Arbiter.
    # Then deploy Controller address during module deployments.
    arbiter = await ctx.starknet.deploy(
        source="contracts/desiege/Arbiter.cairo",
        constructor_calldata=[ctx.admin.contract_address])
    ctx.arbiter = arbiter

    controller = await ctx.starknet.deploy(
        source="contracts/desiege/ModuleController.cairo",
        constructor_calldata=[arbiter.contract_address])
    ctx.controller = controller
    await ctx.execute(
        "admin",
        arbiter.contract_address,
        "set_address_of_controller",
        [controller.contract_address]
    )

    elements_token = await ctx.starknet.deploy(
        "contracts/token/ERC1155/ERC1155_Mintable.cairo",
        constructor_calldata=[
            ctx.admin.contract_address,
            2,
            1, 2,
            2,
            1000, 5000
        ]
    )
    ctx.elements_token = elements_token

    elements_module = await ctx.starknet.deploy(
        source="contracts/desiege/04_Elements.cairo",
        constructor_calldata=[
            controller.contract_address,
            elements_token.contract_address,
            ctx.admin.contract_address,
        ]
    )
    ctx.elements_module = elements_module

    tower_defence = await ctx.starknet.deploy(
        source="contracts/desiege/01_TowerDefence.cairo",
        constructor_calldata=[
            controller.contract_address,
            elements_token.contract_address,
            4,  # blocks per minute
            36,  # hours per game,
            ctx.admin.contract_address
        ]
    )
    ctx.tower_defence = tower_defence

    tower_defence_storage = await ctx.starknet.deploy(
        source="contracts/desiege/02_TowerDefenceStorage.cairo",
        constructor_calldata=[controller.contract_address]
    )
    ctx.tower_defence_storage = tower_defence_storage
    await ctx.execute(
        "admin",
        arbiter.contract_address,
        'batch_set_controller_addresses',
        [
            tower_defence.contract_address, tower_defence_storage.contract_address
        ]
    )

    return ctx


@pytest.mark.asyncio
async def test_elements_minting(game_factory):

    elements_module = game_factory.elements_module
    elements_token = game_factory.elements_token

    execution_info = await elements_token.balance_of(game_factory.player1.contract_address, LIGHT_TOKEN_ID).call()
    old_bal = execution_info.result.res

    # Tests will start at game index 0
    next_game_idx = 1

    l1_address = 2342432432432423

    amount_to_mint = 1000

    await game_factory.execute(
        "admin",
        elements_module.contract_address,
        "mint_elements",
        [
            next_game_idx,
            l1_address,
            game_factory.player1.contract_address,
            LIGHT_TOKEN_ID,
            amount_to_mint
        ]
    )

    execution_info = await elements_token.balance_of(
        game_factory.player1.contract_address,
        LIGHT_TOKEN_ID
    ).call()
    assert execution_info.result.res == old_bal + amount_to_mint

    execution_info = await elements_module.get_total_minted(LIGHT_TOKEN_ID).call()
    assert execution_info.result.total == amount_to_mint
