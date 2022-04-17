import re
import time
import logging
import subprocess
import json
from realms_cli.config import Config as config

def send(signer_alias, contract_alias, function, args):
    """Nile send function."""
    command = [
        "nile",
        "send",
        "--network",
        config.STARKNET_NETWORK,
        signer_alias,
        contract_alias,
        function,
        *map(str, args),
    ]
    return subprocess.check_output(command).strip().decode("utf-8")

def wait(t: int):
    """Wait for t seconds"""
    for _ in range(t):
        time.sleep(1)
        print(".", end="")
    print()

def wrapped_send(signer_alias, contract_alias, function, args):
    """Send command with some extra functionality such as tx status check and built-in timeout.

    tx statuses:
    RECEIVED -> PENDING -> ACCEPTED_ON_L2
    """
    print("------- SEND ----------------------------------------------------")
    out = send(signer_alias, contract_alias, function, args)
    print(out)
    _, tx_hash = parse_send(out)
    time.sleep(2)
    tx_status = get_tx_status(tx_hash)
    print(f"tx status: {tx_status}")
    while tx_status == "RECEIVED":
        print("waiting 10s until transaction is beyond received")
        wait(10)
        tx_status = get_tx_status(tx_hash)
        print(f"tx status: {tx_status}")
    if tx_status == "REJECTED":
        raise Exception
    print("------- SEND ----------------------------------------------------")

def get_tx_receipt(tx_hash : str) -> dict:
    """Returns transaction receipt in dict."""
    command = [
        "starknet",
        "get_transaction_receipt",
        "--hash",
        tx_hash,
    ]
    out_raw = subprocess.check_output(command).strip().decode("utf-8")
    return json.loads(out_raw) 

def get_tx_status(tx_hash : str):
    """Returns transaction status based on transaction hash."""
    return get_tx_receipt(tx_hash)["status"]

def parse_send(x):
    """Extract information from send command."""
    # address is 64, tx_hash is 64 chars long
    address, tx_hash = re.findall("0x[\\da-f]{1,64}", str(x))
    return address, tx_hash
