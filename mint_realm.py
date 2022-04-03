# from dotenv import load_dotenv
import asyncio
import json
from openzeppelin.tests.utils import Signer, uint, str_to_felt, felt_to_str
from scripts.binary_converter import map_realm
# load_dotenv()
from starkware.starknet.wallets.open_zeppelin import OpenZeppelinAccount
from services.external_api.base_client import RetryConfig
from starkware.starknet.services.api.gateway.gateway_client import GatewayClient
from starkware.starknet.services.api.feeder_gateway.feeder_gateway_client import FeederGatewayClient
from starkware.cairo.lang.vm.crypto import get_crypto_lib_context_manager
from starkware.starknet.wallets.starknet_context import StarknetContext
from starkware.starknet.cli.starknet_cli import load_account

json_realms = json.load(open('data/realms.json'))

signer = Signer(123)

# ENV VARIABLES
NETWORK = "alpha-goerli"
STARKNET_WALLET = "starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount"
ACCOUNT_DIR = "realms-cli/hot"
GATEWAY_URL = "https://alpha4.starknet.io/gateway"
GATEWAY_FEEDER_URL = "https://alpha4.starknet.io/feeder_gateway"
# we can also directly import this wallet
# this wallet will be used during invoke and call commands

# THIS REPO

# OTHER GENERAL


def get_gateway_client():
    retry_config = RetryConfig(n_retries=1)
    return GatewayClient(
        url=GATEWAY_URL,
        retry_config=retry_config)


def get_feeder_gateway_client():
    retry_config = RetryConfig(n_retries=1)
    return FeederGatewayClient(
        url=GATEWAY_FEEDER_URL,
        retry_config=retry_config)


def get_context():
    return StarknetContext(
        network_id=NETWORK,
        account_dir=ACCOUNT_DIR,
        gateway_client=get_gateway_client(),
        feeder_gateway_client=get_feeder_gateway_client()
    )


async def mint_realm():
    context = get_context()
    account = await OpenZeppelinAccount.create(
        starknet_context=context,
        account_name="test_account_1")
    set_realm = await signer.send_transaction(
        account, '0x43b557ed70520b547f9631abec08b52df1e2b5b0037473c1cc348820b0063b9', 'set_realm_data', [
            *uint(1), map_realm(json_realms['1'])]
    )
    return set_realm


async def main():
    realm = await mint_realm()
    print(realm)

asyncio.run(main())
