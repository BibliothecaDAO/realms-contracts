"""
This files holds wrapper functions for calls and invokes.
As you can see, we just invoke other nile CLI commands and we can
probably also just call nile python functions.
"""
import re
import subprocess
import asyncio
import os
import json
import sys
import io
import time
from types import SimpleNamespace
from collections import namedtuple

from nile.core.types.account import Account, get_nonce
from nile import deployments
from nile.core.declare import alias_exists
from nile.core.call_or_invoke import call_or_invoke
from nile.core.types.transactions import DeclareTransaction
from nile.starknet_cli import set_command_args
from nile.utils import hex_address, normalize_number
from nile.utils.status import TransactionStatus, TxStatus
from realms_cli.config import Config
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.cli import starknet_cli
from starkware.starknet.cli.starknet_cli import NETWORKS

import logging

from nile.common import (
    get_class_hash,
    ABIS_DIRECTORY,
    is_alias,
    DECLARATIONS_FILENAME,
    parse_information,
)
from nile.deployments import class_hash_exists
from nile.utils import hex_class_hash
from nile.starknet_cli.deploy_account import (
    deploy_account_no_wallet,
    update_deploy_account_context,
)


async def send_multi(self, to, method, calldata, nonce=None):
    """Execute a tx going through an Account contract. Inspired from openzeppelin."""
    config = Config(nile_network=self.network)
    target_address, _ = next(deployments.load(to, self.network)) or to

    calldata = [[int(x) for x in c] for c in calldata]

    if not calldata:
        calls = [[target_address, method, calldata]]
    else:
        calls = [[target_address, method, c] for c in calldata]

    if self.network == "devnet":
        if nonce is None:
            if not str(self.address).startswith("0x"):
                contract_address = hex(int(self.address))
            output_nonce = await execute_call(
                "get_nonce", self.network, contract_address=contract_address
            )
            nonce = int(output_nonce)

    else:
        if nonce is None:
            nonce = await get_nonce(self.address, self.network)

    print(calls)

    (execute_calldata, sig_r, sig_s) = self.signer.sign_invoke(
        sender=self.address,
        calls=calls,
        nonce=nonce,
        max_fee=config.MAX_FEE,
    )

    if self.network == "devnet":
        return await wrapped_call_or_invoke(
            contract=self.address,
            type="invoke",
            method="__execute__",
            params=execute_calldata,
            network=self.network,
            signature=[str(sig_r), str(sig_s)],
            max_fee=str(config.MAX_FEE),
        )

    return await call_or_invoke(
        contract=self.address,
        type="invoke",
        method="__execute__",
        params=execute_calldata,
        network=self.network,
        signature=[str(sig_r), str(sig_s)],
        max_fee=str(config.MAX_FEE),
    )


# bind it to the account class so that we can use the function when signing
Account.send_multi = send_multi


def call(network, contract_alias, function, arguments) -> str:
    """Nile call function."""

    command = [
        "nile",
        "call",
        "--network",
        network,
        contract_alias,
        function,
        *map(str, arguments),
    ]
    return subprocess.check_output(command).strip().decode("utf-8")


async def proxy_call(network, contract_alias, abi, function, params) -> str:
    """Nile proxy call function."""

    address, _ = next(deployments.load(contract_alias, network)) or contract_alias

    address = hex_address(address)

    if network == "devnet":
        return await wrapped_call_or_invoke(
            contract=address,
            type="call",
            method=function,
            params=params,
            network=network,
            abi=abi,
        )

    else:
        return await call_or_invoke(
            contract=address,
            type="call",
            method=function,
            params=params,
            network=network,
            abi=abi,
        )


async def _call_async(network, contract_alias, function, arguments) -> str:
    """Nile async call function."""

    command = " ".join(
        [
            "nile",
            "call",
            "--network",
            network,
            contract_alias,
            function,
            *map(str, arguments),
        ]
    )
    proc = await asyncio.create_subprocess_shell(
        command, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )

    stdout, stderr = await proc.communicate()

    if stderr:
        print(f"[stderr]\n{stderr.decode()}")
    return stdout.decode()


async def _call_sync_manager(network, contract_alias, function, calldata) -> str:
    """ "Helper function to create multiple coroutines."""
    stdout = await asyncio.gather(
        *[
            _call_async(network, contract_alias, function, arguments)
            for arguments in calldata
        ]
    )

    return stdout


def call_multi(network, contract_alias, function, calldata) -> str:
    """Launches the async call manager to launch a pool of calls."""
    return asyncio.run(_call_sync_manager(network, contract_alias, function, calldata))


