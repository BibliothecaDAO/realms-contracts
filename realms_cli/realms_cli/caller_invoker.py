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

from nile.core.declare import declare
from nile.core.types.account import Account, get_nonce
from nile.starknet_cli import execute_call
from nile import deployments
from nile.core.call_or_invoke import call_or_invoke
from nile.utils import hex_address, felt_to_str
from realms_cli.config import Config
from starkware.starknet.compiler.compile import compile_starknet_files

import logging

from nile.common import get_class_hash, ABIS_DIRECTORY
from nile.deployments import class_hash_exists
from nile.utils import hex_class_hash


async def send_multi(self, to, method, calldata, nonce=None):
    """Execute a tx going through an Account contract. Inspired from openzeppelin."""
    config = Config(nile_network=self.network)
    target_address, _ = next(deployments.load(to, self.network)) or to

    calldata = [[int(x) for x in c] for c in calldata]

    if nonce is None:
        nonce = await get_nonce(self.address, self.network)

    (execute_calldata, sig_r, sig_s) = self.signer.sign_invoke(
        sender=self.address,
        calls=[[target_address, method, c] for c in calldata],
        nonce=nonce,
        max_fee=config.MAX_FEE,
    )

    # params = []
    # # params.append(str(len(call_array)))
    # # params.extend([str(elem) for sublist in call_array for elem in sublist])
    # params.append(str(len(calldata)))
    # params.extend([str(param) for param in calldata])
    # params.append(str(nonce))

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
    if out:
        _, tx_hash = parse_send(out)
        get_tx_status(
            network,
            tx_hash,
        )
    else:
        raise Exception("send message returned None")
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

    tx_wrapper = await account.declare(contract_name, max_fee=4226601250467000)
    tx_status, declared_hash = await tx_wrapper.execute(watch_mode="track")

    get_tx_status(
        network,
        str(tx_wrapper.hash),
    )

    return tx_wrapper


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


def get_transaction_result(network, tx_hash):
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
