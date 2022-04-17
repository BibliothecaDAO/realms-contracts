from re import sub
import asyncio
import argparse
from starkware.starknet.wallets.open_zeppelin import OpenZeppelinAccount
from services.external_api.base_client import RetryConfig
from starkware.starknet.services.api.gateway.gateway_client import GatewayClient
from starkware.starknet.services.api.feeder_gateway.feeder_gateway_client import FeederGatewayClient
from starkware.cairo.lang.vm.crypto import get_crypto_lib_context_manager
from starkware.starknet.wallets.starknet_context import StarknetContext
from starkware.starknet.cli.starknet_cli import load_account
from utils import Signer



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
    signer = Signer(
        0x065abfa492a31efe92b3784206de3fa14627322952fb96840e67b82838a5253f)
    # this will fetch the __default__ wallet
    context = get_context()
    account = await OpenZeppelinAccount.create(
        starknet_context=context,
        account_name="admin")
    print(account)
    return 0


# async def main():
#     subparsers = {
#         "mint_realm": mint_realm,
#     }

#     parser = argparse.ArgumentParser()
#     parser.add_argument(
#         "--flavor",
#         type=str,
#         choices=["Debug", "Release", "RelWithDebInfo"],
#         help="Build flavor.",
#     )
#     parser.add_argument("command", choices=subparsers.keys())
#     args, _ = parser.parse_known_args()

#     return await subparsers[args.command](args)

if __name__ == "__main__":
    asyncio.run(mint_realm())
