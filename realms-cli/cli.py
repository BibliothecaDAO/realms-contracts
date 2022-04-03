import argparse
import asyncio
from re import sub

# ENV VARIABLES
NETWORK="alpha-goerli"
STARKNET_WALLET="starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount"
ACCOUNT_DIR="realms-cli/hot"
GATEWAY_URL="https://alpha4.starknet.io/gateway"
GATEWAY_FEEDER_URL="https://alpha4.starknet.io/feeder_gateway"
# we can also directly import this wallet
from starkware.starknet.wallets.open_zeppelin import OpenZeppelinAccount
# this wallet will be used during invoke and call commands

# THIS REPO
import sys
sys.path.append("/workspaces/realms-contracts")
from openzeppelin.tests.utils import Signer

# OTHER GENERAL
from services.external_api.base_client import RetryConfig
from starkware.starknet.services.api.gateway.gateway_client import GatewayClient
from starkware.starknet.services.api.feeder_gateway.feeder_gateway_client import FeederGatewayClient
from starkware.cairo.lang.vm.crypto import get_crypto_lib_context_manager
from starkware.starknet.wallets.starknet_context import StarknetContext

from starkware.starknet.cli.starknet_cli import load_account

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

async def mint_realm(args):
    signer = Signer(0x33c3c3163ad50409e6c8645606623c2f9f3e404fd185d1c7deba1a17f1fcc28)
    # this will fetch the __default__ wallet
    context = get_context()
    account = await OpenZeppelinAccount.create(
        starknet_context=context,
        account_name="test_account_1")
    print(account)
    return 0

async def main():
    subparsers = {
        "mint_realm": mint_realm,
    }

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--flavor",
        type=str,
        choices=["Debug", "Release", "RelWithDebInfo"],
        help="Build flavor.",
    )
    parser.add_argument("command", choices=subparsers.keys())
    args, _ = parser.parse_known_args()

    return await subparsers[args.command](args)

if __name__=="__main__":
    asyncio.run(main())
