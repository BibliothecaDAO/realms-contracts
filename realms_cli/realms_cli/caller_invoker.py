import re
import time
import subprocess

def call(network, contract_alias, function, arguments):
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

def wrapped_call(network, contract_alias, function, arguments):
    """Send command with some extra functionality such as tx status check and built-in timeout.
    (only supported for non-localhost networks)

    tx statuses:
    RECEIVED -> PENDING -> ACCEPTED_ON_L2
    """
    print("------- CALL ----------------------------------------------------")
    print(f"calling {function} from {contract_alias} with {arguments}")
    out = call(network, contract_alias, function, arguments)
    print("------- CALL ----------------------------------------------------")
    # return out such that it can me prettified at a higher level
    return out

def send(network, signer_alias, contract_alias, function, arguments):
    """Nile send function."""
    command = [
        "nile",
        "send",
        "--network",
        network,
        signer_alias,
        contract_alias,
        function,
        *map(str, arguments),
    ]
    return subprocess.check_output(command).strip().decode("utf-8")

def wrapped_send(network, signer_alias, contract_alias, function, arguments):
    """Send command with some extra functionality such as tx status check and built-in timeout.
    (only supported for non-localhost networks)

    tx statuses:
    RECEIVED -> PENDING -> ACCEPTED_ON_L2
    """
    print("------- SEND ----------------------------------------------------")
    out = send(network, signer_alias, contract_alias, function, arguments)
    print(out)
    _, tx_hash = parse_send(out)
    get_tx_status(network, tx_hash,)
    print("------- SEND ----------------------------------------------------")

def get_tx_status(network, tx_hash : str) -> dict:
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
    
def deploy(network, contract_alias):
    """Nile deploy function."""
    command = [
        "nile",
        "deploy",
        "--network",
        network,
        contract_alias,
    ]
    return subprocess.check_output(command).strip().decode("utf-8")