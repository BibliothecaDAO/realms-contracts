import asyncio
import pytest
import dill
import os
from utils import Signer, uint, str_to_felt, MAX_UINT256, assert_revert
import sys
import time

from types import SimpleNamespace
import logging
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.starknet import Starknet, StarknetContract
from starkware.starknet.business_logic.state import BlockInfo

sys.stdout = sys.stderr


CONTRACT_SRC = [os.path.dirname(__file__), "../..", "contracts"]
INITIAL_LORDS_SUPPLY = 500000000 * (10 ** 18)
REALM_MINT_PRICE = 10 * (10 ** 18)

first_token_id = (5042, 0)
second_token_id = (7921, 1)
third_token_id = (0, 13)
fourth_token_id = (232, 3453)
fifth_token_id = (234, 345)
sixth_token_id = (9999, 9999)

initial_user_funds = 1000 * (10 ** 18)


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


    # initialize a realistic timestamp
    set_block_timestamp(starknet.state, round(time.time()))

    logging.warning(CONTRACT_SRC)
    defs = SimpleNamespace(
        account=compile("contracts/Account.cairo"),
        erc20=compile("contracts/token/ERC20_Mintable.cairo"),
        erc721=compile("contracts/token/ERC721_Enumerable_Mintable_Burnable.cairo"),
        erc1155=compile("contracts/token/ERC1155/ERC1155_Mintable.cairo"),
    )

    signers = dict(
        admin=Signer(83745982347),
        arbiter=Signer(7891011),
        user1=Signer(897654321),
        user2=Signer(897654422321),
    )

    accounts = SimpleNamespace(
        **{
            name: (await create_account(starknet, signer, defs.account))
            for name, signer in signers.items()
        }
    )

    lords = await starknet.deploy(
        contract_def=defs.erc20,
        constructor_calldata=[
            str_to_felt("Lords"),  # name
            str_to_felt("LRD"),  # symbol
            *uint(INITIAL_LORDS_SUPPLY),  # initial supply
            accounts.admin.contract_address,  # recipient
            accounts.admin.contract_address,
        ],
    )
    accounts.lords = lords
    logging.warning(accounts)

    realms = await starknet.deploy(
        contract_def=defs.erc721,
        constructor_calldata=[
            str_to_felt("Realms"),  # name
            str_to_felt("Realms"),  # ticker
            accounts.admin.contract_address,  # contract_owner
            lords.contract_address,  # currency_address
        ],
    )
    accounts.realms = realms

    resources = await starknet.deploy(
        contract_def=defs.erc1155,
        constructor_calldata=[
            accounts.admin.contract_address, #recipient
            2, #token_ids_len
            1, 2,
            2, #amounts_len
            1000, 5000
        ])

    consts = SimpleNamespace(
        REALM_MINT_PRICE=REALM_MINT_PRICE, INITIAL_USER_FUNDS=initial_user_funds
    )

    async def give_tokens(recipient, amount):
        await signers["admin"].send_transaction(
            accounts.admin,
            lords.contract_address,
            "transfer",
            [recipient, *uint(amount)],
        )


    async def _erc20_approve(account_name, contract_address, amount):
        await signers[account_name].send_transaction(
            accounts.__dict__[account_name],
            lords.contract_address,
            'approve',
            [contract_address, *uint(amount)],
        )

    lords_approve_ammount = consts.REALM_MINT_PRICE * 3

    async def mint_realms(account_name, token):
        await signers[account_name].send_transaction(
            accounts.__dict__[account_name], realms.contract_address, 'publicMint', [*uint(token)]
        )

    await _erc20_approve("user1", realms.contract_address, lords_approve_ammount)
    await give_tokens(accounts.user1.contract_address, initial_user_funds)
    await mint_realms("user1", 23)
    await mint_realms("user1", 7225)

    await give_tokens(accounts.user2.contract_address, initial_user_funds)

    return SimpleNamespace(
        starknet=starknet,
        consts=consts,
        signers=signers,
        serialized_contracts=dict(
            admin=serialize_contract(accounts.admin, defs.account.abi),
            arbiter=serialize_contract(accounts.arbiter, defs.account.abi),
            lords=serialize_contract(lords, defs.erc20.abi),
            realms=serialize_contract(realms, defs.erc721.abi),
            resources=serialize_contract(resources, defs.erc1155.abi),
            user1=serialize_contract(accounts.user1, defs.account.abi),
            user2=serialize_contract(accounts.user2, defs.account.abi),
        ),
        addresses=SimpleNamespace(
            admin=accounts.admin.contract_address,
            arbiter=accounts.arbiter.contract_address,
            lords=lords.contract_address,
            realms=realms.contract_address,
            resources=resources.contract_address,
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
    serialized_contracts = copyable_deployment.serialized_contracts
    signers = copyable_deployment.signers
    consts = copyable_deployment.consts

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

        def advance_clock(num_seconds):
            set_block_timestamp(
                starknet_state, get_block_timestamp(starknet_state) + num_seconds
            )

        return SimpleNamespace(
            starknet=Starknet(starknet_state),
            advance_clock=advance_clock,
            consts=consts,
            execute=execute,
            **contracts,
        )

    return make
