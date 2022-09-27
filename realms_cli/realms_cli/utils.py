import struct
from typing import List

from nile import deployments


def print_over_colums(array_of_strings, cols=2, width=40):
    """Takes in an array of strings and prints the content over a
     number of colums."""
    ans = ""
    for i, text in enumerate(array_of_strings):
        if i % cols == 0:
            ans += "\n"
        ans += f"| {text.ljust(width)} "
    print(ans)


def uint(a):
    return(a, 0)


def parse_multi_input(cli_input) -> List:
    """Parse input and check for multiple args

    1-4   -> [1,2,3,4]
    1,2,5 -> [1,2,5]
    1     -> [1]

    Returns
        List of args
    """
    if "-" in cli_input:
        low, high = cli_input.split("-")
        return list(range(int(low), int(high)+1))
    if "," in cli_input:
        words = cli_input.split(",")
        return [int(word) for word in words]
    return [cli_input]


def str_to_felt(text: str) -> int:
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")


def felt_to_str(felt: int) -> str:
    b_felt = felt.to_bytes(31, "big")
    return b_felt.decode()


def pack_values(values: list) -> int:
    return int.from_bytes(struct.pack(f"<{len(values)}b", *values), "little")


def uint_decimal(a):
    x = int(a) * 10 ** 18
    return(x, 0)


def expanded_uint_list(arr):
    """
    Convert array of ints into flattened array of uints.
    """
    return list(sum([uint(a) for a in arr], ()))


def expanded_uint_list_decimals(arr):
    """
    Convert array of ints into flattened array of uints.
    """
    return list(sum([uint_decimal(a) for a in arr], ()))


def from_bn(a):
    """
    Convert 18 decimals into 4 decimals
    """
    return round(int(a, 16) / 1000000000000000000, 4)

def safe_load_deployment(alias: str, network: str):
    """Safely loads address from deployments file"""
    try:
        address, _ = next(deployments.load(alias, network))
        print(f"Found deployment for alias {alias}.")
        return address, _
    except StopIteration:
        print(f"Deployment for alias {alias} not found.")
        return None, None


def safe_load_declarations(alias: str, network: str):
    """Safely loads address from deployments file"""
    address, _ = next(deployments.load_class(alias, network), None)
    print(f"Found deployment for alias {alias}.")
    return address


def strhex_as_strfelt(strhex: str):
    """Converts a string in hex format to a string in felt format"""
    if strhex is not None:
        return str(int(strhex, 16))
    else:
        print("strhex address is None.")
