import struct

def str_to_felt(text: str) -> int:
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")


def felt_to_str(felt: int) -> str:
    b_felt = felt.to_bytes(31, "big")
    return b_felt.decode()


def pack_values(values: list) -> int:
    return int.from_bytes(struct.pack(f"<{len(values)}b", *values), "little")

def uint(a):
    return(a, 0)