def wrapped_call(network, contract_alias, function, arguments) -> str:
    """Send command with some extra functionality such as tx status check and built-in timeout.
    (only supported for non-localhost networks)
    tx statuses:
    RECEIVED -> PENDING -> ACCEPTED_ON_L2
    """
    print("------- CALL ----------------------------------------------------")
    print(f"calling {function} from {contract_alias} with {arguments}")
    out = call(network, contract_alias, function, arguments)
    print("_________________________________________________________________")
    # return out such that it can be prettified at a higher level
    return out


async def wrapped_proxy_call(network, contract_alias, abi, function, arguments) -> str:
    """Send command with some extra functionality such as tx status check and built-in timeout.
    (only supported for non-localhost networks)
    tx statuses:
    RECEIVED -> PENDING -> ACCEPTED_ON_L2
    """
    print("------- CALL ----------------------------------------------------")
    print(f"calling {function} from {contract_alias} with {arguments}")
    out = await proxy_call(network, contract_alias, abi, function, arguments)
    print("_________________________________________________________________")
    # return out such that it can be prettified at a higher level
    return out


async def send(network, signer_alias, contract_alias, function, arguments) -> str:
    """Nile send function."""
    account = await Account(signer_alias, network)
    if not arguments:
        return await account.send_multi(contract_alias, function, [])
    elif isinstance(arguments[0], list):
        return await account.send_multi(contract_alias, function, arguments)
    else:
        return await account.send_multi(contract_alias, function, [arguments])


async def wrapped_send(network, signer_alias, contract_alias, function, arguments):
    """Send command with some extra functionality such as tx status check and built-in timeout.
    (only supported for non-localhost networks)

    tx statuses:
    RECEIVED -> PENDING -> ACCEPTED_ON_L2
    """
    print("------- SEND ----------------------------------------------------")
    print(f"invoking {function} from {contract_alias} with {arguments}")
    out = await send(network, signer_alias, contract_alias, function, arguments)
    if network != "devnet":
        if out:
            _, tx_hash = parse_send(out)
            get_tx_status(
                network,
                tx_hash,
            )
        else:
            raise Exception("send message returned None")
    else:
        _, tx_hash = parse_send(out)
        tx_status = await status(tx_hash, network)
    print("------- SEND ----------------------------------------------------")
    return out


def get_tx_status(network, tx_hash: str) -> dict:
    """Returns transaction receipt in dict."""
    command = [
        "nile",
        "debug",
        "--network",
        network,
        tx_hash,
    ]
    out_raw = subprocess.check_output(command).strip().decode("utf-8")
    return out_raw


def parse_send(x):
    """Extract information from send command."""
    # address is 64, tx_hash is 64 chars long
    try:
        address, tx_hash = re.findall("0x[\\da-f]{1,64}", str(x))
        return address, tx_hash
    except ValueError:
        print(f"could not get tx_hash from message {x}")
    return 0x0, 0x0


def deploy(network, alias) -> str:
    """Nile deploy function."""
    command = [
        "nile",
        "deploy",
        alias,
        "--network",
        network,
        "--alias",
        alias,
    ]
    return subprocess.check_output(command).strip().decode("utf-8")


def compile(contract_alias) -> str:
    """Nile call function."""
    if os.path.dirname(__file__).split("/")[1] == "Users":
        path = "/" + os.path.join(
            os.path.dirname(__file__).split("/")[1],
            os.path.dirname(__file__).split("/")[2],
            "Documents",
            "realms",
            "realms-contracts",
        )
    else:
        path = "/workspaces/realms-contracts"

    location = find_file(path, contract_alias + ".cairo")

    command = [
        "nile",
        "compile",
        location,
    ]
    return subprocess.check_output(command).strip().decode("utf-8")


def find_file(root_dir, file_name):
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for f in filenames:
            if f == file_name:
                return os.path.relpath(os.path.join(dirpath, f), root_dir)
    return None


