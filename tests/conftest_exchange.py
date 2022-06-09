from starkware.starknet.business_logic.state.state import BlockInfo
from starkware.starknet.testing.starknet import Starknet, StarknetContract
from starkware.starknet.services.api.contract_definition import ContractDefinition
from starkware.starknet.compiler.compile import compile_starknet_files
import logging
from types import SimpleNamespace
import asyncio
import pytest
import dill
import os
from openzeppelin.tests.utils import Signer, uint, str_to_felt
import sys
import time

from conftest import set_block_timestamp

sys.stdout = sys.stderr

# Create signers that use a private key to sign transaction objects.
DUMMY_PRIVATE = 123456789987654321

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "../..", "contracts")
INITIAL_LORDS_SUPPLY = 500000000 * (10 ** 18)

initial_user_funds = 1000 * (10 ** 18)

initial_supply = 1000000 * (10 ** 18)

###########################
# EXCHANGE
###########################

@pytest.fixture(scope="session")
def compiled_proxy():
    return compile("contracts/settling_game/proxy/PROXY_Logic.cairo")

async def deploy_contract(starknet, contract, calldata):
    print(contract)
    return await starknet.deploy(
        source=contract,
        constructor_calldata=calldata,
    )

async def proxy_builder(compiled_proxy, starknet, signer, account, contract, calldata):

    implementation = await deploy_contract(starknet, contract, [])

    proxy = await starknet.deploy(
        contract_def=compiled_proxy,
        constructor_calldata=[implementation.contract_address],
    )
    
    set_proxy = proxy.replace_abi(implementation.abi)
    
    await signer.send_transaction(
        account=account,
        to=set_proxy.contract_address,
        selector_name='initializer',
        calldata=calldata,
    )

    return set_proxy

@pytest.fixture(scope='session')
async def token_factory(account_factory, compiled_proxy):
    (starknet, accounts, signers) = account_factory
    admin_key = signers[0]
    admin_account = accounts[0]
    treasury_account = accounts[1]

    set_block_timestamp(starknet.state, round(time.time()))

    proxy_lords = await proxy_builder(compiled_proxy, starknet, admin_key, admin_account, "contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo", [
        str_to_felt("Lords"),
        str_to_felt("LRD"),
        18,
        *uint(initial_supply),
        treasury_account.contract_address,
        treasury_account.contract_address,
    ])

    proxy_resources = await proxy_builder(compiled_proxy, starknet, admin_key, admin_account, "contracts/settling_game/tokens/Resources_ERC1155_Mintable_Burnable.cairo", [
        1234,
        admin_account.contract_address
    ])

    return (
        starknet,
        admin_key,
        admin_account,
        treasury_account,
        accounts,
        signers,
        proxy_lords,
        proxy_resources
    )
