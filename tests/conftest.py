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

sys.setrecursionlimit(3000)

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

initial_supply = 1000000 * (10 ** 18)
DEFAULT_GAS_PRICE = 100


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
        starknet_state.state.block_info.block_number, timestamp, DEFAULT_GAS_PRICE
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

    defs = SimpleNamespace(
        account=compile("openzeppelin/account/Account.cairo"),
        lords=compile("contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo"),
        realms=compile("contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo"),
        s_realms=compile("contracts/settling_game/tokens/S_Realms_ERC721_Mintable.cairo"),
        resources=compile(
            "contracts/settling_game/tokens/Resources_ERC1155_Mintable_Burnable.cairo"
        ),
    )

    signers = dict(admin=Signer(83745982347), arbiter=Signer(7891011), user1=Signer(897654321))

    accounts = SimpleNamespace(
        **{
            name: (await create_account(starknet, signer, defs.account))
            for name, signer in signers.items()
        }
    )

    lords = await starknet.deploy(
        contract_def=defs.lords,
        constructor_calldata=[
            str_to_felt("Lords"),  # name
            str_to_felt("LRD"),  # symbol
            11,  # decimal
            *uint(INITIAL_LORDS_SUPPLY),  # initial supply
            accounts.admin.contract_address,  # recipient
            accounts.admin.contract_address,
        ],
    )

    realms = await starknet.deploy(
        contract_def=defs.realms,
        constructor_calldata=[
            str_to_felt("Realms"),  # name
            str_to_felt("Realms"),  # ticker
            accounts.admin.contract_address,  # contract_owner
        ],
    )

    s_realms = await starknet.deploy(
        contract_def=defs.s_realms,
        constructor_calldata=[
            str_to_felt("SRealms"),  # name
            str_to_felt("SRealms"),  # ticker
            accounts.admin.contract_address,  # contract_owner
        ],
    )

    resources = await starknet.deploy(
        contract_def=defs.resources,
        constructor_calldata=[
            1234,
            accounts.admin.contract_address,  # recipient
        ],
    )

    return SimpleNamespace(
        starknet=starknet,
        signers=signers,
        accounts=accounts,
        serialized_contracts=dict(
            admin=serialize_contract(accounts.admin, defs.account.abi),
            arbiter=serialize_contract(accounts.arbiter, defs.account.abi),
            lords=serialize_contract(lords, defs.lords.abi),
            realms=serialize_contract(realms, defs.realms.abi),
            s_realms=serialize_contract(s_realms, defs.s_realms.abi),
            resources=serialize_contract(resources, defs.resources.abi),
            user1=serialize_contract(accounts.user1, defs.account.abi),
        ),
        addresses=SimpleNamespace(
            admin=accounts.admin.contract_address,
            arbiter=accounts.arbiter.contract_address,
            lords=lords.contract_address,
            realms=realms.contract_address,
            resources=resources.contract_address,
            user1=accounts.user1.contract_address,
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
            set_block_timestamp(starknet_state, get_block_timestamp(starknet_state) + num_seconds)

        return SimpleNamespace(
            starknet=Starknet(starknet_state),
            advance_clock=advance_clock,
            signers=signers,
            execute=execute,
            **contracts,
        )

    return make


@pytest.fixture(scope="session")
async def xoroshiro(starknet):
    contract = compile("contracts/utils/xoroshiro128_starstar.cairo")
    seed = 0x10AF
    return await starknet.deploy(contract_def=contract, constructor_calldata=[seed])


@pytest.fixture(scope='session')
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
            "openzeppelin/account/Account.cairo", constructor_calldata=[signer.public_key]
        )
        accounts.append(account)

        print(f'Account {i} is: {hex(account.contract_address)}')

    return starknet, accounts, signers


###########################
# COMBAT specific fixtures
###########################


@pytest.fixture(scope="module")
async def l06_combat(starknet, xoroshiro) -> StarknetContract:
    contract = compile("contracts/settling_game/L06_Combat.cairo")
    return await starknet.deploy(
        contract_def=contract, constructor_calldata=[11, xoroshiro.contract_address]
    )


@pytest.fixture(scope="module")
async def l06_combat_tests(starknet, xoroshiro) -> StarknetContract:
    contract = compile("tests/settling_game/L06_Combat_tests.cairo")
    # a quirk of the testing framework, even though the L06_Combat_tests contract
    # doesn't have a constructor, it somehow calls (I guess) the constructor of
    # L06_Combat because it imports from it; hence when calling deploy, we need
    # to pass proper constructor_calldata
    return await starknet.deploy(
        contract_def=contract, constructor_calldata=[11, xoroshiro.contract_address]
    )


@pytest.fixture(scope="module")
async def s06_combat(starknet) -> StarknetContract:
    contract = compile("contracts/settling_game/S06_Combat.cairo")
    return await starknet.deploy(contract_def=contract)


@pytest.fixture(scope="module")
async def library_combat_tests(starknet) -> StarknetContract:
    contract = compile("tests/settling_game/library_combat_tests.cairo")
    return await starknet.deploy(contract_def=contract)


@pytest.fixture(scope="module")
async def utils_general_tests(starknet) -> StarknetContract:
    contract = compile("tests/settling_game/utils/general_tests.cairo")
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
        player3=Signer(233294208),
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
            player3=serialize_contract(accounts.player3, defs.account.abi),
        ),
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


