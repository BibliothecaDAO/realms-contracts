# This conftest.py is required so that 
# imports of utils references the local version
# not the version under l2 parent dir

import asyncio
import pytest
import dill
import os
from utils import Signer
import sys
import logging
from types import SimpleNamespace

from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.starknet import Starknet, StarknetContract
from starkware.starknet.business_logic.state import BlockInfo

CONTRACT_SRC = [os.path.dirname(__file__), "../../..", "contracts"]
sys.stdout = sys.stderr

def compile(path):
    return compile_starknet_files(
        # In subdirectory, must prefix path with CONTRACT_SRC to compile successfully
        files=[os.path.join(*CONTRACT_SRC,path)],
        debug_info=True,
        cairo_path=CONTRACT_SRC,
    )

async def create_account(starknet, signer, account_def):
    return await starknet.deploy(
        contract_def=account_def,
        constructor_calldata=[signer.public_key],
    )

def get_block_timestamp(starknet_state):
    return starknet_state.state.block_info.block_timestamp

def set_block_timestamp(starknet_state, timestamp):
    starknet_state.state.block_info = BlockInfo(
        starknet_state.state.block_info.block_number, timestamp
    )

# StarknetContracts contain an immutable reference to StarknetState, which
# means if we want to be able to use StarknetState's `copy` method, we cannot
# rely on StarknetContracts that were created prior to the copy.
# For this reason, we specifically inject a new StarknetState when
# deserializing a contract.
def serialize_contract(contract, abi):
    return dict(
        abi=abi,
        contract_address=contract.contract_address,
        deploy_execution_info=contract.deploy_execution_info,
    )


def unserialize_contract(starknet_state, serialized_contract):
    return StarknetContract(state=starknet_state, **serialized_contract)

@pytest.fixture(scope="session")
def event_loop():
    return asyncio.new_event_loop()

# StarknetContracts contain an immutable reference to StarknetState, which
# means if we want to be able to use StarknetState's `copy` method, we cannot
# rely on StarknetContracts that were created prior to the copy.
# For that reason, we avoid returning any StarknetContracts in this "copyable"
# deployment:
async def _build_copyable_deployment():
    starknet = await Starknet.empty()

    logging.warning(CONTRACT_SRC)

    defs = SimpleNamespace(
        account=compile("openzeppelin/account/Account.cairo"),
    )

    signers = dict(
        admin=Signer(83745982347),
        player1=Signer(233294204),
        player2=Signer(233294206),
        player3=Signer(233294208)
    )

    accounts = SimpleNamespace(
        **{
            name: (await create_account(starknet, signer, defs.account))
            for name, signer in signers.items()
        }
    )

    return SimpleNamespace(
        starknet=starknet,
        signers=signers,
        serialized_contracts=dict(
            admin=serialize_contract(accounts.admin, defs.account.abi),
            player1=serialize_contract(accounts.player1, defs.account.abi),
            player2=serialize_contract(accounts.player2, defs.account.abi),
            player3=serialize_contract(accounts.player3, defs.account.abi)
        )
    )

@pytest.fixture(scope="session")
async def copyable_deployment(request):
    CACHE_KEY = "deployment"
    val = request.config.cache.get(CACHE_KEY, None)
    if val is None:
        val = await _build_copyable_deployment()
        res = dill.dumps(val).decode("cp437")
        request.config.cache.set(CACHE_KEY, res)
    else:
        val = dill.loads(val.encode("cp437"))
    return val

@pytest.fixture(scope="session")
async def ctx_factory(copyable_deployment):
    serialized_contracts = copyable_deployment.serialized_contracts
    signers = copyable_deployment.signers

    def make():
        starknet_state = copyable_deployment.starknet.state.copy()

        contracts = {
            name: unserialize_contract(starknet_state, serialized_contract)
            for name, serialized_contract in serialized_contracts.items()
        }

        async def execute(account_name, contract_address, selector_name, calldata):
            return await signers[account_name].send_transaction(
                contracts[account_name],
                contract_address,
                selector_name,
                calldata,
            )

        return SimpleNamespace(
            starknet=Starknet(starknet_state),
            execute=execute,
            **contracts,
        )

    return make
