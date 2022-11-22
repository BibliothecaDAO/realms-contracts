"""
This files holds wrapper functions for calls and invokes.
As you can see, we just invoke other nile CLI commands and we can
probably also just call nile python functions.
"""
import re
import subprocess
import asyncio

from nile.core.declare import declare
from nile.core.account import Account, get_nonce
from nile import deployments
from nile.core.call_or_invoke import call_or_invoke
from realms_cli.config import Config
from starkware.starknet.compiler.compile import compile_starknet_files


def send_multi(self, to, method, calldata, nonce=None):
    """Execute a tx going through an Account contract. Inspired from openzeppelin."""
    config = Config(nile_network=self.network)
    target_address, _ = next(deployments.load(to, self.network)) or to

    calldata = [[int(x) for x in c] for c in calldata]

    if nonce is None:
        nonce = get_nonce(self.address, self.network)

    (execute_calldata, sig_r, sig_s) = self.signer.sign_transaction(
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

    return call_or_invoke(
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


async def _call_async(network, contract_alias, function, arguments) -> str:
    """Nile async call function."""

    command = " ".join([
        "nile",
        "call",
        "--network",
        network,
        contract_alias,
        function,
        *map(str, arguments),
    ])
    proc = await asyncio.create_subprocess_shell(
        command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE)

    stdout, stderr = await proc.communicate()

    if stderr:
        print(f'[stderr]\n{stderr.decode()}')
    return stdout.decode()


async def _call_sync_manager(network, contract_alias, function, calldata) -> str:
    """"Helper function to create multiple coroutines."""
    stdout = await asyncio.gather(*[
        _call_async(network, contract_alias, function, arguments)
        for arguments in calldata
    ])

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
    print("------- CALL ----------------------------------------------------")
    # return out such that it can be prettified at a higher level
    return out


def send(network, signer_alias, contract_alias, function, arguments) -> str:
    """Nile send function."""
    account = Account(signer_alias, network)
    if isinstance(arguments[0], list):
        return account.send_multi(contract_alias, function, arguments)
    return account.send_multi(contract_alias, function, [arguments])


def wrapped_send(network, signer_alias, contract_alias, function, arguments):
    """Send command with some extra functionality such as tx status check and built-in timeout.
    (only supported for non-localhost networks)

    tx statuses:
    RECEIVED -> PENDING -> ACCEPTED_ON_L2
    """
    print("------- SEND ----------------------------------------------------")
    print(f"invoking {function} from {contract_alias} with {arguments}")
    out = send(network, signer_alias, contract_alias, function, arguments)
    if out:
        _, tx_hash = parse_send(out)
        get_tx_status(network, tx_hash,)
    else:
        raise Exception("send message returned None")
    print("------- SEND ----------------------------------------------------")


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
    command = [
        "nile",
        "compile",
        contract_alias,
    ]
    return subprocess.check_output(command).strip().decode("utf-8")


# def declare(contract_name, alias) -> str:
#     """Nile declare function."""
#     command = [
#         "nile",
#         "declare",
#         account,
#         contract_name,
#         "--alias",
#         alias,
#     ]
#     return subprocess.check_output(command).strip().decode("utf-8")


def wrapped_declare(account, contract_name, network, alias):

    account = Account(account, network)

    config = Config(nile_network=network)

    contract_class = compile_starknet_files(
        files=[f"{'contracts'}/{contract_name}.cairo"], debug_info=True, cairo_path=["/workspaces/realms-contracts/lib/cairo_contracts/src"]
    )
    nonce = get_nonce(account.address, network)
    sig_r, sig_s = account.signer.sign_declare(
        sender=account.address,
        contract_class=contract_class,
        nonce=nonce,
        max_fee=80999285161067,
    )

    class_hash = declare(sender=account.address, contract_name=alias, signature=[
                         sig_r, sig_s], alias=alias, network=network, max_fee=80999285161067000)
    return class_hash


Account.wrapped_declare = wrapped_declare