@pytest.fixture(scope='session')
async def token_factory(account_factory):
    (starknet, accounts, signers) = account_factory
    admin_key = signers[0]
    admin_account = accounts[0]
    treasury_account = accounts[1]

    set_block_timestamp(starknet.state, round(time.time()))
    print('Lords...')
    lords = await starknet.deploy(
        source="contracts/settling_game/tokens/Lords_ERC20_Mintable.cairo",
        constructor_calldata=[
            str_to_felt("Lords"),  # name
            str_to_felt("LRD"),
            11,  # symbol
            *uint(initial_supply),  # initial supply
            treasury_account.contract_address,  # recipient
            treasury_account.contract_address,  # owner
        ],
    )
    print('Realms...')
    realms = await starknet.deploy(
        source="contracts/settling_game/tokens/Realms_ERC721_Mintable.cairo",
        constructor_calldata=[
            str_to_felt("Realms"),  # name
            str_to_felt("Realms"),  # ticker
            admin_account.contract_address,  # contract_owner
        ],
    )
    print('S_Realms...')
    s_realms = await starknet.deploy(
        source="contracts/settling_game/tokens/S_Realms_ERC721_Mintable.cairo",
        constructor_calldata=[
            str_to_felt("SRealms"),  # name
            str_to_felt("SRealms"),  # ticker
            admin_account.contract_address,  # contract_owner
        ],
    )
    print('Resources...')
    resources = await starknet.deploy(
        source="contracts/settling_game/tokens/Resources_ERC1155_Mintable_Burnable.cairo",
        constructor_calldata=[1234, admin_account.contract_address],
    )

    return (
        starknet,
        admin_key,
        admin_account,
        treasury_account,
        accounts,
        signers,
        lords,
        realms,
        s_realms,
        resources,
    )


@pytest.fixture(scope='session')
async def game_factory(token_factory):
    (
        starknet,
        admin_key,
        admin_account,
        treasury_account,
        accounts,
        signers,
        lords,
        realms,
        s_realms,
        resources,
    ) = token_factory

    print('Game...')
    arbiter = await starknet.deploy(
        source="contracts/settling_game/Arbiter.cairo",
        constructor_calldata=[admin_account.contract_address],
    )
    controller = await starknet.deploy(
        source="contracts/settling_game/ModuleController.cairo",
        constructor_calldata=[
            arbiter.contract_address,
            lords.contract_address,
            resources.contract_address,
            realms.contract_address,
            treasury_account.contract_address,
            s_realms.contract_address
        ],
    )
    
    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='set_address_of_controller',
        calldata=[controller.contract_address],
    )

    settling_logic = await starknet.deploy(
        source="contracts/settling_game/L01_Settling.cairo",
        constructor_calldata=[controller.contract_address],
    )

    # proxy_settling_logic = await starknet.deploy(
    #     source="contracts/settling_game/proxy/PROXY_Logic.cairo",
    #     constructor_calldata=[settling_logic.contract_address],
    # )

    # await admin_key.send_transaction(
    #     account=admin_account,
    #     to=proxy_settling_logic.contract_address,
    #     selector_name='initializer',
    #     calldata=[admin_account.contract_address, controller.contract_address],
    # )

    settling_state = await starknet.deploy(
        source="contracts/settling_game/S01_Settling.cairo",
        constructor_calldata=[controller.contract_address],
    )
    resources_logic = await starknet.deploy(
        source="contracts/settling_game/L02_Resources.cairo",
        constructor_calldata=[controller.contract_address],
    )
    resources_state = await starknet.deploy(
        source="contracts/settling_game/S02_Resources.cairo",
        constructor_calldata=[controller.contract_address],
    )
    buildings_logic = await starknet.deploy(
        source="contracts/settling_game/L03_Buildings.cairo",
        constructor_calldata=[controller.contract_address],
    )
    buildings_state = await starknet.deploy(
        source="contracts/settling_game/S03_Buildings.cairo",
        constructor_calldata=[controller.contract_address],
    )
    calculator_logic = await starknet.deploy(
        source="contracts/settling_game/L04_Calculator.cairo",
        constructor_calldata=[controller.contract_address],
    )
    wonders_logic = await starknet.deploy(
        source="contracts/settling_game/L05_Wonders.cairo",
        constructor_calldata=[controller.contract_address],
    )
    wonders_state = await starknet.deploy(
        source="contracts/settling_game/S05_Wonders.cairo",
        constructor_calldata=[controller.contract_address],
    )
    # The admin key controls the arbiter. Use it to have the arbiter
    # set the module deployment addresses in the controller.
    await admin_key.send_transaction(
        account=admin_account,
        to=arbiter.contract_address,
        selector_name='batch_set_controller_addresses',
        calldata=[
            settling_logic.contract_address,
            settling_state.contract_address,
            resources_logic.contract_address,
            resources_state.contract_address,
            buildings_logic.contract_address,
            buildings_state.contract_address,
            calculator_logic.contract_address,
            wonders_logic.contract_address,
            wonders_state.contract_address,
        ],
    )

    # set module access witin S_Realm contract
    await admin_key.send_transaction(
        account=admin_account,
        to=s_realms.contract_address,
        selector_name='Set_module_access',
        calldata=[settling_logic.contract_address],
    )

    # set module access witin resources contract
    await admin_key.send_transaction(
        account=admin_account,
        to=resources.contract_address,
        selector_name='Set_module_access',
        calldata=[resources_logic.contract_address],
    )

    # test upgrade
    # V2_settling_logic = await starknet.deploy(
    #     source="contracts/settling_game/L01_Settling.cairo",
    #     constructor_calldata=[],
    # )

    # await admin_key.send_transaction(
    #     account=admin_account,
    #     to=settling_logic.contract_address,
    #     selector_name='upgrade',
    #     calldata=[V2_settling_logic.contract_address],
    # )
    return (
        admin_account,
        treasury_account,
        starknet,
        accounts,
        signers,
        arbiter,
        controller,
        settling_logic,
        settling_state,
        realms,
        resources,
        lords,
        resources_logic,
        resources_state,
        s_realms,
        buildings_logic,
        buildings_state,
        calculator_logic
    )