async def wrapped_declare(account, contract_name, network, alias):
    config = Config(nile_network=network)
    if os.path.dirname(__file__).split("/")[1] == "Users":
        path = "/" + os.path.join(
            os.path.dirname(__file__).split("/")[1],
            os.path.dirname(__file__).split("/")[2],
            "Documents",
            "realms",
            "realms-contracts",
        )
    else:
        path = "/workspaces/realms-contracts"

    location = find_file(path, contract_name + ".cairo")

    account = await Account(account, network)

    compile_starknet_files(
        files=[f"{location}"],
        debug_info=True,
        cairo_path=[path + "/lib/cairo_contracts/src"],
    )

    compile(contract_name)

    # If devnet we need to write the call and check declerations manually
    if network == "devnet":
        print(f"🚀 Declaring {contract_name}")

        if alias_exists(alias, network):
            file = f"{network}.{DECLARATIONS_FILENAME}"
            raise Exception(f"Alias {alias} already exists in {file}")
        max_fee, nonce, _ = await _process_arguments(account, config.MAX_FEE, None)
        # Create the transaction
        transaction = DeclareTransaction(
            account_address=account.address,
            contract_to_submit=contract_name,
            max_fee=max_fee or 0,
            nonce=nonce,
            network=network,
            overriding_path=False,
        )

        sig_r, sig_s = account.signer.sign(message_hash=transaction._get_tx_hash())

        type_specific_args = transaction._get_execute_call_args()

        output = await execute_call(
            "declare",
            network,
            signature=[sig_r, sig_s],
            max_fee=config.MAX_FEE,
            query_flag=None,
            **type_specific_args,
        )
        class_hash, tx_hash = parse_information(output)
        padded_hash = hex_class_hash(class_hash)

        print(f"⏳ Successfully sent declaration of {contract_name} as {padded_hash}")
        print(f"🧾 Transaction hash: {hex(tx_hash)}")

        deployments.register_class_hash(class_hash, network, alias)
    else:
        tx_wrapper = await account.declare(contract_name, max_fee=4226601250467000)
        tx_status, declared_hash = await tx_wrapper.execute(watch_mode="track")

    if network != "devnet":
        get_tx_status(
            network,
            str(tx_wrapper.hash),
        )
    else:
        time.sleep(5)


# async def wrapped_declare(account, contract_name, network, alias):
#     if os.path.dirname(__file__).split("/")[1] == "Users":
#         path = "/" + os.path.join(
#             os.path.dirname(__file__).split("/")[1],
#             os.path.dirname(__file__).split("/")[2],
#             "Documents",
#             "realms",
#             "realms-contracts",
#         )
#     else:
#         path = "/workspaces/realms-contracts"

#     location = find_file(path, contract_name + ".cairo")

#     account = await Account(account, network)

#     compile_starknet_files(
#         files=[f"{location}"],
#         debug_info=True,
#         cairo_path=[path + "/lib/cairo_contracts/src"],
#     )

#     compile(contract_name)

#     tx_wrapper = await account.declare(contract_name, max_fee=4226601250467000)
#     tx_status, declared_hash = await tx_wrapper.execute(watch_mode="track")

#     get_tx_status(
#         network,
#         str(tx_wrapper.hash),
#     )

#     return tx_wrapper


async def declare_class(network, contract_name, account, max_fee, overriding_path=None):
    """
    Declare a contract class and waits until the transaction completes.

    Returns the declared class hash in decimal format.
    """
    logging.debug(f"Declaring contract class {contract_name}...")
    class_hash = get_class_hash(
        contract_name=contract_name, overriding_path=overriding_path
    )
    padded_hash = hex_class_hash(class_hash)
    if class_hash_exists(class_hash, network):
        logging.debug(f"Contract class with hash {padded_hash} already exists")
    else:
        tx = await account.declare(
            contract_name, max_fee=max_fee, overriding_path=overriding_path
        )
        tx_status, declared_hash = await tx.execute(watch_mode="track")

        if tx_status.status.is_rejected:
            raise Exception(
                f"Could not declare contract class. Transaction rejected.",
                tx_status.error_message,
            )

        if padded_hash != declared_hash:
            raise Exception(
                f"Declared hash {declared_hash} does not match expected hash {padded_hash}"
            )

        logging.debug(f"Contract class declared with hash {padded_hash}")

    return class_hash


def get_contract_abi(contract_name):
    return f"{ABIS_DIRECTORY}/{contract_name}.json"


async def get_transaction_result(network, tx_hash):
    if network == "devnet":
        output = await execute_call("get_transaction_trace", network, hash=tx_hash)
        out_dict = json.loads(output)
        return out_dict["function_invocation"]["result"]
    else:
        command = [
            "starknet",
            "get_transaction_trace",
            "--hash",
            tx_hash,
            "--network",
            "alpha-goerli",
        ]
        out = subprocess.check_output(command).strip().decode("utf-8")
        out_dict = json.loads(out)
        return out_dict["function_invocation"]["result"]


async def wrapped_call_or_invoke(
    contract,
    type,
    method,
    params,
    network,
    abi=None,
    signature=None,
    max_fee=None,
    query_flag=None,
    watch_mode=None,
):
    """
    Call or invoke functions of StarkNet smart contracts.
    @param contract: can be an address or an alias.
    @param type: can be either call or invoke.
    @param method: the targeted function.
    @param params: the targeted function arguments.
    @param network: goerli, goerli2, integration, mainnet, or predefined networks file.
    @param signature: optional signature for invoke transactions.
    @param max_fee: optional max fee for invoke transactions.
    @param query_flag: either simulate or estimate_fee.
    @param watch_mode: either track or debug.
    """
    if abi is None or is_alias(contract):
        address, abi = next(deployments.load(contract, network))
    else:
        address = contract

    try:
        output = await execute_call(
            type,
            network,
            inputs=params,
            signature=signature,
            max_fee=max_fee,
            query_flag=query_flag,
            address=hex_address(address),
            abi=abi,
            method=method,
        )
    except BaseException as err:
        if "max_fee must be bigger than 0." in str(err):
            logging.error(
                """
                \n😰 Whoops, looks like max fee is missing. Try with:\n
                --max_fee=`MAX_FEE`
                """
            )
            return
        else:
            logging.error(err)
            return

    if type != "call" and output:
        logging.info(output)
        if not query_flag and watch_mode:
            transaction_hash = _get_transaction_hash(output)
            return await status(normalize_number(transaction_hash), network, watch_mode)

    return output


