import asyncio
import pytest
import dill
import os
from utils import Signer, uint, str_to_felt, MAX_UINT256, assert_revert

from types import SimpleNamespace
import logging
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.starknet import Starknet, StarknetContract

CONTRACT_SRC = [os.path.dirname(__file__), "../..", "contracts"]
INITIAL_LORDS_SUPPLY = 500000000  * (10 ** 18)
REALM_MINT_PRICE= 10 * (10 ** 18)

first_token_id = (5042, 0)
second_token_id = (7921, 1)
third_token_id = (0, 13)
fourth_token_id = (232, 3453)
fifth_token_id = (234, 345)
sixth_token_id = (9999, 9999)

initial_user_funds = 1000  * (10 ** 18)

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
    logging.warning(CONTRACT_SRC)
    defs = SimpleNamespace(
        account=compile("contracts/Account.cairo"),
        erc20=compile("contracts/token/ERC20_Mintable.cairo"),
        erc721=compile("contracts/token/ERC721_Mintable.cairo"),
    )

    signers = SimpleNamespace(
        admin=Signer(83745982347),
        arbiter=Signer(7891011),
        user1=Signer(897654321),
        user2=Signer(897654422321),
    )

    accounts = SimpleNamespace(
        admin=await create_account(starknet, signers.admin, defs.account),
        arbiter=await create_account(starknet, signers.arbiter, defs.account),
        user1=await create_account(starknet, signers.user1, defs.account),
        user2=await create_account(starknet, signers.user2, defs.account),

    )

    lords = await starknet.deploy(
        contract_def=defs.erc20,
        constructor_calldata=[
            str_to_felt("Lords"),     # name
            str_to_felt("LRD"),       # symbol
            *uint(INITIAL_LORDS_SUPPLY),                # initial supply
            accounts.admin.contract_address,   # recipient
            accounts.admin.contract_address,

        ]
    )

    realms = await starknet.deploy(
        contract_def=defs.erc721,
        constructor_calldata=[
            str_to_felt("Realms"),             # name
            str_to_felt("Realms"),             # ticker
            accounts.admin.contract_address,   # contract_owner
            lords.contract_address             # currency_address
        ])

    consts = SimpleNamespace(
        REALM_MINT_PRICE=REALM_MINT_PRICE,
        INITIAL_USER_FUNDS=initial_user_funds
    )

    async def give_tokens(recipient, amount):
        await signers.admin.send_transaction(
            accounts.admin,
            lords.contract_address,
            "transfer",
            [recipient, *uint(amount)],
        )



    async def _erc20_approve(account_name, contract_address, amount):
        await signers.__dict__[account_name].send_transaction(
            accounts.__dict__[account_name],
            lords.contract_address,
            'approve',
            [contract_address, *uint(amount)]
    )

    lords_approve_ammount = consts.REALM_MINT_PRICE * 3

    async def mint_realms(account_name, token):
        await signers.__dict__[account_name].send_transaction(
            accounts.__dict__[account_name],
            realms.contract_address,
            'publicMint',
            [*uint(token)]
        )

    await _erc20_approve("user1", realms.contract_address, lords_approve_ammount)
    await give_tokens(accounts.user1.contract_address, initial_user_funds)
    await mint_realms("user1", 23)
    await mint_realms("user1", 7225)

    await give_tokens(accounts.user2.contract_address, initial_user_funds)


    return SimpleNamespace(
        starknet=starknet,
        defs=defs,
        consts=consts,
        signers=signers,
        addresses=SimpleNamespace(
            admin=accounts.admin.contract_address,
            arbiter=accounts.arbiter.contract_address,
            lords=lords.contract_address,
            realms=realms.contract_address,
            user1=accounts.user1.contract_address,
            user2=accounts.user2.contract_address,
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
    consts = copyable_deployment.consts
    
    def make():
        starknet_state = copyable_deployment.starknet.state.copy()

        accounts = SimpleNamespace(
            arbiter=StarknetContract(
                state=starknet_state,
                abi=defs.account.abi,
                contract_address=addresses.arbiter,
            ),
            user1=StarknetContract(
                state=starknet_state,
                abi=defs.account.abi,
                contract_address=addresses.user1,
            ),
            user2=StarknetContract(
                state=starknet_state,
                abi=defs.account.abi,
                contract_address=addresses.user2,
            ),
            admin=StarknetContract(
                state=starknet_state,
                abi=defs.account.abi,
                contract_address=addresses.admin,
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
            consts=consts,
            execute=execute,
            lords=StarknetContract(
                state=starknet_state,
                abi=defs.erc20.abi,
                contract_address=addresses.lords,
            ),
            realms=StarknetContract(
                state=starknet_state,
                abi=defs.erc721.abi,
                contract_address=addresses.realms,
            ),
        )

    return make
