import pytest
import asyncio
import enum
import logging
import os

from utils import Signer

from starkware.starknet.testing.starknet import Starknet

# from starknet_py.utils.data_transformer.data_transformer import DataTransformer

from starkware.starknet.business_logic.state import BlockInfo
from starkware.starkware_utils.error_handling import StarkException

LOGGER = logging.getLogger(__name__)

signer = Signer(123456789987654321) 

# @pytest.mark.asyncio
# async def test_increase_balance():
#     # Create a new Starknet class that simulates the StarkNet
#     # system.
#     starknet = await Starknet.empty()

#     # Deploy the contract.
#     contract = await starknet.deploy(
#       source="contracts/l2/modules/lore/lore.cairo",
#       constructor_calldata=[
#         0
#       ]
#     )

#     scrolls_count = await contract.get_scrolls_count().call()

#     print(scrolls_count)

#     assert scrolls_count == 1

@pytest.mark.asyncio
async def test_create_scroll():
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    owner_account = await starknet.deploy(
        source="contracts/Account.cairo",
        constructor_calldata=[signer.public_key]
    )

    first_account = await starknet.deploy(
        source="contracts/Account.cairo",
        constructor_calldata=[signer.public_key]
    )

    l1_lockbox_contract_address = 1111

    # Deploy the contract.
    erc721 = await starknet.deploy(
      source="contracts/l2/bridge/test_contracts/Test_Realms_ERC721.cairo",
      constructor_calldata=[
        0,
        0,
        owner_account.contract_address
      ]
    )

    # Deploy the contract.
    bridge = await starknet.deploy(
      source="contracts/l2/bridge/Bridge.cairo",
      constructor_calldata=[
        owner_account.contract_address,
        erc721.contract_address
      ]
    )

    # Set l1 contract    
    await signer.send_transaction(
      account=owner_account,
      to=bridge.contract_address,
      selector_name="set_l1_lockbox_contract_address",
      calldata=[
        l1_lockbox_contract_address
      ]
    )

    # Set Bridge to ERC721 for security
    await signer.send_transaction(
      account=owner_account,
      to=erc721.contract_address,
      selector_name="set_l2_bridge_contract_address",
      calldata=[
        bridge.contract_address
      ]
    )

    # from_address: felt, # Starknet special field - filled for L1 caller contract
    # l1_owner_address: felt,
    # to: felt, 
    # token_ids_len: felt, 
    # token_ids: felt*
    res = await signer.send_transaction(
      account=owner_account,
      to=bridge.contract_address,
      selector_name="depositFromL1",
      calldata=[
        l1_lockbox_contract_address,
        first_account.contract_address,
        2, #
        1, 1  # low, high
      ]
    )

    newNFT = await erc721.ownerOf((1, 1)).call()

    assert newNFT.result.owner == first_account.contract_address