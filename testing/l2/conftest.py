import asyncio
import pytest
import dill
import os
from utils.Signer import Signer

from types import SimpleNamespace

from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.starknet import Starknet, StarknetContract

CONTRACT_SRC = [os.path.dirname(__file__), "../..", "contracts"]

def compile(path):
    return compile_starknet_files(
        files=[path],
        debug_info=True,
        cairo_path=CONTRACT_SRC,
    )

async def create_account(starknet, signer, account_def):
    return await starknet.deploy(
        contract_def=account_def,
        constructor_calldata=[signer.public_key],
    )

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

    defs = SimpleNamespace(
        account=compile("l2/utils/Account.cairo"),
        erc20=compile("l2/tokens/ERC20.cairo")
    )

    signers = SimpleNamespace(
        arbiter=Signer(83745982347),
        minter=Signer(897654321),
    )

    accounts = SimpleNamespace(
        arbiter=await create_account(starknet, signers.arbiter, defs.account),
        minter=await create_account(starknet, signers.minter, defs.account),
    )

    erc20 = await starknet.deploy(
        contract_def=defs.erc20,
        constructor_calldata=[accounts.minter.contract_address],
    )

    return SimpleNamespace(
        starknet=starknet,
        defs=defs,
        signers=signers,
        addresses=SimpleNamespace(
            arbiter=accounts.arbiter.contract_address,
            erc20=erc20.contract_address,
        ),
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
    defs = copyable_deployment.defs
    addresses = copyable_deployment.addresses
    signers = copyable_deployment.signers

    def make():
        starknet_state = copyable_deployment.starknet.state.copy()

        accounts = SimpleNamespace(
            arbiter=StarknetContract(
                state=starknet_state,
                abi=defs.account.abi,
                contract_address=addresses.arbiter,
            ),
        )

        async def execute(account_name, contract_address, selector_name, calldata):
            return await signers.__dict__[account_name].send_transaction(
                accounts.__dict__[account_name],
                contract_address,
                selector_name,
                calldata,
            )

        return SimpleNamespace(
            starknet=Starknet(starknet_state),
            accounts=accounts,
            execute=execute,
            erc20=StarknetContract(
                state=starknet_state,
                abi=defs.erc20.abi,
                contract_address=addresses.erc20,
            ),
        )

    return make
