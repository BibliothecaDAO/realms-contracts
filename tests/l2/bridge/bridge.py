from starkware.starknet.business_logic.state.state import BlockInfo
from starkware.starknet.testing.starknet import Starknet, StarknetContract
from starkware.starknet.services.api.contract_definition import ContractDefinition
from starkware.starknet.compiler.compile import compile_starknet_files
import pytest
import asyncio
import json
from openzeppelin.tests.utils import Signer, uint, str_to_felt, from_uint, felt_to_str
import time
from scripts.binary_converter import map_realm
from tests.conftest import set_block_timestamp

NUM_SIGNING_ACCOUNTS = 2
signer = Signer(123456789987654321)

L1_LOCKBOX_ADDRESS = 0x9Ee907a26DaD632Ee9A6F7006c53a81541bd2376
L1_ADDRESS = 0xA035bF657bd2fBdE2eC374bEc968B85715512f29

# @pytest.mark.asyncio
# async def test_deposit():
#   starknet = await Starknet.empty()

#   owner_account = await starknet.deploy(
#       source="openzeppelin/account/Account.cairo",
#       constructor_calldata=[signer.public_key]
#   )

#   first_account = await starknet.deploy(
#       source="openzeppelin/account/Account.cairo",
#       constructor_calldata=[signer.public_key]
#   )

#   # Deploy the contract.
#   erc721 = await starknet.deploy(
#     source="contracts/l2/bridge/test_contracts/Test_Realms_ERC721.cairo",
#     constructor_calldata=[
#       0,
#       0,
#       owner_account.contract_address
#     ]
#   )

#   # Deploy the contract.
#   bridge = await starknet.deploy(
#     source="contracts/l2/bridge/Bridge.cairo",
#     constructor_calldata=[
#       owner_account.contract_address,
#       erc721.contract_address
#     ]
#   )

#   # Set l1 contract    
#   await signer.send_transaction(
#     account=owner_account,
#     to=bridge.contract_address,
#     selector_name="set_l1_lockbox_contract_address",
#     calldata=[
#       L1_LOCKBOX_ADDRESS
#     ]
#   )

#   # # Set Bridge to ERC721 for security
#   await signer.send_transaction(
#     account=owner_account,
#     to=erc721.contract_address,
#     selector_name="set_l2_bridge_contract_address",
#     calldata=[
#       bridge.contract_address
#     ]
#   )

#   await signer.send_transaction(
#     account=owner_account,
#     to=erc721.contract_address,
#     selector_name="mint",
#     calldata=[
#       bridge.contract_address,
#       1, 0
#     ]
#   )

#   await signer.send_transaction(
#     account=owner_account,
#     to=erc721.contract_address,
#     selector_name="mint",
#     calldata=[
#       bridge.contract_address,
#       2, 0
#     ]
#   )

#   # from_address: felt, # Starknet special field - filled for L1 caller contract
#   # l1_owner_address: felt,
#   # to: felt, 
#   # token_ids_len: felt, 
#   # token_ids: felt*
#   await signer.send_transaction(
#     account=owner_account,
#     to=bridge.contract_address,
#     selector_name="depositFromL1",
#     calldata=[
#       L1_LOCKBOX_ADDRESS,
#       first_account.contract_address,
#       4,
#       1, 0,
#       2, 0  # low, high
#     ]
#   )

#   res1 = await signer.send_transaction(
#     account=owner_account,
#     to=erc721.contract_address,
#     selector_name="ownerOf",
#     calldata=[
#       1, 0
#     ]
#   )

#   res2 = await signer.send_transaction(
#     account=owner_account,
#     to=erc721.contract_address,
#     selector_name="ownerOf",
#     calldata=[
#       2, 0
#     ]
#   )

#   print(res1)
#   print(res2)

#   assert res1.result.response[0] == first_account.contract_address
#   assert res2.result.response[0] == first_account.contract_address

@pytest.mark.asyncio
async def test_withdraw():
  starknet = await Starknet.empty()

  owner_account = await starknet.deploy(
      source="openzeppelin/account/Account.cairo",
      constructor_calldata=[signer.public_key]
  )

  first_account = await starknet.deploy(
      source="openzeppelin/account/Account.cairo",
      constructor_calldata=[signer.public_key]
  )

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
      L1_LOCKBOX_ADDRESS
    ]
  )

  # # Set Bridge to ERC721 for security
  await signer.send_transaction(
    account=owner_account,
    to=erc721.contract_address,
    selector_name="set_l2_bridge_contract_address",
    calldata=[
      bridge.contract_address
    ]
  )

  await signer.send_transaction(
    account=owner_account,
    to=erc721.contract_address,
    selector_name="mint",
    calldata=[
      first_account.contract_address,
      1, 0
    ]
  )

  await signer.send_transaction(
    account=owner_account,
    to=erc721.contract_address,
    selector_name="mint",
    calldata=[
      first_account.contract_address,
      2, 0
    ]
  )

  await signer.send_transaction(
    account=first_account,
    to=erc721.contract_address,
    selector_name="setApprovalForAll",
    calldata=[
      bridge.contract_address,
      1
    ]
  )

  a = await signer.send_transaction(
    account=first_account,
    to=erc721.contract_address,
    selector_name="ownerOf",
    calldata=[
      2, 0,  # low, high
      #2, 0
    ]
  )

  print(a)

  # from_address: felt, # Starknet special field - filled for L1 caller contract
  # l1_owner_address: felt,
  # to: felt, 
  # token_ids_len: felt, 
  # token_ids: felt*
  res = await signer.send_transaction(
    account=first_account,
    to=bridge.contract_address,
    selector_name="withdrawToL1",
    calldata=[
      L1_ADDRESS,
      2,
      1, 0,  # low, high
      2, 0
    ]
  )

  assert res.l2_to_l1_messages[0].payload == [L1_ADDRESS, 1, 0, 2, 0]