async def execute_call(cmd_name, network, **kwargs):
    """Build and execute call to starknet_cli."""
    args = set_context(network)
    command_args = set_command_args(**kwargs)
    cmd = getattr(starknet_cli, cmd_name)

    if cmd_name == "deploy_account":
        args = update_deploy_account_context(args, **kwargs)
        cmd = deploy_account_no_wallet

    return await capture_stdout(cmd(args=args, command_args=command_args))


def set_context(network):
    """Set context args for StarkNet CLI call."""
    args = {
        "gateway_url": get_gateway_url(network),
        "feeder_gateway_url": get_feeder_url(network),
        "wallet": "",
        "network_id": network,
        "account_dir": None,
        "account": None,
    }
    ret_obj = SimpleNamespace(**args)
    return ret_obj


def get_gateway_url(network):
    """Return gateway URL for specified network."""
    config = Config(nile_network=network)
    if network in config.NETWORKS:
        return config.GATEWAYS.get(network)
    else:
        network = "alpha-" + network
        return f"https://{NETWORKS[network]}/gateway"


def get_feeder_url(network):
    """Return feeder gateway URL for specified network."""
    config = Config(nile_network=network)
    if network in config.NETWORKS:
        return config.GATEWAYS.get(network)
    else:
        network = "alpha-" + network
        return f"https://{NETWORKS[network]}/feeder_gateway"


def _get_transaction_hash(string):
    match = re.search(r"Transaction hash: (0x[\da-f]{1,64})", string)
    return match.groups()[0] if match else None


async def capture_stdout(func):
    """Return the stdout during the passed function call."""
    stdout = sys.stdout
    sys.stdout = io.StringIO()
    await func
    output = sys.stdout.getvalue()
    sys.stdout = stdout
    result = output.rstrip()
    return result


async def _process_arguments(account, max_fee, nonce, calldata=None):
    if max_fee is not None:
        max_fee = int(max_fee)

    if nonce is None:
        if not str(account.address).startswith("0x"):
            contract_address = hex(int(account.address))
        output_nonce = await execute_call(
            "get_nonce", account.network, contract_address=contract_address
        )
        nonce = int(output_nonce)

    if calldata is not None:
        calldata = [normalize_number(x) for x in calldata]

    return max_fee, nonce, calldata


_TransactionReceipt = namedtuple("TransactionReceipt", ["tx_hash", "status", "receipt"])


async def status(
    tx_hash, network, watch_mode=None, contracts_file=None
) -> TransactionStatus:
    """Fetch a transaction status.
    Optionally track until resolved (accepted on L2 or rejected) and/or
    use available artifacts to help locate the error. Debug implies track.
    """
    print(f"⏳ Transaction hash: {hex_class_hash(tx_hash)}")
    print("⏳ Querying the network for transaction status...")

    while True:
        tx_status = await execute_call(
            "tx_status", network, hash=hex_class_hash(tx_hash)
        )
        raw_receipt = json.loads(tx_status)
        receipt = _get_tx_receipt(tx_hash, raw_receipt, watch_mode)

        if receipt is not None:
            break

    if not receipt.status.is_rejected:
        return TransactionStatus(tx_hash, receipt.status, None)

    error_message = receipt.receipt["tx_failure_reason"]["error_message"]

    print(f"🧾 Error message:\n{error_message}")

    return TransactionStatus(tx_hash, receipt.status, error_message)


def _get_tx_receipt(tx_hash, raw_receipt, watch_mode) -> _TransactionReceipt:
    receipt = _TransactionReceipt(
        tx_hash, TxStatus.from_receipt(raw_receipt), raw_receipt
    )

    if receipt.status.is_rejected:
        print(f"❌ Transaction status: {receipt.status}")
        return receipt

    log_output = f"Transaction status: {receipt.status}"

    if receipt.status.is_accepted:
        print(f"✅ {log_output}. No error in transaction.")
        return receipt

    if watch_mode is None:
        print(f"🕒 {log_output}.")
        return receipt

    print(f"🕒 {log_output}. Trying again in {20} seconds...")
    time.sleep(20)
