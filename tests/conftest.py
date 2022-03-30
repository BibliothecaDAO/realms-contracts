import asyncio
import pytest
import dill
import os
from openzeppelin.tests.utils import Signer, uint, str_to_felt
import sys
import time

from types import SimpleNamespace
import logging
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.services.api.contract_definition import ContractDefinition
from starkware.starknet.testing.starknet import Starknet, StarknetContract
from starkware.starknet.business_logic.state import BlockInfo

sys.stdout = sys.stderr

# Create signers that use a private key to sign transaction objects.
DUMMY_PRIVATE = 123456789987654321

CONTRACT_SRC = os.path.join(os.path.dirname(__file__), "../..", "contracts")
INITIAL_LORDS_SUPPLY = 500000000 * (10 ** 18)
REALM_MINT_PRICE = 10 * (10 ** 18)

first_token_id = (5042, 0)
second_token_id = (7921, 1)
third_token_id = (0, 13)
fourth_token_id = (232, 3453)
fifth_token_id = (234, 345)
sixth_token_id = (9999, 9999)

initial_user_funds = 1000 * (10 ** 18)


def compile(path) -> ContractDefinition:
    here = os.path.abspath(os.path.dirname(__file__))

    return compile_starknet_files(
        files=[path],
        debug_info=True,
        disable_hint_validation=True,
        cairo_path=[CONTRACT_SRC, here],
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


@pytest.fixture(scope="session")
async def starknet() -> Starknet:
    starknet = await Starknet.empty()
    return starknet


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
        account=compile("openzeppelin/account/Account.cairo"),
        erc20=compile("contracts/token/ERC20_Mintable.cairo"),
        erc721=compile(
            "contracts/token/ERC721_Enumerable_Mintable_Burnable.cairo"),
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
            accounts.admin.contract_address,  # recipient
            5,  # token_ids_len
            1, 2, 3, 4, 5,
            5,  # amounts_len
            100000, 5000, 10000, 10000, 10000,
        ],
    )

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

    lords_approve_amount = consts.REALM_MINT_PRICE * 3

    async def mint_realms(account_name, token):
        await signers[account_name].send_transaction(
            accounts.__dict__[
                account_name], realms.contract_address, 'publicMint', [*uint(token)]
        )

    await _erc20_approve("user1", realms.contract_address, lords_approve_amount)
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
            set_block_timestamp(starknet_state, get_block_timestamp(
                starknet_state) + num_seconds)

        return SimpleNamespace(
            starknet=Starknet(starknet_state),
            advance_clock=advance_clock,
            signers=signers,
            consts=consts,
            execute=execute,
            **contracts,
        )

    return make


@pytest.fixture(scope="session")
async def xoroshiro(starknet):
    contract = compile("contracts/utils/xoroshiro128_starstar.cairo")
    seed = 0x10AF
    return await starknet.deploy(contract_def=contract, constructor_calldata=[seed])


@pytest.fixture(scope='module')
async def account_factory(request):
    num_signers = request.param.get("num_signers", "1")
    starknet = await Starknet.empty()
    accounts = []
    signers = []

    print(f'Deploying {num_signers} accounts...')
    for i in range(num_signers):
        signer = Signer(DUMMY_PRIVATE + i)
        signers.append(signer)
        account = await starknet.deploy(
            "openzeppelin/account/Account.cairo",
            constructor_calldata=[signer.public_key]
        )
        accounts.append(account)

        print(f'Account {i} is: {hex(account.contract_address)}')

    # Initialize network

    # Admin is usually accounts[0], user_1 = accounts[1].
    # To build a transaction to call func_xyz(arg_1, arg_2)
    # on a TargetContract:

    # await Signer.send_transaction(
    #   account=accounts[1],
    #   to=TargetContract,
    #   selector_name='func_xyz',
    #   calldata=[arg_1, arg_2],
    #   nonce=current_nonce)

    # Note that nonce is an optional argument.
    return starknet, accounts, signers


###########################
# COMBAT specific fixtures
###########################

@pytest.fixture(scope="module")
async def l06_combat(starknet, xoroshiro) -> StarknetContract:
    contract = compile("contracts/settling_game/L06_Combat.cairo")
    return await starknet.deploy(
        contract_def=contract, constructor_calldata=[
            xoroshiro.contract_address]
    )


@pytest.fixture(scope="module")
async def l06_combat_tests(starknet, xoroshiro) -> StarknetContract:
    contract = compile("tests/settling_game/L06_Combat_tests.cairo")
    # a quirk of the testing framework, even though the L06_Combat_tests contract
    # doesn't have a constructor, it somehow calls (I guess) the constructor of
    # L06_Combat because it imports from it; hence when calling deploy, we need
    # to pass proper constructor_calldata
    return await starknet.deploy(contract_def=contract, constructor_calldata=[xoroshiro.contract_address])


@pytest.fixture(scope="module")
async def s06_combat(starknet) -> StarknetContract:
    contract = compile("contracts/settling_game/S06_Combat.cairo")
    return await starknet.deploy(contract_def=contract)


@pytest.fixture(scope="module")
async def s06_combat_tests(starknet) -> StarknetContract:
    contract = compile("tests/settling_game/S06_Combat_tests.cairo")
    return await starknet.deploy(contract_def=contract)


###########################
# DESIEGE specific fixtures
###########################

# StarknetContracts contain an immutable reference to StarknetState, which
# means if we want to be able to use StarknetState's `copy` method, we cannot
# rely on StarknetContracts that were created prior to the copy.
# For that reason, we avoid returning any StarknetContracts in this "copyable"
# deployment:
async def _build_copyable_deployment_desiege():
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
async def copyable_deployment_desiege(request):
    CACHE_KEY = "deployment_desiege"
    val = request.config.cache.get(CACHE_KEY, None)
    if val is None:
        val = await _build_copyable_deployment_desiege()
        res = dill.dumps(val).decode("cp437")
        request.config.cache.set(CACHE_KEY, res)
    else:
        val = dill.loads(val.encode("cp437"))
    return val


@pytest.fixture(scope="session")
async def ctx_factory_desiege(copyable_deployment_desiege):
    serialized_contracts = copyable_deployment_desiege.serialized_contracts
    signers = copyable_deployment_desiege.signers

    def make():
        starknet_state = copyable_deployment_desiege.starknet.state.copy()

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
